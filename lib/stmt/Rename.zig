const std = @import("std");
const core = @import("core");
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

old_name: Token,
new_name: Token,
of: clse.Of,
in: ?clse.In,

pub fn parse(tokens: *TokenIterator, env: Stmt.ParseEnv) Stmt.ParseError!This {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.RENAME)) return error.TokenMismatch;

    const old_name = try (try tokens.grabAny(&.{ .string, .literal }, env.diag)).dupe(env.allocator);
    errdefer old_name.cleanup(env.allocator);

    _ = try tokens.grab(.FOR, env.diag);

    const new_name = try (try tokens.grabAny(&.{ .string, .literal }, env.diag)).dupe(env.allocator);
    errdefer new_name.cleanup(env.allocator);

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
    if (self.in) |in| in.cleanup(allocator);
    self.old_name.cleanup(allocator);
    self.new_name.cleanup(allocator);
}

pub fn run(self: This, env: Stmt.RunEnv) Stmt.RunError!void {
    core.profiling.begin(run);
    defer core.profiling.stop();

    const guids = try self.of.getGUID(env);
    defer env.allocator.free(guids);

    const show = core.Stmt.Show{
        .mode = .indirect_uses,
        .of = self.of,
        .in = self.in,
    };

    const targets = try show.search(null, null, env);
    defer env.allocator.free(targets);
    defer for (targets) |asset| env.allocator.free(asset);

    try self.updateAll(targets, guids, env);
}

pub fn updateAll(self: This, asset_paths: []const []const u8, guids: []const GUID, env: Stmt.RunEnv) !void {
    core.profiling.begin(updateAll);
    defer core.profiling.stop();

    for (asset_paths) |path| {
        try env.transaction.include(path);

        try env.out.print("Updating '{s}'...", .{std.fs.path.basename(path)});

        var file = try std.fs.openFileAbsolute(path, .{ .mode = .read_write });
        defer file.close();

        const temp = try env.transaction.getTemp();
        defer env.transaction.delTemp(temp);

        if (!try self.findAndReplace(file, temp, guids, env.allocator)) {
            try env.out.print(" UNCHANGED.\r\n", .{});
            continue;
        }
        file.close();

        file = try std.fs.createFileAbsolute(path, .{ .truncate = true });

        var wbuf: [4096]u8 = undefined;
        var writer = file.writer(&wbuf);
        var rbuf: [4096]u8 = undefined;
        var reader = temp.reader(&rbuf);

        _ = try reader.interface.streamRemaining(&writer.interface);
        try writer.interface.flush();
        try env.out.print(" DONE.\r\n", .{});
    }
}

pub fn findAndReplace(self: This, asset: std.fs.File, out: std.fs.File, guids: []const GUID, allocator: std.mem.Allocator) !bool {
    core.profiling.begin(findAndReplace);
    defer core.profiling.stop();

    var iterator = try ObjIterator.init(asset, allocator);
    defer iterator.deinit();

    const changes = try self.computeChanges(&iterator, guids, allocator);
    defer allocator.free(changes);
    defer for (changes) |c| allocator.free(c.content);

    var buf: [4096]u8 = undefined;
    var fwriter = out.writer(&buf);

    if (changes.len != 0) {
        try iterator.patch(&fwriter.interface, changes);
    }

    return changes.len != 0;
}

pub fn computeChanges(self: This, iterator: *ObjIterator, guid: []const GUID, allocator: std.mem.Allocator) ![]ObjIterator.Entry {
    core.profiling.begin(computeChanges);
    defer core.profiling.stop();

    var modified = try std.ArrayList(ObjIterator.Entry).initCapacity(allocator, 1);
    defer modified.deinit(allocator);

    while (try iterator.next()) |e| {
        var yaml = Yaml.init(.{ .string = e.content }, null, allocator);

        if (!(core.Stmt.Show.matchScriptOrPrefabGUID(guid, &yaml) catch false)) continue;

        var buf = try allocator.alloc(u8, e.content.len * 2);
        defer allocator.free(buf);
        var out = buf[0..];

        yaml.out = .{ .string = &out };
        try yaml.rename(self.old_name.asSlice(), self.new_name.asSlice());

        const doc = try allocator.dupe(u8, out);
        errdefer allocator.free(doc);

        try modified.append(allocator, .{
            .info = e.info,
            .content = doc,
        });
    }

    return try modified.toOwnedSlice(allocator);
}
