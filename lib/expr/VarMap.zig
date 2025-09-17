const std = @import("std");
const core = @import("core");

const Value = core.Expr.Value;
const VarMap = @This();

allocator: std.mem.Allocator,
readonly: std.StringHashMap(Value),
readwrite: std.StringHashMap(Value),

pub fn init(allocator: std.mem.Allocator) VarMap {
    return .{
        .allocator = allocator,
        .readonly = .init(allocator),
        .readwrite = .init(allocator),
    };
}

pub fn default(allocator: std.mem.Allocator) VarMap {
    var map: VarMap = .{
        .allocator = allocator,
        .readonly = .init(allocator),
        .readwrite = .init(allocator),
    };
    map.readonly.put("min", .{ .func = .min }) catch unreachable;
    return map;
}

pub fn get(self: *VarMap, name: []const u8) ?Value {
    return self.readwrite.get(name) orelse self.readonly.get(name);
}

pub fn set(self: *VarMap, name: []const u8, value: Value) std.mem.Allocator.Error!void {
    try self.readwrite.put(name, value);
}

pub fn has(self: *VarMap, name: []const u8) bool {
    return self.readwrite.contains(name);
}
