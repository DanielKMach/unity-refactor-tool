const std = @import("std");

const Project = @This();

const opts: std.fs.Dir.OpenOptions = .{
    .access_sub_paths = true,
    .iterate = true,
};

root: std.fs.Dir,
assets: std.fs.Dir,
packages: std.fs.Dir,
pkgcache: ?std.fs.Dir,

pub fn fromRoot(root: std.fs.Dir) !Project {
    var assets = root.openDir("Assets", opts) catch |err| switch (err) {
        error.FileNotFound, error.NotDir => return error.AssetsNotFound,
        else => |e| return e,
    };
    errdefer assets.close();
    var packages = root.openDir("Packages", opts) catch |err| switch (err) {
        error.FileNotFound, error.NotDir => return error.PackagesNotFound,
        else => |e| return e,
    };
    errdefer packages.close();
    const pkgcache = root.openDir("Library/PackageCache", opts) catch |err| switch (err) {
        error.FileNotFound, error.NotDir => null,
        else => |e| return e,
    };
    errdefer if (pkgcache) |d| d.close() else {};

    return .{
        .root = root,
        .assets = assets,
        .packages = packages,
        .pkgcache = pkgcache,
    };
}

pub fn deinit(proj: *Project) void {
    proj.assets.close();
    proj.packages.close();
    if (proj.pkgcache) |d| d.close();
    proj.* = undefined;
}

pub const FiltFn = fn (*anyopaque, std.fs.Dir.Walker.Entry, std.mem.Allocator) ?std.fs.File;
pub const FragFn = fn (*anyopaque, std.fs.File, [:0]const u8, std.mem.Allocator) SearchError!void;
pub fn FindFn(comptime T: type) type {
    return fn (*const anyopaque, std.fs.Dir.Walker.Entry, std.mem.Allocator) SearchError!?T;
}

// idk why walker.next uses implicit error set on return type.
const WalkerError = @typeInfo(@typeInfo(@TypeOf(std.fs.Dir.Walker.next)).@"fn".return_type.?).error_union.error_set;
pub const SearchError = std.mem.Allocator.Error || error{SearchFailed};

pub const ScanError: type = std.mem.Allocator.Error || SearchError || WalkerError;
pub const FindError: type = std.mem.Allocator.Error || SearchError || WalkerError;

pub fn find(
    proj: Project,
    comptime T: type,
    data: *const anyopaque,
    func: *const FindFn(T),
    allocator: std.mem.Allocator,
) FindError!?T {
    const dirs = [3]?std.fs.Dir{ proj.assets, proj.packages, proj.pkgcache };
    for (dirs) |d| {
        const dir = d orelse continue;

        var walker = try dir.walk(allocator);
        defer walker.deinit();

        while (try walker.next()) |e| {
            if (try @call(.auto, func, .{ data, e, allocator })) |t| return t;
        }
    }
    return null;
}

pub fn scan(
    proj: Project,
    data: *anyopaque,
    filt: *const FiltFn,
    frag: *const FragFn,
    path: ?[]const u8,
    allocator: std.mem.Allocator,
) ScanError!void {
    const threadsafe: std.heap.ThreadSafeAllocator = .{ .child_allocator = allocator };
    const alloc = threadsafe.allocator();

    const dir = if (path) |sub| try proj.assets.openDir(sub, opts) else proj.assets;
    defer if (path != null) dir.close() else {};

    var walker = try dir.walk(alloc);
    defer walker.deinit();
    var walker_mtx: std.Thread.Mutex = .{};
    var has_error: ?anyerror = null;
    var error_mtx: std.Thread.Mutex = .{};

    const threads = try alloc.alloc(std.Thread, 4);
    defer alloc.free(threads);

    for (threads) |*t| {
        t.* = try std.Thread.spawn(.{ .allocator = alloc }, loop, .{
            data,
            filt,
            frag,
            &walker,
            &walker_mtx,
            &has_error,
            &error_mtx,
            alloc,
        });
    }

    for (threads) |thread| {
        thread.join();
    }

    if (has_error != null) {
        return has_error.?;
    }
}

fn loop(
    data: *anyopaque,
    filt: *const FiltFn,
    frag: *const FragFn,
    walker: *std.fs.Dir.Walker,
    w_mtx: *std.Thread.Mutex,
    has_error: *?anyerror,
    e_mtx: *std.Thread.Mutex,
    allocator: std.mem.Allocator,
) (ScanError || WalkerError)!void {
    while (has_error.* == null) {
        var file: ?std.fs.File = null;
        defer if (file) |f| f.close();
        var path: ?[:0]const u8 = null;
        defer if (path) |p| allocator.free(p);

        {
            w_mtx.lock();
            defer w_mtx.unlock();

            const entry = try walker.next() orelse break;
            file = @call(.auto, filt, .{ data, entry, allocator });
            path = try allocator.dupeZ(u8, entry.path);
        }

        if (file != null and path != null) {
            @call(.auto, frag, .{ data, path.?, file.?, allocator }) catch |e| {
                e_mtx.lock();
                defer e_mtx.unlock();
                if (has_error.* == null) has_error.* = e;
                break;
            };
        }
    }
}
