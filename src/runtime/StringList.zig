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
    const new_item = try self.allocator.dupe(u8, str);
    errdefer self.allocator.free(new_item);
    const old_item = self.ctx.items[index];
    self.allocator.free(old_item);
    self.ctx.items[index] = new_item;
}

pub fn push(self: *This, str: []const u8) std.mem.Allocator.Error!void {
    const new_elem = try self.allocator.dupe(u8, str);
    errdefer self.allocator.free(new_elem);
    try self.ctx.append(self.allocator, new_elem);
}

pub fn pushSlice(self: *This, slice: []const []const u8) std.mem.Allocator.Error!void {
    for (slice) |item| {
        try self.push(item);
    }
}

pub fn pop(self: *This, allocator: std.mem.Allocator) std.mem.Allocator.Error!?[]u8 {
    if (self.length() == 0) return null;
    const popped = try allocator.dupe(u8, self.ctx.items[self.ctx.items.len - 1]);
    errdefer allocator.free(popped);
    self.allocator.free(self.ctx.pop().?);
    return popped;
}

pub fn pull(self: *This, index: usize, allocator: std.mem.Allocator) UpdateError![]u8 {
    if (index >= self.ctx.items.len) {
        return error.OutOfBounds;
    }
    const pulled = try allocator.dupe(u8, self.ctx.items[index]);
    errdefer allocator.free(pulled);
    self.allocator.free(self.ctx.orderedRemove(index));
    return pulled;
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

pub fn has(self: *This, str: []const u8) bool {
    return for (self.ctx.items) |item| {
        if (std.mem.eql(u8, item, str)) break true;
    } else false;
}

pub fn toOwnedSlice(self: *This) ![][]u8 {
    return try self.ctx.toOwnedSlice(self.allocator);
}
