const std = @import("std");
const core = @import("core");

const log = std.log.scoped(.asset);

const yaml = core.yaml;
const GUID = core.runtime.GUID;
const Expr = core.Expr;
const Value = core.Expr.Value;
const Asset = @This();

file_id: u64,
guid: ?GUID, // If null, local to the ctx's file
type: ?u4,

const SearchError = Expr.eval.Error || error{ SearchError, InvalidAsset, AssetNotFound };
const FindError = Expr.eval.Error || error{ InvalidAsset, ObjectDefinitionNotFound, NullObjectDefinition };
pub const ObjError = SearchError || FindError;

pub fn obj(self: Asset, env: Expr.eval.Env) ObjError!Value.Object {
    const guid = self.guid orelse env.context.guid orelse @panic("context asset has no guid");
    const entry = env.objs.get(guid, self.file_id) orelse blk: {
        const path = env.assets.get(guid) orelse try search(guid, env);
        break :blk try findObjDef(path, guid, self.file_id, env);
    };

    return .{
        .node = entry.main,
        .doc = entry.doc,
    };
}

fn search(guid: GUID, env: Expr.eval.Env) SearchError![]const u8 {
    const nullable_path = env.assets.fetch(guid) catch return error.SearchError;
    const path = nullable_path orelse return error.AssetNotFound;
    log.info("Loaded asset {f} at '{s}'", .{ guid, path });
    return path;
}

fn findObjDef(path: []const u8, guid: GUID, file_id: u64, env: Expr.eval.Env) FindError!core.runtime.ObjMap.Entry {
    if (file_id == 0) return error.NullObjectDefinition;
    const file = std.fs.openFileAbsolute(path, .{ .mode = .read_only }) catch return error.InvalidAsset;
    defer file.close();

    var iterator = try core.runtime.ObjIterator.init(file, env.allocator);
    defer iterator.deinit();

    while (iterator.next() catch return error.InvalidAsset) |o| {
        if (o.info.file_id != file_id) continue;
        const doc = env.objs.new(guid, file_id, @enumFromInt(o.info.class_id)) catch |err| switch (err) {
            error.AlreadyExists => unreachable,
            else => |e| return e,
        };

        var yml = core.runtime.Yaml.init(.{ .string = o.content }, null, env.allocator);
        try yml.loadDocument(doc);
        log.info("Parsed obj instance {d} with class {d} in '{s}'", .{ o.info.file_id, o.info.class_id, path });
        return env.objs.get(guid, file_id) orelse unreachable;
    }
    return error.ObjectDefinitionNotFound;
}
