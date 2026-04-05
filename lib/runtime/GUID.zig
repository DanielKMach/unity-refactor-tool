const std = @import("std");
const core = @import("core");

const GUID = @This();

const ScanError = std.mem.Allocator.Error || core.yaml.LibyamlError || error{InvalidMetaFile};
pub const FromError = error{InvalidGUID};
pub const FromFileError = FromError || ScanError || std.fs.File.OpenError;

/// A GUID where all bits are set to zero.
pub const zero: GUID = .{ .id = std.math.minInt(u128) };

/// A GUID where all bits are set to one.
pub const one: GUID = .{ .id = std.math.maxInt(u128) };

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

pub fn format(self: GUID, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    return writer.print("{x:0>32}", .{self.id});
}

/// Parses a GUID from a string.
/// The string must be a valid GUID.
pub fn from(guid: []const u8) FromError!GUID {
    if (!isGUID(guid)) return error.InvalidGUID;
    const id = std.fmt.parseUnsigned(u128, guid, 16) catch return error.InvalidGUID;
    return GUID{ .id = id };
}

/// Extracts the GUID from an asset given its path and returns it.
///
/// The asset must have a valid .meta file with the same name.
pub fn fromAsset(path: []const u8, allocator: std.mem.Allocator) FromFileError!GUID {
    const is_meta = std.mem.endsWith(u8, path, ".meta");
    const metafile_path = if (is_meta) path else try std.mem.concat(allocator, u8, &.{ path, ".meta" });
    defer if (!is_meta) allocator.free(metafile_path);

    const file = try std.fs.openFileAbsolute(metafile_path, .{ .mode = .read_only });
    defer file.close();

    var buf: [4096]u8 = undefined;
    var reader = file.reader(&buf);

    const guid = try scanMetafileAlloc(&reader.interface, allocator);
    defer allocator.free(guid);

    return try from(guid);
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

test from {
    const g0 = GUID.zero;
    const g1 = GUID{ .id = 0x123abc };
    const g2 = GUID{ .id = 0x1234567890abcdef1234567890abcdef };
    const g3 = GUID.one;

    try std.testing.expectEqual(g0, from("00000000000000000000000000000000"));
    try std.testing.expectEqual(g1, from("00000000000000000000000000123abc"));
    try std.testing.expectEqual(g1, from("00000000000000000000000000123ABC"));
    try std.testing.expectEqual(g2, from("1234567890abcdef1234567890abcdef"));
    try std.testing.expectEqual(g2, from("1234567890ABCDEF1234567890ABCDEF"));
    try std.testing.expectEqual(g2, from("1234567890ABCDEF1234567890abcdef"));
    try std.testing.expectEqual(g3, from("ffffffffffffffffffffffffffffffff"));
    try std.testing.expectEqual(g3, from("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"));
    try std.testing.expectEqual(g3, from("ffffffffffffffffFFFFFFFFFFFFFFFF"));

    try std.testing.expectError(error.InvalidGUID, from(""));
    try std.testing.expectError(error.InvalidGUID, from("0000000000000000000000000000000"));
    try std.testing.expectError(error.InvalidGUID, from("000000000000000000000000000000000"));
    try std.testing.expectError(error.InvalidGUID, from("gggggggggggggggggggggggggggggggg"));
    try std.testing.expectError(error.InvalidGUID, from("GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"));
}

test eql {
    const g0 = GUID.zero;
    const g1 = GUID{ .id = 0x123abc };
    const g2 = GUID{ .id = 0x1234567890abcdef1234567890abcdef };
    const g3 = GUID.one;

    try std.testing.expect(g0.eql("00000000000000000000000000000000"));
    try std.testing.expect(g1.eql("00000000000000000000000000123ABC"));
    try std.testing.expect(g1.eql("00000000000000000000000000123abc"));
    try std.testing.expect(g2.eql("1234567890abcdef1234567890abcdef"));
    try std.testing.expect(g2.eql("1234567890ABCDEF1234567890ABCDEF"));
    try std.testing.expect(g2.eql("1234567890ABCDEF1234567890abcdef"));
    try std.testing.expect(g3.eql("ffffffffffffffffffffffffffffffff"));
    try std.testing.expect(g3.eql("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"));
    try std.testing.expect(g3.eql("FFFFFFFFFFFFFFFFffffffffffffffff"));

    try std.testing.expect(!g0.eql(""));
    try std.testing.expect(!g0.eql("0000000000000000000000000000000"));
    try std.testing.expect(!g0.eql("000000000000000000000000000000000"));
    try std.testing.expect(!g0.eql("00000000000000000000000000000001"));
    try std.testing.expect(!g1.eql("00000000000000000000000000123abb"));
    try std.testing.expect(!g1.eql("00000000000000000000000000123ABB"));
    try std.testing.expect(!g1.eql("00000000000000000000000000123abd"));
    try std.testing.expect(!g1.eql("00000000000000000000000000123ABD"));
    try std.testing.expect(!g2.eql("1234567890abcdef1234567890abcdee"));
    try std.testing.expect(!g2.eql("1234567890ABCDEF1234567890ABCDEE"));
    try std.testing.expect(!g2.eql("1234567890abcdef1234567890abcdf0"));
    try std.testing.expect(!g2.eql("1234567890ABCDEF1234567890ABCDF0"));
    try std.testing.expect(!g2.eql("ffffffffffffffffffffffffffffffff"));
    try std.testing.expect(!g2.eql("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"));
    try std.testing.expect(!g2.eql("00000000000000000000000000000000"));
    try std.testing.expect(!g3.eql("fffffffffffffffffffffffffffffffe"));
    try std.testing.expect(!g3.eql("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE"));
}

test isGUID {
    try std.testing.expect(isGUID("00000000000000000000000000000000"));
    try std.testing.expect(isGUID("00000000000000000000000000000001"));
    try std.testing.expect(isGUID("1234567890abcdef1234567890abcdef"));
    try std.testing.expect(isGUID("1234567890ABCDEF1234567890ABCDEF"));
    try std.testing.expect(isGUID("1234567890ABCDEF1234567890abcdef"));
    try std.testing.expect(isGUID("ffffffffffffffffffffffffffffffff"));
    try std.testing.expect(isGUID("fffffffffffffffffffffffffffffffe"));
    try std.testing.expect(isGUID("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"));
    try std.testing.expect(isGUID("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE"));
    try std.testing.expect(isGUID("FFFFFFFFFFFFFFFFffffffffffffffff"));
    try std.testing.expect(isGUID("FFFFFFFFFFFFFFFFfffffffffffffffe"));

    try std.testing.expect(!isGUID(""));
    try std.testing.expect(!isGUID("0000000000000000000000000000000"));
    try std.testing.expect(!isGUID("000000000000000000000000000000000"));
    try std.testing.expect(!isGUID("gggggggggggggggggggggggggggggggg"));
    try std.testing.expect(!isGUID("GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG"));
}

test format {
    const g0 = GUID.zero;
    const g1 = GUID{ .id = 0x123abc };
    const g2 = GUID{ .id = 0x1234567890abcdef1234567890abcdef };
    const g3 = GUID.one;

    try std.testing.expectFmt("00000000000000000000000000000000", "{f}", .{g0});
    try std.testing.expectFmt("00000000000000000000000000123abc", "{f}", .{g1});
    try std.testing.expectFmt("1234567890abcdef1234567890abcdef", "{f}", .{g2});
    try std.testing.expectFmt("ffffffffffffffffffffffffffffffff", "{f}", .{g3});
}

test scanMetafile {
    const meta =
        \\ guid: 0123456789abcdef0123456789abcdef
    ;

    var buf: [32]u8 = undefined;
    var rdr = std.Io.Reader.fixed(meta);

    const guid = try scanMetafile(&rdr, &buf, std.testing.allocator);
    try std.testing.expectEqualStrings("0123456789abcdef0123456789abcdef", guid);
}

test scanMetafileAlloc {
    const meta =
        \\ guid: 0123456789abcdef0123456789abcdef
    ;

    var rdr = std.Io.Reader.fixed(meta);

    const guid = try scanMetafileAlloc(&rdr, std.testing.allocator);
    defer std.testing.allocator.free(guid);
    try std.testing.expectEqualStrings("0123456789abcdef0123456789abcdef", guid);
}
