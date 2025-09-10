const std = @import("std");
const core = @import("core");
const ly = @import("libyaml");

const log = std.log.scoped(.expr_object);

const Object = @This();
const Value = core.Expr.Value;
const YamlPair = ly.yaml_node_pair_t;
const YamlNode = ly.yaml_node_t;
const YamlDocument = ly.yaml_document_t;

node: *YamlNode,
document: *YamlDocument,

pub fn get(self: Object, key: []const u8) ?Value {
    const node = self.getNode(key) orelse return null;
    switch (node.type) {
        ly.YAML_SCALAR_NODE => {
            const scalar = node.data.scalar;
            const buf = valueLengthSlice(u8, scalar);

            switch (scalar.style) {
                ly.YAML_SINGLE_QUOTED_SCALAR_STYLE, ly.YAML_DOUBLE_QUOTED_SCALAR_STYLE => {
                    return .{ .string = buf };
                },
                else => {
                    if (buf.len == 0) return .nil;
                    if (std.fmt.parseFloat(f32, buf)) |num| {
                        return .{ .number = num };
                    } else |_| {
                        return .{ .string = buf };
                    }
                },
            }
        },
        ly.YAML_MAPPING_NODE => {
            return .{ .object = Object{
                .node = node,
                .document = self.document,
            } };
        },
        ly.YAML_SEQUENCE_NODE => @panic("TODO: Handle arrays"),
        else => unreachable,
    }
}

fn getNode(self: Object, key: []const u8) ?*YamlNode {
    std.debug.assert(self.node.type == ly.YAML_MAPPING_NODE);
    const nodes = startTopSlice(YamlNode, self.document.nodes);
    const pairs = startTopSlice(YamlPair, self.node.data.mapping.pairs);

    for (pairs) |pair| {
        // I dont know why but whoever wrote libyaml decided to make these 1-based indexes
        const knode = &nodes[@intCast(pair.key - 1)];
        const vnode = &nodes[@intCast(pair.value - 1)];
        std.debug.assert(knode.type == ly.YAML_SCALAR_NODE);
        if (std.mem.eql(u8, valueLengthSlice(u8, knode.data.scalar), key)) {
            return vnode;
        }
    }
    return null;
}

fn valueLengthSlice(comptime T: type, buf: anytype) []T {
    comptime std.debug.assert(@TypeOf(buf.value) == [*c]T);
    return buf.value[0..buf.length];
}

/// Converts a libyaml stack into a slice.
///
/// `start` and `end` refer to the maximum boundaries of the stack.
/// `top` is a dynamic pointer between `start` and `end` referring
/// to the current position, and changes as you push to or pop from the stack.
///
/// If `start` == `top`, the stack is empty.
fn startTopSlice(comptime T: type, stack: anytype) []T {
    comptime std.debug.assert(@TypeOf(stack.start) == [*c]T);
    comptime std.debug.assert(@TypeOf(stack.top) == [*c]T);
    const start = @intFromPtr(stack.start);
    const top = @intFromPtr(stack.top);
    const len = (top - start) / @sizeOf(T);
    return stack.start[0..len];
}
