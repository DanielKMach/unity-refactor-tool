const std = @import("std");

const This = @This();
pub const AccessError = error{OutOfBounds};
pub const UpdateError = AccessError || std.mem.Allocator.Error;

allocator: std.mem.Allocator,
ctx: std.ArrayList([]u8),

pub fn init(allocator: std.mem.Allocator) std.mem.Allocator.Error!This {
    return This{
        .allocator = allocator,
        .ctx = try .initCapacity(allocator, 1),
    };
}

pub fn deinit(self: *This) void {
    for (self.ctx.items) |item| {
        self.allocator.free(item);
    }
    self.ctx.deinit(self.allocator);
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
    self.allocator.free(item);
    self.ctx.items[index] = try self.allocator.dupe(u8, str);
}

pub fn push(self: *This, str: []const u8) std.mem.Allocator.Error!void {
    try self.ctx.append(self.allocator, try self.allocator.dupe(u8, str));
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
    return self.ctx.orderedRemove(index);
}

pub fn remove(self: *This, index: usize) UpdateError!void {
    if (index >= self.ctx.items.len) {
        return error.OutOfBounds;
    }
    const str = self.ctx.orderedRemove(index);
    self.allocator.free(str);
}

pub fn clear(self: *This) void {
    for (self.ctx.items) |item| {
        self.allocator.free(item);
    }
    self.ctx.clearAndFree(self.allocator);
}

pub fn toOwnedSlice(self: *This) ![][]u8 {
    return try self.ctx.toOwnedSlice(self.allocator);
}
