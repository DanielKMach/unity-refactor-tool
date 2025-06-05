const std = @import("std");

const This = @This();

const Data = struct {
    name: []const u8,
    start: i64,
};

allocator: std.mem.Allocator,
data: std.AutoHashMap(std.Thread.Id, std.ArrayList(Data)),
output: std.fs.File,

outputMtx: std.Thread.Mutex = .{},
dataMtx: std.Thread.Mutex = .{},

pub fn init(path: []const u8, allocator: std.mem.Allocator) !This {
    return This{
        .allocator = allocator,
        .output = try std.fs.cwd().createFile(path, .{ .lock = .exclusive }),
        .data = .init(allocator),
    };
}

pub fn deinit(self: *This) void {
    self.output.close();
    var ite = self.data.iterator();
    while (ite.next()) |*entry| {
        entry.value_ptr.deinit();
    }
    self.data.deinit();
}

pub fn begin(self: *This, comptime func: anytype) !void {
    if (@typeInfo(@TypeOf(func)) != .@"fn") {
        @compileError("func must be a function");
    }

    const name = comptime getFnName(func);
    const thread = std.Thread.getCurrentId();
    const start = std.time.microTimestamp();

    self.dataMtx.lock();
    defer self.dataMtx.unlock();

    if (self.data.get(thread) == null) {
        try self.data.put(thread, .init(self.allocator));
    }

    try self.data.getPtr(thread).?.append(Data{
        .name = name,
        .start = start,
    });
}

pub fn stop(self: *This) !void {
    const thread = std.Thread.getCurrentId();
    const end = std.time.microTimestamp();

    self.dataMtx.lock();
    defer self.dataMtx.unlock();

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
    self.outputMtx.lock();
    defer self.outputMtx.unlock();

    const writer = self.output.writer();
    _ = try writer.write("]}");

    self.deinit();
}

fn getFnName(func: anytype) []const u8 {
    if (@typeInfo(@TypeOf(func)) != .@"fn") {
        @compileError("func must be a function");
    }
    return @typeName(@TypeOf(func));
}

fn writeData(self: *This, name: []const u8, tid: std.Thread.Id, dur: i64, ts: i64) !void {
    self.outputMtx.lock();
    defer self.outputMtx.unlock();

    var bufwtr = std.io.bufferedWriter(self.output.writer());
    const writer = bufwtr.writer();

    if (try self.output.getPos() == 0) {
        _ = try writer.write("{\"traceEvents\": [");
    } else {
        _ = try writer.write(", ");
    }

    try writer.print("{{ \"cat\": \"function\", \"name\": \"{s}\", \"ph\": \"X\", \"pid\": 0, \"tid\": {d}, \"dur\": {d}, \"ts\": {d} }}", .{ name, tid, dur, ts });
    try bufwtr.flush();
}
