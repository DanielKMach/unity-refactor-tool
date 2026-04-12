//! A map of loaded object definitions and their associated guid, file id and yaml document.

const std = @import("std");
const core = @import("core");
const yaml = core.yaml;
const GUID = core.runtime.GUID;
const ClassID = core.runtime.ClassID;
const FileID = core.runtime.FileID;

const ObjMap = @This();

pub const Ref = struct {
    guid: GUID,
    file_id: FileID,
};

pub const ObjDef = struct {
    class_id: ClassID,
    doc: yaml.Document,
};

pub const Entry = struct {
    doc: *yaml.Document,
    root: *yaml.Node,
    main: *yaml.Node,
};

allocator: std.mem.Allocator,
objs: std.AutoHashMap(Ref, ObjDef),

pub fn init(allocator: std.mem.Allocator) ObjMap {
    return ObjMap{
        .allocator = allocator,
        .objs = .init(allocator),
    };
}

pub fn new(self: *ObjMap, guid: GUID, file_id: FileID, class_id: ClassID) !*yaml.Document {
    const key: Ref = .{ .guid = guid, .file_id = file_id };
    const result = try self.objs.getOrPut(key);
    if (result.found_existing) return error.AlreadyExists;
    result.value_ptr.* = .{ .class_id = class_id, .doc = undefined };
    return &result.value_ptr.doc;
}

pub fn get(self: *const ObjMap, guid: GUID, file_id: FileID) ?Entry {
    const key: Ref = .{ .guid = guid, .file_id = file_id };
    const def = self.objs.getPtr(key) orelse return null;
    return .{
        .doc = &def.doc,
        .root = def.doc.nodes.start,
        .main = yaml.getNode(def.doc, def.doc.nodes.start.*, @tagName(def.class_id)) orelse @panic("invalid main node"),
    };
}

pub fn deinit(self: *ObjMap) void {
    var it = self.objs.iterator();
    while (it.next()) |entry| {
        yaml.ly.yaml_document_delete(&entry.value_ptr.doc);
    }
    self.objs.deinit();
}

test new {
    const doc =
        \\GameObject:
        \\  foo: bar
    ;

    var yml = core.runtime.Yaml.init(.{ .string = doc }, null, std.testing.allocator);
    var map = init(std.testing.allocator);
    defer map.deinit();

    try yml.loadDocument(try map.new(.zero, 1, .GameObject));
    try std.testing.expectError(error.AlreadyExists, map.new(.zero, 1, .GameObject));
    try std.testing.expectError(error.AlreadyExists, map.new(.zero, 1, .MonoBehaviour));
    try std.testing.expectError(error.AlreadyExists, map.new(.zero, 1, .PrefabInstance));

    try yml.loadDocument(try map.new(.zero, 2, .GameObject));
    try yml.loadDocument(try map.new(.one, 1, .GameObject));
    try yml.loadDocument(try map.new(.one, 2, .GameObject));
    try std.testing.expectError(error.AlreadyExists, map.new(.zero, 2, .GameObject));
    try std.testing.expectError(error.AlreadyExists, map.new(.one, 1, .GameObject));
    try std.testing.expectError(error.AlreadyExists, map.new(.one, 2, .GameObject));
}

test get {
    const doc =
        \\GameObject:
        \\  foo: bar
    ;

    var yml = core.runtime.Yaml.init(.{ .string = doc }, null, std.testing.allocator);
    var map = init(std.testing.allocator);
    defer map.deinit();

    try std.testing.expectEqual(null, map.get(.zero, 1));

    const ptr = try map.new(.zero, 1, .GameObject);
    try yml.loadDocument(ptr);

    const entry = map.get(.zero, 1).?;
    try std.testing.expectEqual(ptr, entry.doc);
    try std.testing.expectEqual(ptr.nodes.start, entry.root);
    try std.testing.expectEqual(yaml.getNode(ptr.*, ptr.nodes.start.*, "GameObject").?, entry.main);
}
