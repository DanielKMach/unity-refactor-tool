const std = @import("std");

const This = @This();

const Data = struct {
    name: []const u8,
    start: i64,
};

allocator: std.mem.Allocator,
data: std.AutoHashMap(std.Thread.Id, std.ArrayList(Data)),
out: std.fs.File.Writer,
buf: []u8,

out_mtx: std.Thread.Mutex = .{},
data_mtx: std.Thread.Mutex = .{},

pub fn init(path: []const u8, allocator: std.mem.Allocator) !This {
    const buf = try allocator.alloc(u8, 1024);
    const file = try std.fs.cwd().createFile(path, .{ .lock = .exclusive });
    return This{
        .allocator = allocator,
        .data = .init(allocator),
        .out = file.writer(buf),
        .buf = buf,
    };
}

pub fn deinit(self: *This) void {
    self.out.file.close();
    self.allocator.free(self.buf);
    var ite = self.data.iterator();
    while (ite.next()) |*entry| {
        entry.value_ptr.deinit(self.allocator);
    }
    self.data.deinit();
    self.* = undefined;
}

pub fn begin(self: *This, comptime func: anytype) !void {
    if (@typeInfo(@TypeOf(func)) != .@"fn") {
        @compileError("func must be a function");
    }

    const name = comptime getFnName(func);
    const thread = std.Thread.getCurrentId();
    const start = std.time.microTimestamp();

    self.data_mtx.lock();
    defer self.data_mtx.unlock();

    if (self.data.get(thread) == null) {
        try self.data.put(thread, try .initCapacity(self.allocator, 64));
    }

    try self.data.getPtr(thread).?.append(self.allocator, .{
        .name = name,
        .start = start,
    });
}

pub fn stop(self: *This) !void {
    const thread = std.Thread.getCurrentId();
    const end = std.time.microTimestamp();

    self.data_mtx.lock();
    defer self.data_mtx.unlock();

    const data = self.data.getPtr(thread).?.pop() orelse return error.NoData;

    const ts = data.start;
    const dur = end - data.start;
    const name = data.name;

    var buf: [1024]u8 = undefined;
    const length = std.mem.replacementSize(u8, name, "\"", "\\\"");
    _ = std.mem.replace(u8, name, "\"", "\\\"", &buf);

    try writeData(self, buf[0..length], thread, dur, ts);
}

pub fn finalize(self: *This) !void {
    self.out_mtx.lock();
    defer self.out_mtx.unlock();

    const writer = &self.out.interface;
    try writer.writeAll("]}");
    try writer.flush();
}

fn getFnName(func: anytype) []const u8 {
    if (@typeInfo(@TypeOf(func)) != .@"fn") {
        @compileError("func must be a function");
    }
    return @typeName(@TypeOf(func));
}

fn writeData(self: *This, name: []const u8, tid: std.Thread.Id, dur: i64, ts: i64) !void {
    self.out_mtx.lock();
    defer self.out_mtx.unlock();

    const writer = &self.out.interface;

    if (self.out.pos == 0) {
        try writer.writeAll("{\"traceEvents\": [");
    } else {
        try writer.writeAll(", ");
    }

    try writer.print("{{ \"cat\": \"function\", \"name\": \"{s}\", \"ph\": \"X\", \"pid\": 0, \"tid\": {d}, \"dur\": {d}, \"ts\": {d} }}", .{ name, tid, dur, ts });
    try writer.flush();
}
