const std = @import("std");
const core = @import("core");
const tracy = @import("tracy");
const log = std.log.scoped(.rename_statement);

const This = @This();
const Stmt = core.Stmt;
const clse = core.Stmt.clse;
const TokenIterator = core.Token.Iterator;
const Scanner = core.runtime.Scanner;
const ObjIterator = core.runtime.ObjIterator;
const Yaml = core.runtime.Yaml;
const GUID = core.runtime.GUID;
const Token = core.Token;
const yaml = core.yaml;

old_name: Token,
new_name: Token,
of: clse.Of,
in: ?clse.In,

pub fn parse(tokens: *TokenIterator, env: Stmt.ParseEnv) Stmt.ParseError!This {
    const zone = tracy.Zone(@src());
    defer zone.End();

    if (!tokens.match(.RENAME)) return error.TokenMismatch;

    const old_name = try tokens.grabAny(&.{ .string, .literal }, env.diag);

    _ = try tokens.grab(.FOR, env.diag);

    const new_name = try tokens.grabAny(&.{ .string, .literal }, env.diag);

    const Clauses = struct {
        OF: clse.Of,
        IN: ?clse.In = null,
    };
    const clauses = try clse.parse(Clauses, tokens, env);

    return .{
        .old_name = old_name,
        .new_name = new_name,
        .of = clauses.OF,
        .in = clauses.IN,
    };
}

pub fn cleanup(self: This, allocator: std.mem.Allocator) void {
    self.of.cleanup(allocator);
}

pub fn run(self: This, env: Stmt.RunEnv) Stmt.RunError!void {
    const zone = tracy.Zone(@src());
    defer zone.End();

    const guids = try self.of.getGUID(.components_only, env);
    defer env.allocator.free(guids);

    const show = core.Stmt.Show{
        .mode = .indirect_uses,
        .of = self.of,
        .in = self.in,
        .where = null,
    };

    const targets = try show.search(null, env);
    defer env.allocator.free(targets);
    defer for (targets) |asset| env.allocator.free(asset);

    log.info("Updating...", .{});
    try self.updateAll(targets, guids, env);
}

pub fn updateAll(self: This, references: []const []const u8, guids: []const GUID, env: Stmt.RunEnv) !void {
    const zone = tracy.Zone(@src());
    defer zone.End();

    var objs: core.runtime.ObjMap = .init(env.allocator);
    defer objs.deinit();

    var assets: core.runtime.AssetMap = .init(env.allocator, env.proj);
    defer assets.deinit();

    for (references) |path| {
        try self.update(path, guids, &assets, &objs, env.allocator);
    }

    try Stmt.Evaluate.saveChanges(assets, objs, env);
}

pub fn update(
    self: This,
    asset: []const u8,
    guids: []const GUID,
    assetmap: *core.runtime.AssetMap,
    objmap: *core.runtime.ObjMap,
    allocator: std.mem.Allocator,
) !void {
    const asset_guid = try assetmap.put(asset);

    const file = try std.fs.openFileAbsolute(asset, .{ .mode = .read_write });
    defer file.close();

    var iterator = try ObjIterator.init(file, allocator);
    defer iterator.deinit();

    while (try iterator.next()) |e| {
        if (e.info.class_id != .MonoBehaviour and e.info.class_id != .PrefabInstance or e.info.stripped) continue;

        var yml = Yaml.init(.{ .string = e.content }, null, allocator);
        self.updateObj(
            &yml,
            e.info.file_id,
            e.info.class_id,
            asset_guid,
            guids,
            assetmap,
            objmap,
            allocator,
        ) catch |err| switch (err) {
            error.InvalidObject => |ee| {
                log.warn("Invalid obj instance structure {d} at '{s}'", .{ e.info.file_id, asset });
                return ee;
            },
            else => return err,
        };
    }
}

pub fn updateObj(
    self: This,
    yml: *core.runtime.Yaml,
    file_id: u64,
    class_id: core.runtime.ClassID,
    guid: GUID,
    guids: []const GUID,
    assetmap: *core.runtime.AssetMap,
    objmap: *core.runtime.ObjMap,
    allocator: std.mem.Allocator,
) !void {
    const c_alloc = std.heap.raw_c_allocator;

    switch (class_id) {
        .MonoBehaviour => {
            if (try Stmt.Show.matchGUID(guids, yml) == null) return;
            const entry = objmap.get(guid, file_id) orelse blk: {
                const doc = try objmap.new(guid, file_id, class_id);
                try yml.loadDocument(doc);
                break :blk objmap.get(guid, file_id) orelse unreachable;
            };
            const main = entry.main;
            const doc = entry.doc;
            const nodes = yaml.fromStack(yaml.Node, doc.nodes);
            const pair = yaml.getPair(doc.*, main.*, self.old_name.asSlice()) orelse return;
            const knode: *yaml.Node = &nodes[@intCast(pair.key - 1)];
            std.debug.assert(knode.type == yaml.ly.YAML_SCALAR_NODE);
            yaml.ly.free(knode.data.scalar.value);
            const new_name = try c_alloc.dupe(u8, self.new_name.asSlice());
            knode.data.scalar.value = new_name.ptr;
            knode.data.scalar.length = new_name.len;
        },
        .PrefabInstance => {
            const doc = try objmap.new(guid, file_id, class_id);
            try yml.loadDocument(doc);
            const main = (objmap.get(guid, file_id) orelse unreachable).main;
            const nodes = yaml.fromStack(yaml.Node, doc.nodes);

            // Grab the list of modifications and iterate through them
            const mod_node = yaml.getNode(doc.*, main.*, "m_Modification") orelse return error.InvalidObject;
            const mods_node = yaml.getNode(doc.*, mod_node.*, "m_Modifications") orelse return error.InvalidObject;
            const mods = yaml.fromStack(c_int, mods_node.data.sequence.items);
            for (mods) |m| {
                const mod = nodes[@intCast(m - 1)]; // one based indexing
                std.debug.assert(mod.type == yaml.ly.YAML_MAPPING_NODE);

                // Check if this modification is for the old property name
                const path_node = yaml.getNode(doc.*, mod, "propertyPath") orelse return error.InvalidObject;
                std.debug.assert(path_node.type == yaml.ly.YAML_SCALAR_NODE);
                const path = yaml.fromBuffer(u8, path_node.data.scalar);
                const dot_idx = std.mem.indexOf(u8, path, ".") orelse path.len;
                if (!std.mem.eql(u8, self.old_name.asSlice(), path[0..dot_idx])) continue;

                // Grab the reference info to check if it's one of the target GUIDs
                const reference_node = yaml.getNode(doc.*, mod, "target") orelse return error.InvalidObject;
                std.debug.assert(reference_node.type == yaml.ly.YAML_MAPPING_NODE);
                const file_id_node = yaml.getNode(doc.*, reference_node.*, "fileID") orelse return error.InvalidObject;
                const guid_node = yaml.getNode(doc.*, reference_node.*, "guid") orelse return error.InvalidObject;
                const target_file_id = try std.fmt.parseInt(u64, yaml.fromBuffer(u8, file_id_node.data.scalar), 10);
                const target_guid = try GUID.fromText(yaml.fromBuffer(u8, guid_node.data.scalar));

                // Check if the referenced object is one of the target GUIDs
                const asset_path = assetmap.get(target_guid) orelse try assetmap.fetch(target_guid) orelse {
                    log.warn("Failed to find asset for GUID '{f}' referenced by obj {d} at '{f}'", .{ target_guid, file_id, guid });
                    return error.TargetNotFound;
                };
                if (!try hasObjInstance(asset_path, target_file_id, guids, allocator)) continue;

                // Update the property name in the modification
                // Preserve prop access "old_name.Array.data[0]" -> "new_name.Array.data[0]"
                const new_name = self.new_name.asSlice();
                const new_name_buf = try c_alloc.alloc(u8, new_name.len + path.len - dot_idx);
                @memcpy(new_name_buf[0..new_name.len], new_name);
                @memcpy(new_name_buf[new_name.len..], path[dot_idx..]);
                yaml.ly.free(path_node.data.scalar.value);
                path_node.data.scalar.value = new_name_buf.ptr;
                path_node.data.scalar.length = new_name_buf.len;
            }
        },
        else => return,
    }
}

pub fn hasObjInstance(asset: []const u8, file_id: u64, guids: []const GUID, allocator: std.mem.Allocator) !bool {
    const file = try std.fs.openFileAbsolute(asset, .{ .mode = .read_only });
    defer file.close();

    var iterator = try ObjIterator.init(file, allocator);
    defer iterator.deinit();

    while (try iterator.next()) |e| {
        if (e.info.file_id != file_id or e.info.class_id != .MonoBehaviour) continue;
        std.debug.assert(!e.info.stripped);
        var yml = Yaml.init(.{ .string = e.content }, null, allocator);
        return try Stmt.Show.matchGUID(guids, &yml) != null;
    }
    return false;
}
