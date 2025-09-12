const std = @import("std");
const core = @import("core");
const log = std.log.scoped(.rename_statement);

const This = @This();
const Tokenizer = core.parsing.Tokenizer;
const Scanner = core.runtime.Scanner;
const ComponentIterator = core.runtime.ComponentIterator;
const Yaml = core.runtime.Yaml;
const InTarget = core.Stmt.clse.InTarget;
const AssetTarget = core.Stmt.clse.AssetTarget;
const GUID = core.runtime.GUID;

const files = &.{ ".prefab", ".unity", ".asset" };

old_name: []const u8,
new_name: []const u8,
of: AssetTarget,
in: ?InTarget,

pub fn parse(tokens: *Tokenizer.TokenIterator, env: core.Stmt.ParsingEnv) core.Stmt.ParseError!This {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.RENAME)) return error.TokenMismatch;

    var old_name: []const u8 = undefined;
    var new_name: []const u8 = undefined;

    switch (tokens.next().value) {
        .string => |str| old_name = try env.allocator.dupe(u8, str),
        .literal => |lit| old_name = try env.allocator.dupe(u8, lit),
        else => return env.err(.{ .unexpected_token = .{
            .found = tokens.peek(0),
            .expected = &.{ .literal, .string },
        } }),
    }
    errdefer env.allocator.free(old_name);

    if (!tokens.match(.FOR)) return env.err(.{ .unexpected_token = .{
        .found = tokens.peek(1),
        .expected = &.{.FOR},
    } });

    switch (tokens.next().value) {
        .string => |str| new_name = try env.allocator.dupe(u8, str),
        .literal => |lit| new_name = try env.allocator.dupe(u8, lit),
        else => return env.err(.{ .unexpected_token = .{
            .found = tokens.peek(0),
            .expected = &.{ .literal, .string },
        } }),
    }
    errdefer env.allocator.free(new_name);

    const Clauses = struct {
        OF: AssetTarget,
        IN: ?InTarget = null,
    };
    const clauses = try core.Stmt.clse.parse(Clauses, tokens, env);

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
    allocator.free(self.old_name);
    allocator.free(self.new_name);
}

pub fn run(self: This, env: core.Stmt.RuntimeEnv) core.Stmt.RuntimeError!void {
    core.profiling.begin(run);
    defer core.profiling.stop();

    const in = self.in orelse InTarget.default;
    const of = self.of;

    var dir = try in.openDir(env, .{ .iterate = true, .access_sub_paths = true });
    defer dir.close();

    const guids = try of.getGUID(env);
    defer env.allocator.free(guids);
    defer for (guids) |g| g.deinit(env.allocator);

    const show = core.Stmt.Show{
        .mode = .indirect_uses,
        .of = of,
        .in = in,
    };

    const targets = try show.search(null, null, env);
    defer env.allocator.free(targets);
    defer for (targets) |asset| env.allocator.free(asset);

    try self.updateAll(targets, guids, env);
}

pub fn updateAll(self: This, asset_paths: []const []const u8, guids: []const GUID, env: core.Stmt.RuntimeEnv) !void {
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

    var iterator = try ComponentIterator.init(asset, allocator);
    defer iterator.deinit();

    const changes = try self.computeChanges(&iterator, guids, allocator);
    defer allocator.free(changes);
    defer for (changes) |c| allocator.free(c.document);

    var buf: [4096]u8 = undefined;
    var fwriter = out.writer(&buf);

    if (changes.len != 0) {
        try iterator.patch(&fwriter.interface, changes);
    }

    return changes.len != 0;
}

pub fn computeChanges(self: This, iterator: *ComponentIterator, guid: []const GUID, allocator: std.mem.Allocator) ![]ComponentIterator.Component {
    core.profiling.begin(computeChanges);
    defer core.profiling.stop();

    var modified = try std.ArrayList(ComponentIterator.Component).initCapacity(allocator, 1);
    defer modified.deinit(allocator);

    while (try iterator.next()) |comp| {
        var yaml = Yaml.init(.{ .string = comp.document }, null, allocator);

        if (!(core.Stmt.Show.matchScriptOrPrefabGUID(guid, &yaml) catch false)) continue;

        var buf = try allocator.alloc(u8, comp.len * 2);
        defer allocator.free(buf);
        var out = buf[0..];

        yaml.out = .{ .string = &out };
        try yaml.rename(self.old_name, self.new_name);

        const doc = try allocator.dupe(u8, out);
        errdefer allocator.free(doc);

        try modified.append(allocator, .{
            .index = comp.index,
            .len = comp.len,
            .document = doc,
        });
    }

    return try modified.toOwnedSlice(allocator);
}
