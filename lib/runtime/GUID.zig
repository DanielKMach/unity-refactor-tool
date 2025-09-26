const std = @import("std");
const core = @import("core");

const GUID = @This();

const ScanError = std.mem.Allocator.Error || core.yaml.LibyamlError || error{InvalidMetaFile};
const FromTextError = error{InvalidGUID};
const FromFileError = ScanError || std.fs.File.OpenError;

/// The value of the GUID consisting of 32 hexadecimal digits.
id: u128,

pub inline fn eql(self: GUID, guid: []const u8) bool {
    if (guid.len != 32) return false;
    return for (guid, 0..) |c, i| {
        const s: u7 = @intCast(31 - i);
        if (!switch (c) {
            '0'...'9' => c - '0' == self.id >> s * 4 & 0xF,
            'a'...'f' => c - 'a' + 10 == self.id >> s * 4 & 0xF,
            'A'...'F' => c - 'A' + 10 == self.id >> s * 4 & 0xF,
            else => false,
        }) break false;
    } else true;
}

pub fn fromText(guid: []const u8) FromTextError!GUID {
    if (!isGUID(guid)) return error.InvalidGUID;
    const id = std.fmt.parseInt(u128, guid, 16) catch return error.InvalidGUID;
    return GUID{ .id = id };
}

pub fn fromFile(path: []const u8, allocator: std.mem.Allocator) FromFileError!GUID {
    const is_meta = std.mem.endsWith(u8, path, ".meta");
    const metafile_path = if (is_meta) path else try std.mem.concat(allocator, u8, &.{ path, ".meta" });
    defer if (!is_meta) allocator.free(metafile_path);

    const file = try std.fs.openFileAbsolute(metafile_path, .{ .mode = .read_only });
    defer file.close();

    var buf: [4096]u8 = undefined;
    var reader = file.reader(&buf);

    const guid = try scanMetafileAlloc(&reader.interface, allocator);
    defer allocator.free(guid);

    return fromText(guid) catch unreachable;
}

/// Scans the metafile for the GUID and returns it.
/// Returns `error.InvalidMetaFile` if it can't be found.
///
/// Asserts that the buffer is at least 32 bytes long.
pub fn scanMetafile(reader: *std.Io.Reader, buf: []u8, alloc: std.mem.Allocator) ScanError![]u8 {
    std.debug.assert(buf.len >= 32);

    var yaml = core.runtime.Yaml.init(.{ .reader = reader }, null, alloc);

    const nullable_guid = try yaml.get(&.{"guid"}, buf);
    const guid = nullable_guid orelse return error.InvalidMetaFile;

    if (!isGUID(guid)) return error.InvalidMetaFile;

    return guid[0..32];
}

/// Scans the metafile for the GUID and returns it.
/// Returns `error.InvalidMetaFile` if it can't be found.
/// The return value is owned by the caller.
pub fn scanMetafileAlloc(reader: *std.Io.Reader, alloc: std.mem.Allocator) ScanError![]u8 {
    var buf: [32]u8 = undefined;
    const guid = try scanMetafile(reader, &buf, alloc);
    return try alloc.dupe(u8, guid);
}

/// Checks if the string is a valid GUID (32 hexadecimal digits).
pub fn isGUID(str: []const u8) bool {
    if (str.len != 32) return false;
    return for (str) |c| {
        if (!std.ascii.isHex(c)) break false;
    } else true;
}

test eql {
    const g1 = GUID{ .id = 0x1234567890abcdef1234567890abcdef };
    const g2 = GUID{ .id = 0x0 };
    const g3 = GUID{ .id = std.math.maxInt(u128) };
    try std.testing.expect(g1.eql("1234567890abcdef1234567890abcdef"));
    try std.testing.expect(g1.eql("1234567890ABCDEF1234567890ABCDEF"));
    try std.testing.expect(!g1.eql("1234567890abcdef1234567890abcdee"));
    try std.testing.expect(!g1.eql("2234567890abcdef1234567890abcdef"));
    try std.testing.expect(!g1.eql("1234567890ABCDEF1234567890AACDEF"));
    try std.testing.expect(g2.eql("00000000000000000000000000000000"));
    try std.testing.expect(!g2.eql("0000000000000000000000000000000f"));
    try std.testing.expect(g3.eql("ffffffffffffffffffffffffffffffff"));
    try std.testing.expect(!g3.eql("fffffffffffffffffffffffffffffff0"));
}
