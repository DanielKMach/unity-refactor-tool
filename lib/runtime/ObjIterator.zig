//! Iterates through all Unity object definitions in a file.

const std = @import("std");
const tracy = @import("tracy");
const core = @import("core");

const log = std.log.scoped(.component_iterator);

const This = @This();

pub const ParseHeaderError = error{InvalidHeader};
pub const IterateError = ParseHeaderError || std.mem.Allocator.Error || std.Io.Reader.Error || std.Io.Reader.DelimiterError || std.fs.File.Reader.SeekError;
pub const PatchError = IterateError || std.Io.Writer.Error || std.Io.Reader.StreamError;

pub const Info = struct {
    pos: usize,
    len: usize,
    class_id: core.runtime.ClassID,
    file_id: core.runtime.FileID,
    stripped: bool,
};

pub const Entry = struct {
    info: Info,
    content: []const u8,
};

freader: std.fs.File.Reader,
allocator: std.mem.Allocator,
last: ?Entry,

pub fn init(file: std.fs.File, allocator: std.mem.Allocator) std.mem.Allocator.Error!This {
    const buf = try allocator.alloc(u8, 4096);
    return This{
        .freader = file.reader(buf),
        .allocator = allocator,
        .last = null,
    };
}

pub fn deinit(self: *This) void {
    self.allocator.free(self.freader.interface.buffer);
    self.freeLast();
    self.* = undefined;
}

pub fn next(self: *This) IterateError!?Entry {
    const zone = tracy.Zone(@src());
    defer zone.End();

    var target: usize = 0;
    if (self.last) |lst| {
        target = lst.info.pos + lst.info.len;
        self.freeLast();
    }
    if (self.freader.logicalPos() != target) {
        try self.freader.seekTo(target);
    }

    var out = std.Io.Writer.Allocating.init(self.allocator);
    defer out.deinit();

    const info = fetchNext(&self.freader, &out.writer) catch |err| switch (err) {
        error.WriteFailed => return error.OutOfMemory,
        error.EndOfStream => return null,
        else => |e| return e,
    };
    std.debug.assert(info.len == out.written().len);

    self.last = .{ .info = info, .content = try out.toOwnedSlice() };
    return self.last;
}

fn freeLast(self: *This) void {
    if (self.last) |doc| {
        self.allocator.free(doc.content);
        self.last = null;
    }
}

/// Fetches the next object definition from `freader`.
/// The yaml document is written to `out` while the object information is returned.
///
/// The seek position must be initially located at the start
/// of an object header or yaml directive.
fn fetchNext(freader: *std.fs.File.Reader, out: *std.Io.Writer) !Info {
    const zone = tracy.Zone(@src());
    defer zone.End();

    var reader = &freader.interface;
    const head = while (true) { // search for next obj header
        const ln = try reader.takeDelimiterInclusive('\n');
        if (ln.len == 0 or ln[0] == '%') continue; // skip %YAML %TAG and empty lines
        if (std.mem.startsWith(u8, ln, "--- !u!")) break ln;

        log.err("Expected obj header, found \"{s}\"", .{ln});
        return error.InvalidHeader;
    };

    const pos = freader.logicalPos();
    const cid, const fid, const strp = parseHeader(head) catch |err| {
        log.err("Invalid parseHeader(\"{s}\") close to pos {d}", .{ head, pos });
        return err;
    };

    while (true) { // read until next header or eof
        const ln = reader.peekDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                _ = try reader.streamRemaining(out);
                break;
            },
            error.StreamTooLong => { // skip long lines
                _ = try reader.streamDelimiter(out, '\n');
                try reader.streamExact(out, 1);
                continue;
            },
            else => |e| return e,
        };
        if (std.mem.startsWith(u8, ln, "--- !u!")) break; // break if header
        try reader.streamExact(out, ln.len);
    }

    return .{
        .pos = pos,
        .len = freader.logicalPos() - pos,
        .class_id = @enumFromInt(cid),
        .file_id = fid,
        .stripped = strp,
    };
}

fn parseHeader(line: []const u8) ParseHeaderError!struct { u32, core.runtime.FileID, bool } {
    var rdr: std.Io.Reader = .fixed(std.mem.trimRight(u8, line, "\r\n"));

    var buf: []u8 = rdr.take(7) catch return error.InvalidHeader;
    if (!std.mem.eql(u8, buf, "--- !u!")) return error.InvalidHeader;
    buf = rdr.takeDelimiterExclusive(' ') catch return error.InvalidHeader;
    const class_id = std.fmt.parseInt(u32, buf, 10) catch return error.InvalidHeader;
    buf = rdr.takeDelimiterExclusive(' ') catch return error.InvalidHeader;
    if (buf[0] != '&') return error.InvalidHeader;
    const file_id = std.fmt.parseInt(i64, buf[1..], 10) catch return error.InvalidHeader;
    buf = rdr.buffered();
    const stripped = buf.len > 0 and std.mem.eql(u8, buf, "stripped");

    return .{ class_id, file_id, stripped };
}

pub fn patch(self: *This, out: *std.Io.Writer, entries: []const Entry) PatchError!void {
    try self.freader.seekTo(0);
    var reader = &self.freader.interface;

    var last_index: usize = 0;
    for (entries) |e| {
        try reader.streamExact(out, e.info.pos - last_index);
        try out.writeAll(e.content);
        try reader.discardAll(e.info.len);
        last_index = e.info.pos + e.info.len;
    }

    _ = try reader.streamRemaining(out);
    try out.flush();
}

test parseHeader {
    inline for (.{
        "--- !u!104 &2",
        "--- !u!104 &2\n",
        "--- !u!104 &2\r\n",
    }) |i| {
        const h = try parseHeader(i);
        try std.testing.expectEqual(104, h[0]);
        try std.testing.expectEqual(2, h[1]);
        try std.testing.expectEqual(false, h[2]);
    }

    inline for (.{
        "--- !u!4 &986831988 stripped",
        "--- !u!4 &986831988 stripped\n",
        "--- !u!4 &986831988 stripped\r\n",
    }) |i| {
        const h = try parseHeader(i);
        try std.testing.expectEqual(4, h[0]);
        try std.testing.expectEqual(986831988, h[1]);
        try std.testing.expectEqual(true, h[2]);
    }

    inline for (.{
        "--- !u!114 &-8338380993658723609",
        "--- !u!114 &-8338380993658723609\n",
        "--- !u!114 &-8338380993658723609\r\n",
    }) |i| {
        const h = try parseHeader(i);
        try std.testing.expectEqual(114, h[0]);
        try std.testing.expectEqual(-8338380993658723609, h[1]);
        try std.testing.expectEqual(false, h[2]);
    }

    try std.testing.expectError(error.InvalidHeader, parseHeader(""));
    try std.testing.expectError(error.InvalidHeader, parseHeader("--- !u!"));
    try std.testing.expectError(error.InvalidHeader, parseHeader("--- !u!104"));
    try std.testing.expectError(error.InvalidHeader, parseHeader("--- !u!104 &"));
    try std.testing.expectError(error.InvalidHeader, parseHeader("--- !u!104 &-"));
    try std.testing.expectError(error.InvalidHeader, parseHeader("--- !u! &2"));
    try std.testing.expectError(error.InvalidHeader, parseHeader("\n--- !u!104 &2"));
    try std.testing.expectError(error.InvalidHeader, parseHeader("\r\n--- !u!104 &2"));
}
