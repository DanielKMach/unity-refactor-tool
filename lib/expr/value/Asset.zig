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

pub fn obj(self: Asset, env: Expr.EvalEnv) Expr.eval.Error!Value.Object {
    const guid = self.guid orelse env.context.guid orelse @panic("context asset has no guid");
    const entry = env.objs.get(guid, self.file_id) orelse blk: {
        const path = env.assets.get(guid) orelse blk2: {
            const path = env.assets.fetch(guid, env.allocator) catch @panic("TODO: unable to find asset file") orelse unreachable;
            log.info("Loaded asset {f} at '{s}'", .{ guid, path });
            break :blk2 path;
        };

        const file = std.fs.openFileAbsolute(path, .{ .mode = .read_only }) catch @panic("TODO: unable to open asset file");
        defer file.close();

        var iterator = try core.runtime.ComponentIterator.init(file, env.allocator);
        defer iterator.deinit();

        while (iterator.next() catch unreachable) |e| {
            if (e.info.file_id != self.file_id) continue;
            const doc = env.objs.new(guid, self.file_id, e.info.class_id) catch |err| switch (err) {
                error.AlreadyExists => unreachable,
                else => |errr| return errr,
            };

            var yml = core.runtime.Yaml.init(.{ .string = e.content }, null, env.allocator);
            try yml.loadDocument(doc);
            log.info("Parsed obj instance {d} with class {d} at '{s}'", .{ e.info.file_id, e.info.class_id, path });
            break :blk env.objs.get(guid, self.file_id) orelse unreachable;
        }
        @panic("TODO: Runtime error unable to find obj definition within asset file");
    };

    return .{
        .node = entry.main,
        .doc = entry.doc,
    };
}

// fn find(guid: GUID, allocator: std.mem.Allocator) !?[]const u8 {
// }
