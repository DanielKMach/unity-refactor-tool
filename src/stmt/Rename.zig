const std = @import("std");
const core = @import("core");
const results = core.results;
const log = std.log.scoped(.rename_statement);

const This = @This();
const Tokenizer = core.language.Tokenizer;
const Scanner = core.runtime.Scanner;
const RuntimeEnv = core.runtime.RuntimeEnv;
const ComponentIterator = core.runtime.ComponentIterator;
const Yaml = core.runtime.Yaml;
const InTarget = core.stmt.clse.InTarget;
const AssetTarget = core.stmt.clse.AssetTarget;
const GUID = core.runtime.GUID;

const files = &.{ ".prefab", ".unity", ".asset" };

old_name: []const u8,
new_name: []const u8,
of: AssetTarget,
in: InTarget,

pub fn parse(tokens: *Tokenizer.TokenIterator) !results.ParseResult(This) {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.RENAME)) return .ERR(.unknown);

    var old_name: []const u8 = undefined;
    var new_name: []const u8 = undefined;
    var of: ?AssetTarget = null;
    var in: ?InTarget = null;

    switch (tokens.next().value) {
        .string => |str| old_name = str,
        .literal => |lit| old_name = lit,
        else => return .ERR(.{
            .unexpected_token = .{
                .found = tokens.peek(0),
                .expected = &.{ .literal, .string },
            },
        }),
    }

    if (!tokens.match(.FOR)) return .ERR(.{
        .unexpected_token = .{
            .found = tokens.peek(1),
            .expected = &.{.FOR},
        },
    });

    switch (tokens.next().value) {
        .string => |str| new_name = str,
        .literal => |lit| new_name = lit,
        else => return .ERR(.{
            .unexpected_token = .{
                .found = tokens.peek(0),
                .expected = &.{ .literal, .string },
            },
        }),
    }

    clses: switch (tokens.peek(1).value) {
        .OF => {
            if (of != null) continue :clses .RENAME;
            of = switch (try AssetTarget.parse(tokens)) {
                .ok => |v| v,
                .err => |err| return .ERR(err),
            };
            continue :clses tokens.peek(1).value;
        },
        .IN => {
            if (in != null) continue :clses .RENAME;
            in = switch (try InTarget.parse(tokens)) {
                .ok => |v| v,
                .err => |err| return .ERR(err),
            };
            continue :clses tokens.peek(1).value;
        },
        .eos => break :clses,
        else => return .ERR(.{
            .unexpected_token = .{
                .found = tokens.next(),
                .expected = &.{.eos},
            },
        }),
    }

    if (of == null) return .ERR(.{
        .unexpected_token = .{
            .found = tokens.next(),
            .expected = &.{.OF},
        },
    });

    return .OK(.{
        .old_name = old_name,
        .new_name = new_name,
        .of = of.?,
        .in = in orelse InTarget.default,
    });
}

pub fn run(self: This, env: RuntimeEnv) !results.RuntimeResult(void) {
    core.profiling.begin(run);
    defer core.profiling.stop();

    const in = self.in;
    const of = self.of;

    var dir = in.openDir(env, .{ .iterate = true, .access_sub_paths = true }) catch {
        return .ERR(.{
            .invalid_path = .{ .path = in.dir },
        });
    };
    defer dir.close();

    const guids = switch (try of.getGUID(env.cwd, env.allocator)) {
        .ok => |v| v,
        .err => |err| return .ERR(err),
    };
    defer {
        for (guids) |g| g.deinit(env.allocator);
        env.allocator.free(guids);
    }

    const show = core.stmt.Show{
        .mode = .indirect_uses,
        .of = of,
        .in = in,
    };

    const target_assets = switch (try show.search(env, null, null)) {
        .ok => |r| r,
        .err => |err| return .ERR(err),
    };

    defer {
        for (target_assets) |asset| {
            env.allocator.free(asset);
        }
        env.allocator.free(target_assets);
    }

    try self.updateAll(target_assets, guids, env);
    return .OK(void{});
}

pub fn updateAll(self: This, asset_paths: []const []const u8, guids: []const GUID, env: RuntimeEnv) !void {
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
        try file.writeFileAll(temp, .{});

        try env.out.print(" DONE.\r\n", .{});
    }
}

pub fn findAndReplace(self: This, asset: std.fs.File, out: std.fs.File, guids: []const GUID, allocator: std.mem.Allocator) !bool {
    core.profiling.begin(findAndReplace);
    defer core.profiling.stop();

    var iterator = ComponentIterator.init(asset, allocator);
    defer iterator.deinit();

    const changes = try self.computeChanges(&iterator, guids, allocator);
    defer allocator.free(changes);
    defer for (changes) |c| allocator.free(c.document);

    if (changes.len != 0) {
        try iterator.patch(out, changes);
    }

    return changes.len != 0;
}

pub fn computeChanges(self: This, iterator: *ComponentIterator, guid: []const GUID, allocator: std.mem.Allocator) ![]ComponentIterator.Component {
    core.profiling.begin(computeChanges);
    defer core.profiling.stop();

    var modified = std.ArrayList(ComponentIterator.Component).init(allocator);
    defer modified.deinit();

    while (try iterator.next()) |comp| {
        var yaml = Yaml.init(.{ .string = comp.document }, null, allocator);

        if (!(core.stmt.Show.matchScriptOrPrefabGUID(guid, &yaml) catch false)) continue;

        var buf = try allocator.alloc(u8, comp.len * 2);
        errdefer allocator.free(buf);
        yaml.out = .{ .string = &buf };
        try yaml.rename(self.old_name, self.new_name);

        try modified.append(.{
            .index = comp.index,
            .len = comp.len,
            .document = buf,
        });
    }

    return try modified.toOwnedSlice();
}
