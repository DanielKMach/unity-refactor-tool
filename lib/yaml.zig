const std = @import("std");
const core = @import("core");

/// LibYAML bindings
pub const ly = @import("libyaml");

pub const Document = ly.yaml_document_t;
pub const Node = ly.yaml_node_t;
pub const Pair = ly.yaml_node_pair_t;
pub const Parser = ly.yaml_parser_t;
pub const Emitter = ly.yaml_emitter_t;
pub const Event = ly.yaml_event_t;
pub const Token = ly.yaml_token_t;

const NodeID = c_int;

pub const LibyamlError = error{LibyamlError};

/// Gets an item from a sequence node by its index.
///
/// Asserts that the given node is a sequence node.
pub fn getItem(doc: Document, node: Node, index: usize) ?*Node {
    std.debug.assert(node.type == ly.YAML_SEQUENCE_NODE);
    const nodes = fromStack(Node, doc.nodes);
    const items = fromStack(NodeID, node.data.sequence.items);
    if (index >= items.len) return null;
    const id: NodeID = items[index];
    return &nodes[@intCast(id - 1)];
}

/// Gets a key-value pair from a mapping node by its key.
///
/// Asserts that the given node is a mapping node.
pub fn getPair(doc: Document, node: Node, key: []const u8) ?*Pair {
    std.debug.assert(node.type == ly.YAML_MAPPING_NODE);
    const nodes = fromStack(Node, doc.nodes);
    const pairs = fromStack(Pair, node.data.mapping.pairs);

    for (pairs) |*pair| {
        // I dont know why but whoever wrote libyaml decided to make these 1-based indexes
        const knode = &nodes[@intCast(pair.key - 1)];
        std.debug.assert(knode.type == ly.YAML_SCALAR_NODE);
        if (std.mem.eql(u8, fromBuffer(u8, knode.data.scalar), key)) {
            return pair;
        }
    }
    return null;
}

/// Gets a node from a mapping node by its key.
///
/// Asserts that the given node is a mapping node.
pub fn getNode(doc: Document, node: Node, key: []const u8) ?*Node {
    std.debug.assert(node.type == ly.YAML_MAPPING_NODE);
    const target_pair = getPair(doc, node, key) orelse return null;
    const nodes = fromStack(Node, doc.nodes);

    return &nodes[@intCast(target_pair.value - 1)];
}

/// Converts a libyaml buffer into a slice.
pub fn fromBuffer(comptime T: type, buf: anytype) []T {
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
pub fn fromStack(comptime T: type, stack: anytype) []T {
    comptime std.debug.assert(@TypeOf(stack.start) == [*c]T);
    comptime std.debug.assert(@TypeOf(stack.top) == [*c]T);
    const len = stack.top - stack.start;
    return stack.start[0..len];
}
