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

// TODO: not allow redefinition
pub fn define(self: *VarMap, name: []const u8, value: Value) std.mem.Allocator.Error!void {
    self.set(name, value);
}

pub fn get(self: *VarMap, name: []const u8) ?Value {
    return self.map.get(name);
}

pub fn set(self: *VarMap, name: []const u8, value: Value) std.mem.Allocator.Error!void {
    self.map.put(name, value);
}
