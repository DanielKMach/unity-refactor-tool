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
const GUID = core.runtime.GUID;

const files = &.{ ".prefab", ".unity", ".asset" };

path: std.BoundedArray([]const u8, 8),
of: AssetTarget,
in: InTarget,

pub fn parse(tokens: *Tokenizer.TokenIterator) !results.ParseResult(This) {
    core.profiling.begin(parse);
    defer core.profiling.stop();

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
    defer data.allocator.free(guid);
    defer for (guid) |g| g.deinit(data.allocator);

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
    defer data.allocator.free(target_assets);
    defer for (target_assets) |asset| {
        data.allocator.free(asset);
    };

    log.debug("Evaluating found...", .{});

    try self.searchAndPrint(target_assets, guid, data.allocator, data.out);

    return .OK(void{});
}

pub fn searchAndPrint(self: This, assets: []const []const u8, guid: []const GUID, allocator: std.mem.Allocator, out: std.io.AnyWriter) !void {
    core.profiling.begin(searchAndPrint);
    defer core.profiling.stop();

    for (assets) |path| {
        const file = std.fs.openFileAbsolute(path, .{ .mode = .read_only }) catch |err| {
            log.warn("Error ({s}) opening file: '{s}'", .{ @errorName(err), path });
            continue;
        };
        defer file.close();

        self.scanAndPrint(file, path, guid, allocator, out) catch |err| {
            log.warn("Error ({s}) scanning file: '{s}'", .{ @errorName(err), path });
            continue;
        };
    }
}

pub fn scanAndPrint(self: This, file: std.fs.File, file_path: []const u8, guid: []const GUID, allocator: std.mem.Allocator, out: std.io.AnyWriter) !void {
    core.profiling.begin(scanAndPrint);
    defer core.profiling.stop();

    var iter = ComponentIterator.init(file, allocator);
    defer iter.deinit();

    while (try iter.next()) |comp| {
        var yaml = Yaml.init(.{ .string = comp.document }, null, allocator);

        if (!(try core.cmds.Show.matchScriptOrPrefabGUID(guid, &yaml))) continue;

        const value = try yaml.getAlloc(self.path.slice(), allocator);
        defer if (value) |v| allocator.free(v) else {};

        try print(file_path, value orelse continue, out);
    }
}

pub fn print(path: []const u8, value: []const u8, out: std.io.AnyWriter) !void {
    core.profiling.begin(print);
    defer core.profiling.stop();

    try out.print("{s} => {s}\r\n", .{ path, value });
}
