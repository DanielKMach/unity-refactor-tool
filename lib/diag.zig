const std = @import("std");
const log = std.log.scoped(.error_log);

pub fn Diagnostics(comptime T: type, comptime e: anytype) type {
    return struct {
        const This = @This();

        pub const Problem = T;
        pub const Error = @TypeOf(e);

        pub const none: *This = @constCast(&This{
            .allocator = failing,
            .errors = .empty,
        });

        allocator: std.mem.Allocator,
        errors: std.ArrayList(T),

        pub fn init(allocator: std.mem.Allocator) This {
            return .{
                .allocator = allocator,
                .errors = .empty,
            };
        }

        pub fn push(self: *This, value: T) Error {
            self.errors.append(self.allocator, value) catch |err| {
                log.err("Failed to append error to log: {t}", .{err});
            };
            return e;
        }

        pub fn pop(self: *This) ?T {
            return self.errors.pop();
        }

        pub fn toOwnedSlice(self: *This) std.mem.Allocator.Error![]T {
            return self.errors.toOwnedSlice(self.allocator);
        }

        pub fn deinit(self: *This) void {
            self.errors.deinit(self.allocator);
            self.* = undefined;
        }
    };
}

// This eventually will be added to zig's std library
pub const failing: std.mem.Allocator = .{
    .ptr = undefined,
    .vtable = &.{
        .alloc = noAlloc,
        .resize = unreachableResize,
        .remap = unreachableRemap,
        .free = unreachableFree,
    },
};

pub fn noAlloc(
    self: *anyopaque,
    len: usize,
    alignment: std.mem.Alignment,
    ret_addr: usize,
) ?[*]u8 {
    _ = self;
    _ = len;
    _ = alignment;
    _ = ret_addr;
    return null;
}

fn unreachableResize(
    self: *anyopaque,
    memory: []u8,
    alignment: std.mem.Alignment,
    new_len: usize,
    ret_addr: usize,
) bool {
    _ = self;
    _ = memory;
    _ = alignment;
    _ = new_len;
    _ = ret_addr;
    unreachable;
}

fn unreachableRemap(
    self: *anyopaque,
    memory: []u8,
    alignment: std.mem.Alignment,
    new_len: usize,
    ret_addr: usize,
) ?[*]u8 {
    _ = self;
    _ = memory;
    _ = alignment;
    _ = new_len;
    _ = ret_addr;
    unreachable;
}

fn unreachableFree(
    self: *anyopaque,
    memory: []u8,
    alignment: std.mem.Alignment,
    ret_addr: usize,
) void {
    _ = self;
    _ = memory;
    _ = alignment;
    _ = ret_addr;
    unreachable;
}
