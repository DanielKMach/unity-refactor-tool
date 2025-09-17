const std = @import("std");
const core = @import("core");

const Value = core.Expr.Value;
const VarMap = @This();

allocator: std.mem.Allocator,
readonly: std.StringHashMap(Value),
readwrite: std.StringHashMap(Value),

const ReadOnlyError = error{ReadOnly};

pub const GetError = error{UndefinedVariable};
pub const SetError = std.mem.Allocator.Error || ReadOnlyError || GetError;
pub const DefineError = std.mem.Allocator.Error || ReadOnlyError || error{AlreadyDefined};

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

pub fn get(self: *VarMap, name: []const u8) GetError!Value {
    std.debug.assert(!self.readonly.contains(name) or !self.readwrite.contains(name));
    return self.readwrite.get(name) orelse self.readonly.get(name) orelse error.UndefinedVariable;
}

pub fn set(self: *VarMap, name: []const u8, value: Value) SetError!void {
    if (self.readonly.contains(name)) {
        return error.ReadOnly;
    }
    if (!self.readwrite.contains(name)) {
        return error.UndefinedVariable;
    }
    try self.readwrite.put(name, value);
}

pub fn define(self: *VarMap, name: []const u8, value: Value) DefineError!void {
    if (self.readonly.contains(name)) {
        return error.ReadOnly;
    }
    if (self.readwrite.contains(name)) {
        return error.AlreadyDefined;
    }
    try self.readwrite.put(name, value);
}
