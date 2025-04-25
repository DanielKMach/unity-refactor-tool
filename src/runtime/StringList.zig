const std = @import("std");

const This = @This();
pub const AccessError = error{OutOfBounds};
pub const UpdateError = AccessError || std.mem.Allocator.Error;

ctx: std.ArrayList([]u8),

pub fn init(allocator: std.mem.Allocator) This {
    return This{
        .ctx = .init(allocator),
    };
}

pub fn deinit(self: This) void {
    for (self.ctx.items) |item| {
        self.ctx.allocator.free(item);
    }
    self.ctx.deinit();
}

pub fn length(self: This) usize {
    return self.ctx.items.len;
}

pub fn get(self: *This, index: usize) AccessError![]u8 {
    if (index >= self.ctx.items.len) {
        return error.OutOfBounds;
    }
    return self.ctx.items[index];
}

pub fn set(self: *This, index: usize, str: []const u8) UpdateError!void {
    if (index >= self.ctx.items.len) {
        return error.OutOfBounds;
    }
    const item = self.ctx.items[index];
    self.ctx.allocator.free(item);
    self.ctx.items[index] = try self.ctx.allocator.dupe(u8, str);
}

pub fn push(self: *This, str: []const u8) std.mem.Allocator.Error!void {
    try self.ctx.append(try self.ctx.allocator.dupe(u8, str));
}

pub fn pushSlice(self: *This, slice: []const []const u8) std.mem.Allocator.Error!void {
    for (slice) |item| {
        try self.push(item);
    }
}

pub fn pull(self: *This) ?[]u8 {
    return self.ctx.pop();
}

pub fn pop(self: *This, index: usize) UpdateError![]u8 {
    if (index >= self.ctx.items.len) {
        return error.OutOfBounds;
    }
    return try self.ctx.orderedRemove(index);
}

pub fn remove(self: *This, index: usize) UpdateError!void {
    if (index >= self.ctx.items.len) {
        return error.OutOfBounds;
    }
    const str = self.ctx.orderedRemove(index);
    self.ctx.allocator.free(str);
}

pub fn clear(self: *This) void {
    for (self.ctx.items) |item| {
        self.ctx.allocator.free(item);
    }
    self.ctx.clearAndFree();
}

pub fn toOwnedSlice(self: *This) ![][]u8 {
    return try self.ctx.toOwnedSlice();
}
