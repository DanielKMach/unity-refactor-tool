const std = @import("std");

const This = @This();
const FragFn = *const fn (data: *anyopaque, entry: std.fs.Dir.Walker.Entry) anyerror!void;

fragFn: FragFn,
allocator: std.mem.Allocator,
threads: []std.Thread,

walker: ?std.fs.Dir.Walker,
walkerMtx: std.Thread.Mutex,

pub fn init(dir: std.fs.Dir, fragFn: FragFn, allocator: std.mem.Allocator) !This {
    const walker = try dir.walk(allocator);

    return This{
        .fragFn = fragFn,
        .walker = walker,
        .walkerMtx = std.Thread.Mutex{},
        .allocator = allocator,
        .threads = try allocator.alloc(std.Thread, 10),
    };
}

pub fn deinit(self: *This) void {
    if (self.walker) |*wlkr| wlkr.deinit();
    self.allocator.free(self.threads);
}

pub fn scan(self: *This, data: *anyopaque) !void {
    for (self.threads) |*thread| {
        thread.* = try std.Thread.spawn(.{ .allocator = self.allocator }, loop, .{ self, data });
    }

    for (self.threads) |thread| {
        thread.join();
    }
}

fn loop(self: *This, data: *anyopaque) !void {
    while (true) {
        var entry: std.fs.Dir.Walker.Entry = undefined;
        if (self.walker) |*wlkr| {
            self.walkerMtx.lock();
            defer self.walkerMtx.unlock();
            entry = if (try wlkr.next()) |e| e else break;
        }
        try self.fragFn(data, entry);
    }
}
