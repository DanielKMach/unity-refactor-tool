const std = @import("std");
const core = @import("root");

const This = @This();

const ScanError = error{
    InvalidMetaFile,
};

/// The value of the GUID consisting of 32 hexadecimal digits.
value: []const u8,

/// The absolute path to the asset file if provided.
source: ?[]const u8,

pub fn init(guid: []const u8, source: ?[]const u8, allocator: std.mem.Allocator) std.mem.Allocator.Error!This {
    return This{
        .value = try allocator.dupe(u8, guid),
        .source = if (source) |src| try allocator.dupe(u8, src) else null,
    };
}

pub fn fromFile(path: []const u8, allocator: std.mem.Allocator) !This {
    const is_meta = std.mem.endsWith(u8, path, ".meta");
    const metafile_path = if (is_meta) path else try std.mem.concat(allocator, u8, &.{ path, ".meta" });
    defer if (!is_meta) allocator.free(metafile_path);

    const file = try std.fs.openFileAbsolute(metafile_path, .{ .mode = .read_only });
    defer file.close();

    const guid = try scanMetafileAlloc(file.reader().any(), allocator);

    return This{
        .value = guid,
        .source = try allocator.dupe(u8, path),
    };
}

pub fn deinit(self: This, allocator: std.mem.Allocator) void {
    allocator.free(self.value);
    if (self.source) |src| {
        allocator.free(src);
    }
}

/// Scans the metafile for the GUID and returns it.
/// Returns `error.InvalidMetaFile` if it can't be found.
///
/// Asserts that the buffer is at least 32 bytes long.
pub fn scanMetafile(reader: std.io.AnyReader, buf: []u8, alloc: std.mem.Allocator) ![]u8 {
    std.debug.assert(buf.len >= 32);

    var bufrdr = std.io.bufferedReader(reader);
    var yaml = core.runtime.Yaml.init(.{ .reader = bufrdr.reader().any() }, null, alloc);

    const nullable_guid = try yaml.get(&.{"guid"}, buf);
    const guid = nullable_guid orelse return error.InvalidMetaFile;

    if (!isGUID(guid)) {
        return error.InvalidMetaFile;
    }

    return guid;
}

/// Scans the metafile for the GUID and returns it.
/// Returns `error.InvalidMetaFile` if it can't be found.
/// The return value is owned by the caller.
///
/// Asserts that the buffer is at least 32 bytes long.
pub fn scanMetafileAlloc(reader: std.io.AnyReader, alloc: std.mem.Allocator) ![]u8 {
    var buf: [32]u8 = undefined;
    const guid = try scanMetafile(reader, &buf, alloc);
    return try alloc.dupe(u8, guid);
}

/// Checks if the string is a valid GUID (32 hexadecimal digits).
pub fn isGUID(str: []const u8) bool {
    if (str.len != 32) return false;
    for (str) |c| {
        if (!std.ascii.isHex(c)) return false;
    }
    return true;
}
