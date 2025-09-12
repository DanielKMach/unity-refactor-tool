const std = @import("std");
const log = std.log.scoped(.error_log);

pub fn Diagnostics(comptime T: type, comptime e: anytype) type {
    return struct {
        const This = @This();

        pub const Problem = T;
        pub const Error = @TypeOf(e);

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

const RuntimeErrorLog = Diagnostics(usize, error.USRLRuntimeError);

test "usage" {
    var error_log: RuntimeErrorLog = .init(std.testing.allocator);
    defer error_log.deinit();

    try std.testing.expectEqual(error.USRLRuntimeError, error_log.push(1));
    try std.testing.expectEqual(error.USRLRuntimeError, error_log.push(2));
    try std.testing.expectEqual(error.USRLRuntimeError, error_log.push(3));

    const errors = try error_log.toOwnedSlice();
    defer std.testing.allocator.free(errors);
    try std.testing.expectEqual(3, errors.len);
    try std.testing.expectEqual(1, errors[0]);
    try std.testing.expectEqual(2, errors[1]);
    try std.testing.expectEqual(3, errors[2]);
}

fn triggerErrdefer(error_log: *RuntimeErrorLog, ptr: *bool) anyerror!void {
    errdefer ptr.* = true;
    return error_log.push(42);
}

test triggerErrdefer {
    var error_log: RuntimeErrorLog = .init(std.testing.allocator);
    defer error_log.deinit();

    var errderer_triggered: bool = false;
    try std.testing.expectError(error.USRLRuntimeError, triggerErrdefer(&error_log, &errderer_triggered));
    try std.testing.expect(errderer_triggered);

    const errors = try error_log.toOwnedSlice();
    defer std.testing.allocator.free(errors);
    try std.testing.expectEqual(1, errors.len);
    try std.testing.expectEqual(42, errors[0]);
}
