const std = @import("std");
const core = @import("core");

const Value = core.Expr.Value;
const VarMap = @This();

allocator: std.mem.Allocator,
map: std.StringHashMap(Value),

pub fn init(allocator: std.mem.Allocator) VarMap {
    return VarMap{
        .allocator = allocator,
        .map = .init(allocator),
    };
}

pub fn get(self: *VarMap, name: []const u8) ?Value {
    return self.map.get(name);
}

pub fn set(self: *VarMap, name: []const u8, value: Value) std.mem.Allocator.Error!void {
    try self.map.put(name, value);
}

pub fn has(self: *VarMap, name: []const u8) bool {
    return self.map.contains(name);
}
