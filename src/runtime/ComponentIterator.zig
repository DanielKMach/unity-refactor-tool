const std = @import("std");

const This = @This();
const History = @import("history.zig").History;

pub const Component = struct {
    index: usize,
    len: usize,
    document: []u8,
};

allocator: std.mem.Allocator,
file: std.fs.File,
last: ?Component,

pub fn init(file: std.fs.File, allocator: std.mem.Allocator) This {
    return This{
        .allocator = allocator,
        .file = file,
        .last = null,
    };
}

pub fn deinit(self: *This) void {
    self.freeLast();
}

pub fn next(self: *This) !?Component {
    const reader = self.file.reader();
    const seekable = self.file.seekableStream();

    var target: usize = 0;
    if (self.last) |c| {
        target = c.index + c.len;
        self.freeLast();
    }
    try seekable.seekTo(target);

    var index: usize = undefined;
    var len: usize = undefined;
    findNextComponent(reader, seekable, &index, &len) catch |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    };

    if (len == 0) {
        return null;
    }

    const buf = try self.allocator.alloc(u8, len);

    try seekable.seekTo(index);
    const count = try reader.read(buf);
    std.debug.assert(count == buf.len);

    const comp = Component{
        .index = index,
        .len = len,
        .document = buf,
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

fn findNextComponent(reader: std.fs.File.Reader, seekable: std.fs.File.SeekableStream, index: *usize, len: *usize) !void {
    var last_chars = History(u8, 8).empty;
    var c: u8 = undefined;

    index.* = try seekable.getPos();
    len.* = 0;
    while (true) {
        c = try reader.readByte();
        last_chars.push(c);
        len.* += 1;

        if (c == '%' and (last_chars.last(1) == '\n' or last_chars.last(1) == null)) {
            if (len.* - 1 > 0) {
                len.* -= 1;
                break;
            }
            while (c != '\n') {
                c = try reader.readByte();
                last_chars.push(c);
            }
            index.* = try seekable.getPos();
            len.* = 0;
        }

        if (c == '-' and last_chars.last(1) == '-' and (last_chars.last(2) == '\n' or last_chars.last(2) == null)) {
            if (len.* - 2 > 0) {
                len.* -= 2;
                break;
            }
            while (c != '\n') {
                c = try reader.readByte();
                last_chars.push(c);
            }
            index.* = try seekable.getPos();
            len.* = 0;
        }
    }
}

pub fn patch(self: This, out: std.fs.File, components: []Component) !void {
    var bufwtr = std.io.bufferedWriter(out.writer());

    const writer = bufwtr.writer();
    const reader = self.file.reader();
    const seekable = self.file.seekableStream();

    try seekable.seekTo(0);
    var buf: [4096]u8 = undefined;

    var i: usize = 0;
    for (components) |comp| {
        var len: usize = undefined;
        var count: usize = undefined;
        while (true) {
            len = @min(comp.index - i, buf.len);
            if (len == 0) break;
            count = try reader.read(buf[0..len]);
            if (count == 0) break;
            _ = try writer.write(buf[0..count]);
            i += count;
        }
        _ = try writer.write(comp.document);
        try seekable.seekTo(comp.index + comp.len);
    }

    while (true) {
        const count = try reader.read(buf[0..]);
        if (count == 0) break;
        _ = try writer.write(buf[0..count]);
    }

    try bufwtr.flush();
}
