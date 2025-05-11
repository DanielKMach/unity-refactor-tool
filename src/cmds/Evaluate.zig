const std = @import("std");
const core = @import("root");
const results = core.results;
const log = std.log.scoped(.evaluate_command);

const This = @This();
const Tokenizer = core.language.Tokenizer;
const Scanner = core.runtime.Scanner;
const RuntimeData = core.runtime.RuntimeData;
const ComponentIterator = core.runtime.ComponentIterator;
const Yaml = core.runtime.Yaml;
const InTarget = core.cmds.sub.InTarget;
const AssetTarget = core.cmds.sub.AssetTarget;

const files = &.{ ".prefab", ".unity", ".asset" };

path: std.BoundedArray([]const u8, 8),
of: AssetTarget,
in: InTarget,

pub fn parse(tokens: *Tokenizer.TokenIterator) !results.ParseResult(This) {
    if (tokens.next()) |tkn| {
        if (!tkn.is(.keyword, "EVALUATE")) {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected_type = .keyword,
                    .expected_value = "EVALUATE",
                },
            });
        }
    } else {
        return .ERR(.{
            .unexpected_eof = .{
                .expected_type = .keyword,
                .expected_value = "EVALUATE",
            },
        });
    }

    var path: std.BoundedArray([]const u8, 8) = try .init(0);
    var of: ?AssetTarget = null;
    var in: ?InTarget = null;

    var analyzing_key = true;
    while (tokens.peek(1)) |tkn| {
        if (analyzing_key) {
            if (tkn.isType(.literal) or tkn.isType(.literal_string)) {
                try path.append(tkn.value);
            } else {
                return .ERR(.{
                    .unexpected_token = .{
                        .found = tkn,
                        .expected_type = .literal,
                    },
                });
            }
        } else if (!tkn.is(.operator, ".")) {
            break;
        }
        _ = tokens.next();
        analyzing_key = !analyzing_key;
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
        .path = path,
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
    defer {
        for (guid) |g| data.allocator.free(g);
        data.allocator.free(guid);
    }

    const show = core.cmds.Show{
        .mode = .indirect_uses,
        .of = of,
        .in = in,
    };

    log.debug("Searching for references...", .{});

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

    log.debug("Evaluating found...", .{});

    try self.searchAndPrint(target_assets, guid, data);

    return .OK(void{});
}

pub fn searchAndPrint(self: This, asset_paths: []const []const u8, guid: []const []const u8, data: RuntimeData) !void {
    for (asset_paths) |p| {
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

        self.scanAndPrint(file, path, guid, data) catch |err| {
            log.warn("Error ({s}) scanning file: '{s}'", .{ @errorName(err), path });
            continue;
        };
    }
}

pub fn scanAndPrint(self: This, file: std.fs.File, file_path: []const u8, guid: []const []const u8, data: RuntimeData) !void {
    var iter = ComponentIterator.init(file, data.allocator);
    defer iter.deinit();

    while (try iter.next()) |comp| {
        var yaml = Yaml.init(.{ .string = comp.document }, null, data.allocator);

        if (!(core.cmds.Show.matchScriptOrPrefabGUID(guid, &yaml) catch false)) continue;

        const value = yaml.getAlloc(self.path.slice(), data.allocator) catch |err| {
            log.warn("Error ({s}) getting value in '{s}'", .{ @errorName(err), file_path });
            continue;
        };
        defer if (value) |v| data.allocator.free(v) else {};

        try print(file_path, value orelse continue, data);
    }
}

pub fn print(path: []const u8, value: []const u8, data: RuntimeData) !void {
    try data.out.print("{s} => {s}\r\n", .{ path, value });
}
