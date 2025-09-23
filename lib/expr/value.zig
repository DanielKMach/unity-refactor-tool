//! A value resulting from expression evaluation.

const std = @import("std");
const core = @import("core");

pub const Value = union(enum) {
    pub const Type = @typeInfo(Value).@"union".tag_type orelse unreachable;
    pub const Object = @import("value/Object.zig");
    pub const List = @import("value/List.zig");
    pub const Func = @import("value/Func.zig");

    nil,
    string: []const u8,
    number: f32,
    object: Object,
    array: List,
    func: Func,

    /// Duplicates this value into the given allocator.
    ///
    /// Unnecessary but safe to call if the value is not a string.
    pub fn dupe(self: Value, allocator: std.mem.Allocator) std.mem.Allocator.Error!Value {
        return switch (self) {
            .string => |s| .{ .string = try allocator.dupe(u8, s) },
            else => self,
        };
    }

    /// Frees the value.
    ///
    /// This function is intended to be called when a value is duplicated using `dupe`.
    /// The given allocator must be the same as the one used to duplicate the value.
    ///
    /// Unnecessary but safe to call if the value is not a string.
    pub fn cleanup(self: Value, allocator: std.mem.Allocator) void {
        switch (self) {
            .string => |s| allocator.free(s),
            else => {},
        }
    }

    /// Returns whether this value is "truthy" in a boolean context.
    pub fn isTruthy(self: Value) bool {
        return switch (self) {
            .nil => false,
            .number => |n| n != 0.0,
            .string => |s| s.len != 0,
            .object => true,
            .array => true,
            .func => true,
        };
    }

    pub fn stringify(self: Value, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try switch (self) {
            .nil => writer.print("NIL", .{}),
            .number => |n| try writer.print("{d}", .{n}),
            .string => |s| try writer.print("{s}", .{s}),
            .object => writer.print("[object]", .{}),
            .array => writer.print("[array]", .{}),
            .func => writer.print("[function]", .{}),
        };
    }

    /// A value from a source expression for better traceability.
    pub const Derived = struct {
        src: *core.Expr,
        val: Value,
    };

    pub fn validate(value: Derived, expected: []const Type, diag: *core.RuntimeDiagnostics) core.RuntimeDiagnostics.Error!void {
        const valid = for (expected) |t| {
            if (value.val == t) break true;
        } else false;

        if (!valid) return diag.push(.{
            .unexpected_type = .{
                .found = value.val,
                .location = value.src.loc(),
                .expected = expected,
            },
        });
    }

    pub fn eql(a: Value, b: Value) bool {
        if (@as(Value.Type, a) != @as(Value.Type, b)) return false;
        return switch (a) {
            .number => |a_number| a_number == b.number,
            .string => |a_string| std.mem.eql(u8, a_string, b.string),
            .nil => true,
            .object => |a_object| a_object.node == b.object.node,
            .array => @panic("TODO: Handle array"),
            .func => |a_func| a_func.ptr == b.func.ptr,
        };
    }
};
