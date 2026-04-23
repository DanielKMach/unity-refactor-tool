const std = @import("std");
const core = @import("core");
const tracy = @import("tracy");

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
    if (proj.pkgcache) |*d| d.close();
    proj.* = undefined;
}

pub const FindFn = fn (*const anyopaque, std.fs.Dir.Walker.Entry, std.mem.Allocator) SearchError!bool;
pub const FiltFn = fn (*anyopaque, std.fs.Dir.Walker.Entry, std.mem.Allocator) SearchError!bool;
pub const FragFn = fn (*anyopaque, std.fs.Dir, []const u8, std.mem.Allocator) SearchError!void;

// idk why walker.next uses implicit error set on return type.
const WalkerError = @typeInfo(@typeInfo(@TypeOf(std.fs.Dir.Walker.next)).@"fn".return_type.?).error_union.error_set;
pub const SearchError = std.mem.Allocator.Error || error{SearchFailed};

pub const FindError = SearchError || WalkerError || std.fs.Dir.RealPathError || std.mem.Allocator.Error;
pub const ScanError = SearchError || WalkerError || std.fs.Dir.OpenError || std.Thread.SpawnError || std.mem.Allocator.Error;

pub fn find(
    proj: Project,
    data: *const anyopaque,
    func: *const FindFn,
    allocator: std.mem.Allocator,
) FindError!?[]u8 {
    const zone = tracy.Zone(@src());
    defer zone.End();

    const dirs = [3]?std.fs.Dir{ proj.assets, proj.packages, proj.pkgcache };
    for (dirs) |d| {
        const dir = d orelse continue;

        var walker = try dir.walk(allocator);
        defer walker.deinit();

        while (try walker.next()) |e| {
            if (try @call(.auto, func, .{ data, e, allocator })) {
                return try e.dir.realpathAlloc(allocator, e.basename);
            }
        }
    }
    return null;
}

/// Requires thread-safe allocator.
pub fn scan(
    proj: Project,
    data: *anyopaque,
    filt: *const FiltFn,
    frag: *const FragFn,
    path: ?[]const u8,
    pool: *std.Thread.Pool,
    allocator: std.mem.Allocator,
) ScanError!void {
    const zone = tracy.Zone(@src());
    defer zone.End();

    var dir = if (path) |sub| try proj.assets.openDir(sub, opts) else proj.assets;
    defer if (path != null) dir.close() else {};

    var walker = try dir.walk(allocator);
    defer walker.deinit();
    var walker_mtx: std.Thread.Mutex = .{};
    var err: ?ScanError = null;

    const count = @min(core.config.scan_thread_count, pool.threads.len);
    var group = std.Thread.WaitGroup{};

    for (0..count) |_| {
        pool.spawnWg(&group, loop, .{
            data,
            filt,
            frag,
            dir,
            &walker,
            &walker_mtx,
            &err,
            allocator,
        });
    }

    group.wait();
    return err orelse {};
}

fn loop(
    data: *anyopaque,
    filt: *const FiltFn,
    frag: *const FragFn,
    dir: std.fs.Dir,
    walker: *std.fs.Dir.Walker,
    w_mtx: *std.Thread.Mutex,
    err: *?ScanError,
    allocator: std.mem.Allocator,
) void {
    const zone = tracy.Zone(@src());
    defer zone.End();

    var buf: [std.fs.max_path_bytes]u8 = undefined;
    return blk: {
        while (err.* == null) {
            const path = filt: {
                w_mtx.lock();
                defer w_mtx.unlock();

                const entry = (walker.next() catch |e| break :blk e) orelse break;
                if (@call(.auto, filt, .{ data, entry, allocator }) catch |e| break :blk e) {
                    @memcpy(buf[0..entry.path.len], entry.path);
                    break :filt buf[0..entry.path.len];
                } else continue;
            };

            @call(.auto, frag, .{ data, dir, path, allocator }) catch |e| break :blk e;
        }
    } catch |e| {
        err.* = e;
    };
}
