//! Iterates through all Unity object definitions in a file.

const std = @import("std");
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
    var reader = &freader.interface;
    var line: []u8 = &.{};
    var peek: []u8 = try reader.peekDelimiterInclusive('\n');

    while (peek[0] == '%' or std.mem.startsWith(u8, peek, "--- ")) {
        line = try reader.takeDelimiterInclusive('\n');
        peek = try reader.peekDelimiterInclusive('\n');
    }

    const header = try parseHeader(line);

    const index = freader.logicalPos();
    line = try reader.takeDelimiterInclusive('\n');

    while (!std.mem.startsWith(u8, line, "--- ")) {
        line = reader.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => return .{
                .pos = index,
                .len = freader.logicalPos() - index,
                .class_id = @enumFromInt(header[0]),
                .file_id = header[1],
                .stripped = header[2],
            },
            else => return err,
        };
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
    if (!std.mem.startsWith(u8, line, "--- !u!")) return error.InvalidHeader;
    var i: usize = 7;
    while (std.ascii.isDigit(line[i])) i += 1;
    const class_id = std.fmt.parseInt(u32, line[7..i], 10) catch return error.InvalidHeader;
    while (!std.ascii.isDigit(line[i])) i += 1;
    const s = i;
    while (i < line.len and std.ascii.isDigit(line[i])) i += 1;
    const file_id = std.fmt.parseInt(u64, line[s..i], 10) catch return error.InvalidHeader;
    const stripped = (i + 8 == line.len and std.mem.eql(u8, line[i..], " stripped"));

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
