const std = @import("std");
const core = @import("core");

const log = std.log.scoped(.expr_object);

const List = @This();
const Value = core.Expr.Value;
const Object = Value.Object;
const yaml = core.yaml;
const ly = yaml.ly;

const SetError = std.mem.Allocator.Error || yaml.LibyamlError || error{OutOfBounds};

node: *yaml.Node,
doc: *yaml.Document,

pub fn get(self: List, index: usize) ?Value {
    const node = yaml.getItem(self.doc.*, self.node.*, index) orelse return null;
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

pub fn push(self: List, value: Value) SetError!void {
    std.debug.assert(self.node.type == ly.YAML_SEQUENCE_NODE);
    const nodes = yaml.fromStack(yaml.Node, self.doc.nodes);
    const vnode = try Object.nodeFromValue(self.doc, value);
    const vnode_id: c_int = @intCast(vnode - nodes.ptr + 1);

    if (ly.yaml_document_append_sequence_item(self.doc, self.node, vnode_id) == 0) {
        return error.LibyamlError;
    }
}

pub fn len(self: List) usize {
    std.debug.assert(self.node.type == ly.YAML_SEQUENCE_NODE);
    return self.node.data.sequence.items.top - self.node.data.sequence.items.start;
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
