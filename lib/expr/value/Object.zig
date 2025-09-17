const std = @import("std");
const core = @import("core");
const ly = @import("libyaml");

const log = std.log.scoped(.expr_object);

const Object = @This();
const Value = core.Expr.Value;
const YamlPair = ly.yaml_node_pair_t;
const YamlNode = ly.yaml_node_t;
const YamlDocument = ly.yaml_document_t;

const LibyamlError = error{LibyamlError};
const SetError = std.mem.Allocator.Error || LibyamlError;

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

pub fn set(self: Object, key: []const u8, value: Value) SetError!void {
    const allocator = std.heap.c_allocator;
    const value_node_id: c_int = switch (value) {
        .string => |str| blk: {
            const buf = try allocator.dupe(u8, str);
            break :blk ly.yaml_document_add_scalar(
                self.document,
                null, // No tag
                @ptrCast(buf),
                @intCast(buf.len),
                ly.YAML_DOUBLE_QUOTED_SCALAR_STYLE,
            );
        },
        .number => |num| blk: {
            const buf = try std.fmt.allocPrint(allocator, "{d}", .{num});
            break :blk ly.yaml_document_add_scalar(
                self.document,
                null, // No tag
                @ptrCast(buf),
                @intCast(buf.len),
                ly.YAML_PLAIN_SCALAR_STYLE,
            );
        },
        .nil => blk: {
            const buf = try allocator.alloc(u8, 0);
            break :blk ly.yaml_document_add_scalar(
                self.document,
                null, // No tag
                @ptrCast(buf),
                @intCast(buf.len),
                ly.YAML_PLAIN_SCALAR_STYLE,
            );
        },
        .object => |obj| blk: {
            const nodes = startTopSlice(YamlNode, self.document.nodes);
            const i = indexOfPtr(YamlNode, nodes, obj.node) orelse @panic("Object node not in document");
            break :blk @intCast(i + 1);
        },
        .array => @panic("TODO: Handle arrays"),
        .func => @panic("TODO: Dont allow funcs"),
    };

    const pair = self.getPair(key);
    if (pair) |p| {
        p.value = value_node_id;
    } else {
        const nodes = startTopSlice(YamlNode, self.document.nodes);

        const key_node_id = blk: {
            const duped = try allocator.dupe(u8, key);
            break :blk ly.yaml_document_add_scalar(
                self.document,
                null, // No tag
                @ptrCast(duped),
                @intCast(duped.len),
                ly.YAML_PLAIN_SCALAR_STYLE,
            );
        };

        const i: c_int = @intCast(indexOfPtr(YamlNode, nodes, self.node) orelse unreachable);
        const result = ly.yaml_document_append_mapping_pair(self.document, i + 1, key_node_id, value_node_id);
        if (result == 0) return error.LibyamlError;
    }
}

fn getPair(self: Object, key: []const u8) ?*YamlPair {
    std.debug.assert(self.node.type == ly.YAML_MAPPING_NODE);
    const nodes = startTopSlice(YamlNode, self.document.nodes);
    const pairs = startTopSlice(YamlPair, self.node.data.mapping.pairs);

    for (pairs) |*pair| {
        // I dont know why but whoever wrote libyaml decided to make these 1-based indexes
        const knode = &nodes[@intCast(pair.key - 1)];
        std.debug.assert(knode.type == ly.YAML_SCALAR_NODE);
        if (std.mem.eql(u8, valueLengthSlice(u8, knode.data.scalar), key)) {
            return pair;
        }
    }
    return null;
}

fn getNode(self: Object, key: []const u8) ?*YamlNode {
    std.debug.assert(self.node.type == ly.YAML_MAPPING_NODE);
    const target_pair = self.getPair(key) orelse return null;
    const nodes = startTopSlice(YamlNode, self.document.nodes);

    return &nodes[@intCast(target_pair.value - 1)];
}

fn indexOfPtr(comptime T: type, slice: []T, value: *T) ?usize {
    const start = @intFromPtr(slice.ptr);
    const target = @intFromPtr(value);
    if (target < start) return null;
    const index = (target - start) / @sizeOf(T);
    if (index >= slice.len) return null;
    return index;
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
