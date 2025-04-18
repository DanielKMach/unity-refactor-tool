const std = @import("std");
const core = @import("root");
const results = core.results;
const log = std.log.scoped(.rename_command);

const This = @This();
const Tokenizer = core.language.Tokenizer;
const Scanner = core.runtime.Scanner;
const RuntimeData = core.runtime.RuntimeData;
const ComponentIterator = core.runtime.ComponentIterator;
const Yaml = core.runtime.Yaml;
const InTarget = core.cmds.sub.InTarget;
const AssetTarget = core.cmds.sub.AssetTarget;

const files = &.{ ".prefab", ".unity", ".asset" };

old_name: []const u8,
new_name: []const u8,
of: AssetTarget,
in: InTarget,

pub fn parse(tokens: *Tokenizer.TokenIterator) !results.ParseResult(This) {
    if (tokens.next()) |tkn| {
        if (!tkn.is(.keyword, "RENAME")) {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected_type = .keyword,
                    .expected_value = "RENAME",
                },
            });
        }
    } else {
        return .ERR(.{
            .unexpected_eof = .{
                .expected_type = .keyword,
                .expected_value = "RENAME",
            },
        });
    }

    var old_name: []const u8 = undefined;
    var new_name: []const u8 = undefined;
    var of: ?AssetTarget = null;
    var in: ?InTarget = null;

    if (tokens.next()) |tkn| {
        if (tkn.isType(.literal) or tkn.isType(.literal_string)) {
            old_name = tkn.value;
        } else {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected_type = .literal_string,
                },
            });
        }
    } else {
        return .ERR(.{
            .unexpected_eof = .{
                .expected_type = .literal_string,
            },
        });
    }

    if (tokens.next()) |tkn| {
        if (!tkn.is(.keyword, "FOR")) {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected_type = .keyword,
                    .expected_value = "FOR",
                },
            });
        }
    } else {
        return .ERR(.{
            .unexpected_eof = .{
                .expected_type = .keyword,
                .expected_value = "FOR",
            },
        });
    }

    if (tokens.next()) |tkn| {
        if (tkn.isType(.literal) or tkn.isType(.literal_string)) {
            new_name = tkn.value;
        } else {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected_type = .literal_string,
                },
            });
        }
    } else {
        return .ERR(.{
            .unexpected_eof = .{
                .expected_type = .literal_string,
            },
        });
    }

    while (tokens.peek(1)) |tkn| {
        if (of == null and tkn.is(.keyword, "OF")) {
            const res = try AssetTarget.parse(tokens);
            if (res.isErr()) |err| return .ERR(err);
            of = res.ok;
        } else if (in == null and tkn.is(.keyword, "IN")) {
            const res = try InTarget.parse(tokens);
            if (res.isErr()) |err| return .ERR(err);
            in = res.ok;
        } else {
            break;
        }
    }

    if (of == null)
        return .ERR(.{
            .unexpected_eof = .{
                .expected_type = .keyword,
                .expected_value = "OF",
            },
        });

    return .OK(.{
        .old_name = old_name,
        .new_name = new_name,
        .of = of.?,
        .in = in orelse InTarget.default,
    });
}

pub fn run(self: This, data: RuntimeData) !results.RuntimeResult(void) {
    const in = self.in;
    const of = self.of;

    var dir = in.openDir(data, .{ .iterate = true, .access_sub_paths = true }) catch {
        return .ERR(.{
            .invalid_path = .{ .path = in.dir },
        });
    };
    defer dir.close();

    const guid = switch (try of.getGUID(data.allocator, data.cwd)) {
        .ok => |v| v,
        .err => |err| return .ERR(err),
    };
    defer data.allocator.free(guid);

    var show_output = std.ArrayList(u8).init(data.allocator);
    defer show_output.deinit();
    const writer = show_output.writer();

    const show = core.cmds.Show{
        .exts = &.{ ".unity", ".prefab", ".asset" },
        .of = of,
        .in = in,
    };

    const rundata = RuntimeData{
        .allocator = data.allocator,
        .out = writer.any(),
        .cwd = data.cwd,
        .query = data.query,
        .verbose = false,
    };

    // Using SHOW command to search for references
    var res = try show.run(rundata);
    if (res.isErr()) |e| {
        return .ERR(e);
    }

    // Parsing files and storing the changes
    var paths = std.mem.SplitIterator(u8, .scalar){
        .buffer = show_output.items,
        .index = 0,
        .delimiter = '\n',
    };

    const updated = try self.updateAll(&paths, data, guid);
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

pub fn updateAll(self: This, paths: *std.mem.SplitIterator(u8, .scalar), data: RuntimeData, guid: []const []const u8) ![]Mod {
    var updated = std.ArrayList(Mod).init(data.allocator);
    defer updated.deinit();

    while (paths.next()) |p| {
        const trimmed_name = std.mem.trim(u8, p, " \t\r\n");
        if (trimmed_name.len == 0) continue;

        const path = std.fs.path.join(data.allocator, &.{ self.in.dir, trimmed_name }) catch |err| {
            log.warn("Error joining path: '{s}'", .{@errorName(err)});
            continue;
        };

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

pub fn scopeAndReplace(self: This, data: RuntimeData, file: std.fs.File, path: []const u8, guid: []const []const u8) !?Mod {
    var iterator = ComponentIterator.init(file, data.allocator);
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

        for (guid) |g| {
            if (try yaml.matchGUID(g)) {
                break;
            }
        } else {
            continue;
        }

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
