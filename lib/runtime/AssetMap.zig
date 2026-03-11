//! A map of assets with their associated GUID.

const std = @import("std");
const core = @import("core");
const yaml = core.yaml;
const GUID = core.runtime.GUID;

const AssetMap = @This();

proj: core.Project,
allocator: std.mem.Allocator,
assets: std.AutoHashMap(GUID, []const u8),

pub fn init(allocator: std.mem.Allocator, proj: core.Project) AssetMap {
    return .{
        .allocator = allocator,
        .assets = .init(allocator),
        .proj = proj,
    };
}

pub fn deinit(self: *AssetMap) void {
    var it = self.assets.iterator();
    while (it.next()) |entry| {
        self.allocator.free(entry.value_ptr.*);
    }
    self.assets.deinit();
}

pub fn get(self: *const AssetMap, guid: GUID) ?[]const u8 {
    return self.assets.get(guid);
}

pub fn put(self: *AssetMap, asset_path: []const u8) !GUID {
    const guid = try GUID.fromFile(asset_path, self.allocator);
    if (self.get(guid) != null) return guid;
    const abspath = try self.allocator.dupe(u8, asset_path);
    errdefer self.allocator.free(abspath);
    try self.assets.put(guid, abspath);
    return guid;
}

pub fn fetch(self: *AssetMap, guid: GUID) !?[]const u8 {
    const abspath = try self.proj.find([]u8, &guid, &find, self.allocator) orelse return null;
    errdefer self.allocator.free(abspath);
    try self.assets.put(guid, abspath);
    return abspath;
}

pub fn entries(self: *const AssetMap) std.AutoHashMap(GUID, []const u8).Iterator {
    return self.assets.iterator();
}

fn find(data: *const anyopaque, e: std.fs.Dir.Walker.Entry, allocator: std.mem.Allocator) core.Project.SearchError!?[]u8 {
    if (e.kind != .file) return null;
    if (!std.mem.endsWith(u8, e.path, ".meta")) return null;

    const file = e.dir.openFile(e.path, .{ .mode = .read_only }) catch |err| switch (err) {
        error.FileNotFound => return null,
        else => return error.SearchFailed,
    };
    defer file.close();

    var buf: [4096]u8 = undefined;
    var reader = file.reader(&buf);

    var guid_buf: [32]u8 = undefined;
    const file_guid = GUID.scanMetafile(&reader.interface, &guid_buf, allocator) catch return null;

    const guid = @as(*const GUID, @ptrCast(@alignCast(data))).*;
    if (guid.eql(file_guid)) {
        return e.dir.realpathAlloc(allocator, e.path[0 .. e.path.len - 5]) catch return error.SearchFailed;
    } else return null;
}
