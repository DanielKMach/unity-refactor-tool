const std = @import("std");

const log = std.log.scoped(.component_iterator);

const This = @This();
const History = @import("history.zig").History;

pub const IterateError = std.mem.Allocator.Error || std.Io.Reader.Error || std.Io.Reader.DelimiterError || std.fs.File.Reader.SeekError;
pub const PatchError = IterateError || std.Io.Writer.Error || std.Io.Reader.StreamError;

pub const Component = struct {
    index: usize,
    len: usize,
    document: []const u8,
};

freader: std.fs.File.Reader,
allocator: std.mem.Allocator,
last: ?Component,

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

pub fn next(self: *This) IterateError!?Component {
    var reader = &self.freader.interface;

    var target: usize = 0;
    if (self.last) |c| {
        target = c.index + c.len;
        self.freeLast();
    }
    try self.freader.seekTo(target);

    const index, const len = findNextComponent(&self.freader) catch |err| switch (err) {
        error.EndOfStream => return null,
        else => return err,
    };
    std.debug.assert(len != 0);

    try self.freader.seekTo(index);
    const doc = try reader.readAlloc(self.allocator, len);
    std.debug.assert(doc.len == len);

    const comp = Component{
        .index = index,
        .len = len,
        .document = doc,
    };
    self.last = comp;
    return comp;
}

fn freeLast(self: *This) void {
    if (self.last) |c| {
        self.allocator.free(c.document);
        self.last = null;
    }
}

fn findNextComponent(freader: *std.fs.File.Reader) ![2]usize {
    var reader = &freader.interface;
    var line: []u8 = try reader.takeDelimiterInclusive('\n');

    while (line[0] == '%' or std.mem.startsWith(u8, line, "--- ")) {
        line = try reader.takeDelimiterInclusive('\n');
    }

    const index = freader.logicalPos() - line.len;
    while (!std.mem.startsWith(u8, line, "--- ")) {
        line = reader.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => return .{ index, freader.logicalPos() - index },
            else => return err,
        };
    }

    return .{ index, freader.logicalPos() - line.len - index };
}

pub fn patch(self: *This, out: *std.Io.Writer, components: []const Component) PatchError!void {
    try self.freader.seekTo(0);
    var reader = &self.freader.interface;

    var last_index: usize = 0;
    for (components) |comp| {
        try reader.streamExact(out, comp.index - last_index);
        try out.writeAll(comp.document);
        last_index = comp.index + comp.len;
        try self.freader.seekTo(last_index);
    }

    _ = try reader.streamRemaining(out);
}
