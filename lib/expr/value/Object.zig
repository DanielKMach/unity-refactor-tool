const std = @import("std");
const core = @import("core");

const log = std.log.scoped(.expr_object);

const Object = @This();
const Value = core.Expr.Value;
const yaml = core.yaml;
const ly = yaml.ly;

const SetError = std.mem.Allocator.Error || yaml.LibyamlError;

node: *yaml.Node,
doc: *yaml.Document,

pub fn get(self: Object, key: []const u8) ?Value {
    const node = yaml.getNode(self.doc.*, self.node.*, key) orelse return null;
    return valueFromNode(self.doc, node);
}

pub fn set(self: Object, key: []const u8, value: Value) SetError!void {
    const nodes = yaml.fromStack(yaml.Node, self.doc.nodes);

    const vnode = try nodeFromValue(self.doc, value);
    const vnode_id: c_int = @intCast(vnode - nodes.ptr + 1);

    const pair = yaml.getPair(self.doc.*, self.node.*, key);
    if (pair) |p| {
        p.value = vnode_id;
    } else {
        const knode_id = blk: {
            const duped = try std.heap.c_allocator.dupe(u8, key);
            break :blk ly.yaml_document_add_scalar(
                self.doc,
                null, // No tag
                @ptrCast(duped),
                @intCast(duped.len),
                ly.YAML_PLAIN_SCALAR_STYLE,
            );
        };

        const i: c_int = @intCast(self.node - nodes.ptr);
        if (ly.yaml_document_append_mapping_pair(self.doc, i + 1, knode_id, vnode_id) == 0) {
            return error.LibyamlError;
        }
    }
}

pub fn valueFromNode(doc: *yaml.Document, node: *yaml.Node) Value {
    return switch (node.type) {
        ly.YAML_SCALAR_NODE => blk: {
            const scalar = node.data.scalar;
            const buf = yaml.fromBuffer(u8, scalar);

            switch (scalar.style) {
                ly.YAML_SINGLE_QUOTED_SCALAR_STYLE, ly.YAML_DOUBLE_QUOTED_SCALAR_STYLE => {
                    break :blk .{ .string = buf };
                },
                else => {
                    if (buf.len == 0) return .nil;
                    if (std.fmt.parseFloat(f32, buf)) |num| {
                        break :blk .{ .number = num };
                    } else |_| {
                        break :blk .{ .string = buf };
                    }
                },
            }
        },
        ly.YAML_MAPPING_NODE => .{ .object = .{
            .node = node,
            .doc = doc,
        } },
        ly.YAML_SEQUENCE_NODE => .{ .array = .{
            .node = node,
            .doc = doc,
        } },
        else => unreachable,
    };
}

pub fn nodeFromValue(doc: *yaml.Document, value: Value) std.mem.Allocator.Error!*yaml.Node {
    const allocator = std.heap.c_allocator;
    const id: c_int = switch (value) {
        .string => |str| blk: {
            const buf = try allocator.dupe(u8, str);
            break :blk ly.yaml_document_add_scalar(
                doc,
                null, // No tag
                @ptrCast(buf),
                @intCast(buf.len),
                ly.YAML_DOUBLE_QUOTED_SCALAR_STYLE,
            );
        },
        .number => |num| blk: {
            const buf = try std.fmt.allocPrint(allocator, "{d}", .{num});
            break :blk ly.yaml_document_add_scalar(
                doc,
                null, // No tag
                @ptrCast(buf),
                @intCast(buf.len),
                ly.YAML_PLAIN_SCALAR_STYLE,
            );
        },
        .nil => blk: {
            const buf = try allocator.alloc(u8, 0);
            break :blk ly.yaml_document_add_scalar(
                doc,
                null, // No tag
                @ptrCast(buf),
                @intCast(buf.len),
                ly.YAML_PLAIN_SCALAR_STYLE,
            );
        },
        .object => |obj| blk: {
            const nodes = yaml.fromStack(yaml.Node, doc.nodes);
            const i = obj.node - nodes.ptr;
            std.debug.assert(i < nodes.len);
            break :blk @intCast(i + 1);
        },
        .array => |arr| blk: {
            const nodes = yaml.fromStack(yaml.Node, doc.nodes);
            const i = arr.node - nodes.ptr;
            std.debug.assert(i < nodes.len);
            break :blk @intCast(i + 1);
        },
        .func => @panic("TODO: Dont allow funcs"),
    };
    const nodes = yaml.fromStack(yaml.Node, doc.nodes);
    return &nodes[@intCast(id - 1)];
}
