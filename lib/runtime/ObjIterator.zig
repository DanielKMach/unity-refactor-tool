//! Iterates through all Unity object definitions in a file.

const std = @import("std");
const tracy = @import("tracy");
const core = @import("core");

const log = std.log.scoped(.component_iterator);

const This = @This();
const History = @import("history.zig").History;

pub const ParseHeaderError = error{InvalidHeader};
pub const IterateError = ParseHeaderError || std.mem.Allocator.Error || std.Io.Reader.Error || std.Io.Reader.DelimiterError || std.fs.File.Reader.SeekError;
pub const PatchError = IterateError || std.Io.Writer.Error || std.Io.Reader.StreamError;

pub const Info = struct {
    pos: usize,
    len: usize,
    class_id: core.runtime.ClassID,
    file_id: u64,
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

    var reader = &self.freader.interface;

    var target: usize = 0;
    if (self.last) |lst| {
        target = lst.info.pos + lst.info.len;
        self.freeLast();
    }
    try self.freader.seekTo(target);

    const info = findNextComponent(&self.freader) catch |err| switch (err) {
        error.EndOfStream => return null,
        else => return err,
    };

    try self.freader.seekTo(info.pos);
    const content = try reader.readAlloc(self.allocator, info.len);
    std.debug.assert(content.len == info.len);

    self.last = .{ .info = info, .content = content };
    return .{ .info = info, .content = content };
}

fn freeLast(self: *This) void {
    if (self.last) |doc| {
        self.allocator.free(doc.content);
        self.last = null;
    }
}

fn findNextComponent(freader: *std.fs.File.Reader) !Info {
    const zone = tracy.Zone(@src());
    defer zone.End();

    var reader = &freader.interface;
    var line: []u8 = &.{};

    while (true) { // search for next obj instance header
        var peek: std.Io.Reader.DelimiterError![]u8 = reader.peekDelimiterInclusive('\n');
        while (peek == error.StreamTooLong) { // skip long lines
            _ = try reader.discardDelimiterInclusive('\n');
            peek = reader.peekDelimiterInclusive('\n');
        }
        const p = peek catch |e| return e;
        if (p[0] != '%' and !std.mem.startsWith(u8, p, "--- ")) break;
        line = try reader.takeDelimiterInclusive('\n');
    }

    const header = try parseHeader(line);
    const index = freader.logicalPos();
    while (true) { // read until next obj instance header
        line = reader.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => return .{ // return rest if doesnt find next obj instance header
                .pos = index,
                .len = freader.logicalPos() - index,
                .class_id = @enumFromInt(header[0]),
                .file_id = header[1],
                .stripped = header[2],
            },
            error.StreamTooLong => { // skip long lines
                _ = try reader.discardDelimiterInclusive('\n');
                continue;
            },
            else => return err,
        };
        if (std.mem.startsWith(u8, line, "--- ")) break; // break if header
    }

    return .{
        .pos = index,
        .len = freader.logicalPos() - line.len - index,
        .class_id = @enumFromInt(header[0]),
        .file_id = header[1],
        .stripped = header[2],
    };
}

fn parseHeader(line: []const u8) !struct { u32, u64, bool } {
    var rdr: std.Io.Reader = .fixed(std.mem.trimRight(u8, line, "\r\n"));

    var buf: []u8 = rdr.take(7) catch return error.InvalidHeader;
    if (!std.mem.eql(u8, buf, "--- !u!")) return error.InvalidHeader;
    buf = rdr.takeDelimiterExclusive(' ') catch return error.InvalidHeader;
    const class_id = std.fmt.parseInt(u32, buf, 10) catch return error.InvalidHeader;
    buf = rdr.takeDelimiterExclusive(' ') catch return error.InvalidHeader;
    if (buf[0] != '&') return error.InvalidHeader;
    const file_id = std.fmt.parseInt(u64, buf[1..], 10) catch return error.InvalidHeader;
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

    try std.testing.expectError(error.InvalidHeader, parseHeader(""));
    try std.testing.expectError(error.InvalidHeader, parseHeader("--- !u!"));
    try std.testing.expectError(error.InvalidHeader, parseHeader("--- !u!104"));
    try std.testing.expectError(error.InvalidHeader, parseHeader("--- !u!104 &"));
    try std.testing.expectError(error.InvalidHeader, parseHeader("--- !u! &2"));
    try std.testing.expectError(error.InvalidHeader, parseHeader("\n--- !u!104 &2"));
    try std.testing.expectError(error.InvalidHeader, parseHeader("\r\n--- !u!104 &2"));
}
