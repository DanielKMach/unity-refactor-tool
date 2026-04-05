//! A value resulting from expression evaluation.

const std = @import("std");
const core = @import("core");
const yaml = core.yaml;
const ly = yaml.ly;

pub const Value = union(enum) {
    pub const Type = @typeInfo(Value).@"union".tag_type orelse unreachable;
    pub const Object = @import("value/Object.zig");
    pub const List = @import("value/List.zig");
    pub const Func = @import("value/Func.zig");
    pub const Asset = @import("value/Asset.zig");

    pub const ToNodeError = std.mem.Allocator.Error || yaml.LibyamlError || error{UnrepresentableValue};

    nil,
    string: []const u8,
    number: f32,
    object: Object,
    array: List,
    func: Func,
    asset: Asset,

    /// Duplicates this value into the given allocator.
    ///
    /// Unnecessary but safe to call if the value is not a string.
    pub fn dupe(self: Value, allocator: std.mem.Allocator) std.mem.Allocator.Error!Value {
        return switch (self) {
            .string => |s| .{ .string = try allocator.dupe(u8, s) },
            else => self,
        };
    }

    /// Frees the value.
    ///
    /// This function is intended to be called when a value is duplicated using `dupe`.
    /// The given allocator must be the same as the one used to duplicate the value.
    ///
    /// Unnecessary but safe to call if the value is not a string.
    pub fn cleanup(self: Value, allocator: std.mem.Allocator) void {
        switch (self) {
            .string => |s| allocator.free(s),
            else => {},
        }
    }

    /// Returns whether this value is "truthy" in a boolean context.
    pub fn isTruthy(self: Value) bool {
        return switch (self) {
            .nil => false,
            .number => |n| n != 0.0,
            .string => |s| s.len != 0,
            .object => true,
            .array => true,
            .func => true,
            .asset => |a| a.file_id != 0,
        };
    }

    pub fn format(self: Value, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        return switch (self) {
            .nil => writer.writeAll("NIL"),
            .number => |n| writer.print("{d}", .{n}),
            .string => |s| writer.print("'{s}'", .{s}),
            .object => |o| writer.print("{f}", .{o}),
            .array => |a| writer.print("{f}", .{a}),
            .func => |f| writer.print("[func@{x}]", .{@intFromPtr(f.ptr)}),
            .asset => |a| {
                try writer.print("[asset {d}", .{a.file_id});
                if (a.guid) |g| try writer.print(":{f}", .{g});
                try writer.writeAll("]");
            },
        };
    }

    pub fn stringify(self: Value, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        return switch (self) {
            .nil => writer.writeAll("NIL"),
            .number => |n| writer.print("{d}", .{n}),
            .string => |s| writer.print("{s}", .{s}),
            .object => |o| writer.print("{f}", .{o}),
            .array => |a| writer.print("{f}", .{a}),
            .func => |f| writer.print("[func@{x}]", .{@intFromPtr(f.ptr)}),
            .asset => |a| {
                try writer.print("[asset {d}", .{a.file_id});
                if (a.guid) |g| try writer.print(":{f}", .{g});
                try writer.writeAll("]");
            },
        };
    }

    /// A value from a source expression for better traceability.
    pub const Derived = struct {
        src: *core.Expr,
        val: Value,
    };

    pub fn validate(value: Derived, expected: []const Type, diag: *core.RuntimeDiagnostics) core.RuntimeDiagnostics.Error!void {
        const valid = for (expected) |t| {
            if (value.val == t) break true;
        } else false;

        if (!valid) return diag.push(.{
            .unexpected_type = .{
                .found = value.val,
                .location = value.src.loc(),
                .expected = expected,
            },
        });
    }

    pub fn eql(a: Value, b: Value) bool {
        if (@as(Value.Type, a) != @as(Value.Type, b)) return false;
        return switch (a) {
            .number => |a_number| a_number == b.number,
            .string => |a_string| std.mem.eql(u8, a_string, b.string),
            .nil => true,
            .object => |a_object| a_object.node == b.object.node,
            .array => |a_array| a_array.node == b.array.node,
            .func => |a_func| a_func.ptr == b.func.ptr,
            .asset => |a_asset| a_asset.file_id == b.asset.file_id and (a_asset.guid == null and b.asset.guid == null or a_asset.guid != null and b.asset.guid != null and a_asset.guid.?.id == b.asset.guid.?.id),
        };
    }

    /// Constructs a Value from a YAML node.
    pub fn fromNode(node: *yaml.Node, doc: *yaml.Document) Value {
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
            ly.YAML_MAPPING_NODE => blk: {
                if (yaml.getNode(doc.*, node.*, "fileID")) |file_id_node| {
                    const file_id_str = yaml.fromBuffer(u8, file_id_node.data.scalar);
                    const file_id = std.fmt.parseInt(u64, file_id_str, 10) catch unreachable;
                    var guid: ?core.runtime.GUID = null;
                    var @"type": ?u4 = null;
                    if (yaml.getNode(doc.*, node.*, "guid")) |guid_node| {
                        const guid_str = yaml.fromBuffer(u8, guid_node.data.scalar);
                        guid = core.runtime.GUID.from(guid_str) catch unreachable;
                        const type_node = yaml.getNode(doc.*, node.*, "type") orelse unreachable;
                        const type_str = yaml.fromBuffer(u8, type_node.data.scalar);
                        @"type" = std.fmt.parseInt(u4, type_str, 10) catch unreachable;
                    }
                    break :blk .{ .asset = .{
                        .file_id = file_id,
                        .guid = guid,
                        .type = @"type",
                    } };
                } else {
                    break :blk .{ .object = .{
                        .node = node,
                        .doc = doc,
                    } };
                }
            },
            ly.YAML_SEQUENCE_NODE => .{ .array = .{
                .node = node,
                .doc = doc,
            } },
            else => unreachable,
        };
    }

    /// Converts this value into a YAML node in the given document.
    pub fn toNode(value: Value, doc: *yaml.Document) ToNodeError!*yaml.Node {
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
            .asset => |ass| blk: {
                const ref_node = ly.yaml_document_add_mapping(
                    doc,
                    null,
                    ly.YAML_FLOW_MAPPING_STYLE,
                );
                if (ref_node == 0) return error.LibyamlError;

                const file_id_knode = ly.yaml_document_add_scalar(
                    doc,
                    null,
                    "fileID",
                    6,
                    ly.YAML_PLAIN_SCALAR_STYLE,
                );
                if (file_id_knode == 0) return error.LibyamlError;

                const file_id_str = try std.fmt.allocPrint(allocator, "{d}", .{ass.file_id});
                errdefer allocator.free(file_id_str);
                const file_id_vnode = ly.yaml_document_add_scalar(
                    doc,
                    null,
                    file_id_str.ptr,
                    @intCast(file_id_str.len),
                    ly.YAML_PLAIN_SCALAR_STYLE,
                );
                if (file_id_vnode == 0) return error.LibyamlError;
                if (ly.yaml_document_append_mapping_pair(doc, ref_node, file_id_knode, file_id_vnode) == 0) return error.LibyamlError;

                if (ass.guid) |guid| {
                    const guid_knode = ly.yaml_document_add_scalar(
                        doc,
                        null,
                        "guid",
                        4,
                        ly.YAML_PLAIN_SCALAR_STYLE,
                    );
                    if (guid_knode == 0) return error.LibyamlError;

                    const guid_str = try std.fmt.allocPrint(allocator, "{f}", .{guid});
                    errdefer allocator.free(guid_str);
                    const guid_vnode = ly.yaml_document_add_scalar(
                        doc,
                        null,
                        guid_str.ptr,
                        32,
                        ly.YAML_PLAIN_SCALAR_STYLE,
                    );
                    if (guid_vnode == 0) return error.LibyamlError;
                    if (ly.yaml_document_append_mapping_pair(doc, ref_node, guid_knode, guid_vnode) == 0) return error.LibyamlError;

                    const type_knode = ly.yaml_document_add_scalar(
                        doc,
                        null,
                        "type",
                        4,
                        ly.YAML_PLAIN_SCALAR_STYLE,
                    );
                    if (type_knode == 0) return error.LibyamlError;

                    const type_str = switch (ass.type orelse unreachable) {
                        3 => "3",
                        2 => "2",
                        else => unreachable,
                    };
                    errdefer allocator.free(type_str);
                    const type_vnode = ly.yaml_document_add_scalar(
                        doc,
                        null,
                        type_str,
                        1,
                        ly.YAML_PLAIN_SCALAR_STYLE,
                    );
                    if (type_vnode == 0) return error.LibyamlError;
                    if (ly.yaml_document_append_mapping_pair(doc, ref_node, type_knode, type_vnode) == 0) return error.LibyamlError;
                }
                break :blk ref_node;
            },
            .func => return error.UnrepresentableValue,
        };
        if (id == 0) return error.LibyamlError;
        const nodes = yaml.fromStack(yaml.Node, doc.nodes);
        return &nodes[@intCast(id - 1)];
    }
};
