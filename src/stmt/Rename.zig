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

pub fn run(self: This, data: RuntimeEnv) !results.RuntimeResult(void) {
    core.profiling.begin(run);
    defer core.profiling.stop();

    const in = self.in;
    const of = self.of;

    var dir = in.openDir(data, .{ .iterate = true, .access_sub_paths = true }) catch {
        return .ERR(.{
            .invalid_path = .{ .path = in.dir },
        });
    };
    defer dir.close();

    const guid = switch (try of.getGUID(data.cwd, data.allocator)) {
        .ok => |v| v,
        .err => |err| return .ERR(err),
    };
    defer {
        for (guid) |g| g.deinit(data.allocator);
        data.allocator.free(guid);
    }

    const show = core.stmt.Show{
        .mode = .indirect_uses,
        .of = of,
        .in = in,
    };

    const search_result = try show.search(data, null, null);
    if (search_result.isErr()) |err| {
        return .ERR(err);
    }
    const target_assets = search_result.ok;
    defer {
        for (target_assets) |asset| {
            data.allocator.free(asset);
        }
        data.allocator.free(target_assets);
    }

    // Parsing files and storing the changes
    const updated = try self.updateAll(target_assets, data, guid);
    defer {
        for (updated) |mod| {
            mod.modifications.close();
            data.cwd.deleteFile(&mod.cache_path) catch {};
        }
        data.allocator.free(updated);
    }

    // Apply changes
    try applyAll(updated, data.cwd);

    return .OK(void{});
}

pub fn updateAll(self: This, asset_paths: []const []const u8, data: RuntimeEnv, guid: []const GUID) ![]Mod {
    core.profiling.begin(updateAll);
    defer core.profiling.stop();

    var updated = std.ArrayList(Mod).init(data.allocator);
    defer updated.deinit();

    for (asset_paths) |path| {
        const file = data.cwd.openFile(path, .{ .mode = .read_only }) catch |err| {
            log.warn("Error ({s}) opening file: '{s}'", .{ @errorName(err), path });
            continue;
        };
        defer file.close();

        const mod = try self.scopeAndReplace(data, file, path, guid) orelse continue;
        try updated.append(mod);
    }

    return try updated.toOwnedSlice();
}

pub fn scopeAndReplace(self: This, data: RuntimeEnv, file: std.fs.File, path: []const u8, guid: []const GUID) !?Mod {
    core.profiling.begin(scopeAndReplace);
    defer core.profiling.stop();

    var iterator = ComponentIterator.init(file, data.allocator);
    defer iterator.deinit();
    var modified = std.ArrayList(ComponentIterator.Component).init(data.allocator);
    defer {
        for (modified.items) |comp| {
            data.allocator.free(comp.document);
        }
        modified.deinit();
    }

    try data.out.print("Updating '{s}'...", .{std.fs.path.basename(path)});

    while (try iterator.next()) |comp| {
        var yaml = Yaml.init(.{ .string = comp.document }, null, data.allocator);

        if (!(core.stmt.Show.matchScriptOrPrefabGUID(guid, &yaml) catch false)) continue;

        var buf = try data.allocator.alloc(u8, comp.len * 2);
        yaml.out = .{ .string = &buf };
        try yaml.rename(self.old_name, self.new_name);

        try modified.append(.{
            .index = comp.index,
            .len = comp.len,
            .document = buf,
        });
    }

    if (modified.items.len == 0) {
        try data.out.print(" UNCHANGED.\r\n", .{});
        return null;
    } else {
        try data.out.print(" DONE.\r\n", .{});
    }

    const mod = try Mod.new(path, data.cwd);
    try iterator.patch(mod.modifications, modified.items);

    return mod;
}

pub fn applyAll(mods: []Mod, cwd: std.fs.Dir) !void {
    core.profiling.begin(applyAll);
    defer core.profiling.stop();

    for (mods) |mod| {
        const path = mod.path;
        const cache = mod.modifications;

        const file = try cwd.createFile(path, .{ .lock = .exclusive, .truncate = true });
        defer file.close();

        try file.writeFileAll(cache, .{});
    }
}

const Mod = struct {
    path: []const u8,
    cache_path: [8]u8,
    modifications: std.fs.File,

    pub fn new(path: []const u8, cwd: std.fs.Dir) !Mod {
        var name: [8]u8 = undefined;
        const hash = std.hash.Adler32.hash(path);
        _ = try std.fmt.bufPrint(&name, "{x:0>8}", .{hash});
        const cache_file = try cwd.createFile(&name, .{ .lock = .exclusive, .truncate = true, .read = true });

        return Mod{
            .path = path,
            .cache_path = name,
            .modifications = cache_file,
        };
    }

    pub fn close(self: *Mod) void {
        self.modifications.close();
    }
};
