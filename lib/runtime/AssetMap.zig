//! A map of assets with their associated GUID.

const std = @import("std");
const tracy = @import("tracy");
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

pub fn put(self: *AssetMap, asset_path: []const u8) core.runtime.GUID.FromFileError!GUID {
    const guid = try GUID.fromAsset(asset_path, self.allocator);
    if (self.get(guid) != null) return guid;
    const abspath = try self.allocator.dupe(u8, asset_path);
    errdefer self.allocator.free(abspath);
    try self.assets.put(guid, abspath);
    return guid;
}

pub fn fetch(self: *AssetMap, guid: GUID) core.Project.FindError!?[]const u8 {
    const zone = tracy.Zone(@src());
    defer zone.End();

    const metafile = try self.proj.find(&guid, &find, self.allocator) orelse return null;
    errdefer self.allocator.free(metafile);
    try self.assets.put(guid, metafile[0 .. metafile.len - 5]);
    return metafile[0 .. metafile.len - 5];
}

pub fn entries(self: *const AssetMap) std.AutoHashMap(GUID, []const u8).Iterator {
    return self.assets.iterator();
}

fn find(data: *const anyopaque, e: std.fs.Dir.Walker.Entry, allocator: std.mem.Allocator) core.Project.SearchError!bool {
    if (e.kind != .file) return false;
    if (!std.mem.endsWith(u8, e.path, ".meta")) return false;

    const file = e.dir.openFile(e.basename, .{ .mode = .read_only }) catch |err| switch (err) {
        error.FileNotFound => return false,
        else => return error.SearchFailed,
    };
    defer file.close();

    var buf: [4096]u8 = undefined;
    var reader = file.reader(&buf);

    var guid_buf: [32]u8 = undefined;
    const file_guid = GUID.scanMetafile(&reader.interface, &guid_buf, allocator) catch return false;

    const guid = @as(*const GUID, @ptrCast(@alignCast(data))).*;
    return guid.eql(file_guid);
}
