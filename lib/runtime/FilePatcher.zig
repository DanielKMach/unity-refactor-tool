const std = @import("std");
const log = std.log.scoped(.file_patcher);

const This = @This();

pub const StartError = std.fs.File.Reader.SeekError || std.mem.Allocator.Error;
pub const PatchError = std.Io.Reader.StreamError;
pub const FlushError = std.Io.Reader.StreamRemainingError;
pub const ApplyError = FlushError || std.fs.File.SetEndPosError || std.fs.File.Reader.SeekError;

allocator: std.mem.Allocator,
patcher: ?*Patcher,
from: std.fs.File,
to: std.fs.File,

pub fn init(from: std.fs.File, to: std.fs.File, allocator: std.mem.Allocator) This {
    const self = This{
        .allocator = allocator,
        .patcher = null,
        .from = from,
        .to = to,
    };

    return self;
}

pub fn start(self: *This) StartError!void {
    if (self.patcher) |_| @panic("Already patching");
    self.patcher = try newPatcher(self.from, self.to, self.allocator);
}

pub fn patch(self: *This, index: usize, length: usize, new_content: []const u8) PatchError!void {
    const patcher = self.patcher orelse @panic("Not patching. Call start() first.");
    try patcher.patch(index, length, new_content);
}

pub fn flush(self: *This) FlushError!void {
    const patcher = self.patcher orelse @panic("Not patching. Call start() first.");
    try patcher.flush();
    freePatcher(patcher, self.allocator);
    self.patcher = null;
}

pub fn apply(self: This) ApplyError!void {
    if (self.patcher) |_| @panic("Cannot stream back while patching. Use flush() first.");

    var wbuf: [4096]u8 = undefined;
    var writer = self.from.writer(&wbuf);
    try writer.seekTo(0);
    var rbuf: [4096]u8 = undefined;
    var reader = self.to.reader(&rbuf);
    try reader.seekTo(0);

    _ = try reader.interface.streamRemaining(&writer.interface);
    try writer.end();
}

pub fn deinit(self: *This) void {
    if (self.patcher) |p| {
        freePatcher(p, self.allocator);
        self.patcher = null;
    }
}

fn newPatcher(from: std.fs.File, to: std.fs.File, allocator: std.mem.Allocator) StartError!*Patcher {
    const wbuf = try allocator.alloc(u8, 4096);
    errdefer allocator.free(wbuf);
    var writer = to.writer(wbuf);
    try writer.seekTo(0);

    const rbuf = try allocator.alloc(u8, 4096);
    errdefer allocator.free(rbuf);
    var reader = from.reader(rbuf);
    try reader.seekTo(0);

    const patcher = try allocator.create(Patcher);
    patcher.* = .{
        .last_index = 0,
        .freader = reader,
        .fwriter = writer,
    };
    return patcher;
}

fn freePatcher(patcher: *Patcher, allocator: std.mem.Allocator) void {
    allocator.free(patcher.freader.interface.buffer);
    allocator.free(patcher.fwriter.interface.buffer);
    patcher.* = undefined;
    allocator.destroy(patcher);
}

const Patcher = struct {
    last_index: usize = 0,
    freader: std.fs.File.Reader,
    fwriter: std.fs.File.Writer,

    pub fn patch(self: *Patcher, index: usize, length: usize, new_content: []const u8) !void {
        const reader = &self.freader.interface;
        const writer = &self.fwriter.interface;

        try reader.streamExact(writer, index - self.last_index);
        try writer.writeAll(new_content);
        try reader.discardAll(length);
        self.last_index = index + length;
    }

    pub fn flush(self: *Patcher) std.Io.Reader.StreamRemainingError!void {
        const reader = &self.freader.interface;
        const writer = &self.fwriter.interface;

        _ = try reader.streamRemaining(writer);
        try writer.flush();
    }
};
