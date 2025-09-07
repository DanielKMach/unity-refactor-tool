const std = @import("std");

pub const Value = union(enum) {
    pub const Type = @typeInfo(Value).@"union".tag_type orelse unreachable;

    nil,
    string: []const u8,
    number: f32,
    object: void,
    array: void,

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
};
