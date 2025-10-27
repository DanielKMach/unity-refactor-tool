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

pub fn deinit(self: *VarMap) void {
    var iterator = self.readwrite.iterator();
    while (iterator.next()) |entry| {
        self.allocator.free(entry.key_ptr.*);
        entry.value_ptr.cleanup(self.allocator);
    }
    self.readwrite.deinit();
    self.readonly.deinit();
}

pub fn default(allocator: std.mem.Allocator) std.mem.Allocator.Error!VarMap {
    var map: VarMap = .{
        .allocator = allocator,
        .readonly = .init(allocator),
        .readwrite = .init(allocator),
    };
    inline for (@typeInfo(Value.Func.builtin).@"struct".decls) |decl| {
        const d = @field(Value.Func.builtin, decl.name);
        try map.readonly.put(decl.name, .{ .func = comptime .new(&d) });
    }
    try map.readonly.put("pi", .{ .number = std.math.pi });
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
    const new_value = try value.dupe(self.allocator);
    const val = self.readwrite.getPtr(name) orelse unreachable;
    val.cleanup(self.allocator);
    val.* = new_value;
}

pub fn define(self: *VarMap, name: []const u8, value: Value) DefineError!void {
    if (self.readonly.contains(name)) {
        return error.ReadOnly;
    }
    if (self.readwrite.contains(name)) {
        return error.AlreadyDefined;
    }
    const varname = try self.allocator.dupe(u8, name);
    errdefer self.allocator.free(varname);
    const varvalue = try value.dupe(self.allocator);
    errdefer varvalue.cleanup(self.allocator);
    try self.readwrite.put(varname, varvalue);
}
