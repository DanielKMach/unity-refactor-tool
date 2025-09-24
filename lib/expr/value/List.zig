const std = @import("std");
const core = @import("core");

const log = std.log.scoped(.expr_object);

const List = @This();
const Value = core.Expr.Value;
const Object = Value.Object;
const yaml = core.yaml;
const ly = yaml.ly;

pub const GetError = error{OutOfBounds};
pub const PushError = std.mem.Allocator.Error || yaml.LibyamlError;
pub const SetError = GetError || std.mem.Allocator.Error || yaml.LibyamlError;

node: *yaml.Node,
doc: *yaml.Document,

pub fn get(self: List, index: usize) GetError!Value {
    const node = yaml.getItem(self.doc.*, self.node.*, index) orelse return error.OutOfBounds;
    return Object.valueFromNode(self.doc, node);
}

pub fn set(self: List, index: usize, value: Value) SetError!void {
    std.debug.assert(self.node.type == ly.YAML_SEQUENCE_NODE);
    if (index >= self.len()) return error.OutOfBounds;
    const nodes = yaml.fromStack(yaml.Node, self.doc.nodes);
    const vnode = try Object.nodeFromValue(self.doc, value);
    const vnode_id: c_int = @intCast(vnode - nodes.ptr + 1);

    const items = yaml.fromStack(c_int, self.node.data.sequence.items);
    items[index] = vnode_id;
}

pub fn push(self: List, value: Value) PushError!void {
    std.debug.assert(self.node.type == ly.YAML_SEQUENCE_NODE);
    const nodes = yaml.fromStack(yaml.Node, self.doc.nodes);
    const vnode = try Object.nodeFromValue(self.doc, value);
    const vnode_id: c_int = @intCast(vnode - nodes.ptr + 1);
    const id = self.node - nodes.ptr + 1;

    if (ly.yaml_document_append_sequence_item(self.doc, @intCast(id), vnode_id) == 0) {
        return error.LibyamlError;
    }
}

pub fn pop(self: List) ?Value {
    std.debug.assert(self.node.type == ly.YAML_SEQUENCE_NODE);
    const l = self.len();
    if (l == 0) return null;

    const items = yaml.fromStack(c_int, self.node.data.sequence.items);
    const vnode_id = items[l - 1];
    std.debug.assert(self.node.data.sequence.items.top > self.node.data.sequence.items.start);
    self.node.data.sequence.items.top -= 1;

    const nodes = yaml.fromStack(yaml.Node, self.doc.nodes);
    const vnode = &nodes[@intCast(vnode_id - 1)];
    return Object.valueFromNode(self.doc, vnode);
}

pub fn len(self: List) usize {
    std.debug.assert(self.node.type == ly.YAML_SEQUENCE_NODE);
    return self.node.data.sequence.items.top - self.node.data.sequence.items.start;
}

pub fn validateIndex(self: List, index: Value.Derived, diag: *core.RuntimeDiagnostics) core.RuntimeDiagnostics.Error!usize {
    try Value.validate(index, &.{.number}, diag);

    const float = index.val.number;
    if (std.math.isNan(float) or std.math.isInf(float) or @rem(float, 1) != 0) {
        return diag.push(.{ .invalid_index = .{
            .index = float,
            .location = index.src.loc(),
        } });
    }

    const idx: isize = @intFromFloat(float);
    if (idx < 0 or idx >= self.len()) {
        return diag.push(.{ .out_of_bounds = .{
            .index = idx,
            .len = self.len(),
            .location = index.src.loc(),
        } });
    }

    return @intCast(idx);
}

pub fn format(self: List, writer: *std.Io.Writer) std.Io.Writer.Error!void {
    std.debug.assert(self.node.type == ly.YAML_SEQUENCE_NODE);
    try writer.writeAll("[ ");
    const items = yaml.fromStack(c_int, self.node.data.sequence.items);
    const nodes = yaml.fromStack(yaml.Node, self.doc.nodes);
    for (items, 0..) |item, i| {
        if (i != 0) try writer.print(", ", .{});

        const vnode = &nodes[@intCast(item - 1)];
        const val = Object.valueFromNode(self.doc, vnode);

        try writer.print("{f}", .{val});
    }
    try writer.writeAll(" ]");
}
