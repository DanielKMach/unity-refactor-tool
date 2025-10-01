//! A map of assets with their associated GUID.

const std = @import("std");
const core = @import("core");
const yaml = core.yaml;
const GUID = core.runtime.GUID;

const AssetMap = @This();

allocator: std.mem.Allocator,
assets: std.AutoHashMap(GUID, []const u8),

pub fn init(allocator: std.mem.Allocator) AssetMap {
    return .{
        .allocator = allocator,
        .assets = .init(allocator),
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
    var dir = try std.fs.cwd().openDir(".", .{ .iterate = true, .access_sub_paths = true });
    defer dir.close();

    var walker = try dir.walk(self.allocator);
    defer walker.deinit();

    var buf: [4096]u8 = undefined;

    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.path, ".meta")) continue;

        const file = dir.openFile(entry.path, .{ .mode = .read_only }) catch continue;
        defer file.close();

        var reader = file.reader(&buf);

        var guid_buf: [32]u8 = undefined;
        const file_guid = GUID.scanMetafile(&reader.interface, &guid_buf, self.allocator) catch |err| switch (err) {
            error.InvalidMetaFile => continue,
            else => |e| return e,
        };

        if (guid.eql(file_guid)) {
            std.debug.assert(std.mem.endsWith(u8, entry.path, ".meta"));
            const abspath = try dir.realpathAlloc(self.allocator, entry.path[0 .. entry.path.len - 5]);
            errdefer self.allocator.free(abspath);
            try self.assets.put(guid, abspath);
            return abspath;
        }
    }

    return null;
}

pub fn entries(self: *const AssetMap) std.AutoHashMap(GUID, []const u8).Iterator {
    return self.assets.iterator();
}
