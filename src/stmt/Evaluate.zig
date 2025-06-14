const std = @import("std");
const core = @import("core");
const results = core.results;
const log = std.log.scoped(.evaluate_statement);

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

path: std.BoundedArray([]const u8, 8),
of: AssetTarget,
in: InTarget,

pub fn parse(tokens: *Tokenizer.TokenIterator) !results.ParseResult(This) {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.EVAL)) return .ERR(.unknown);

    var path: std.BoundedArray([]const u8, 8) = try .init(0);
    var of: ?AssetTarget = null;
    var in: ?InTarget = null;

    while (true) {
        switch (tokens.next().value) {
            .string => |str| try path.append(str),
            .literal => |lit| try path.append(lit),
            else => return .ERR(.{
                .unexpected_token = .{
                    .found = tokens.peek(0),
                    .expected = &.{ .literal, .string },
                },
            }),
        }

        if (!tokens.match(.dot)) break;
    }

    clses: switch (tokens.peek(1).value) {
        .OF => {
            if (of != null) continue :clses .EVAL;
            of = switch (try AssetTarget.parse(tokens)) {
                .ok => |v| v,
                .err => |err| return .ERR(err),
            };
            continue :clses tokens.peek(1).value;
        },
        .IN => {
            if (in != null) continue :clses .EVAL;
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
        .path = path,
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
    defer data.allocator.free(guid);
    defer for (guid) |g| g.deinit(data.allocator);

    const show = core.stmt.Show{
        .mode = .indirect_uses,
        .of = of,
        .in = in,
    };

    log.info("Searching for references...", .{});

    const search_result = try show.search(data, null, null);
    if (search_result.isErr()) |err| {
        return .ERR(err);
    }
    const target_assets = search_result.ok;
    defer data.allocator.free(target_assets);
    defer for (target_assets) |asset| {
        data.allocator.free(asset);
    };

    log.info("Printing references...", .{});

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

        if (!(try core.stmt.Show.matchScriptOrPrefabGUID(guid, &yaml))) continue;

        const path = self.path.slice();
        const new_path = try allocator.alloc([]const u8, path.len + 1);
        defer allocator.free(new_path);
        @memcpy(new_path[1..], path);
        new_path[0] = "MonoBehaviour";

        const value = try yaml.getAlloc(new_path, allocator);
        defer if (value) |v| allocator.free(v) else {};

        try print(file_path, value orelse continue, out);
    }
}

pub fn print(path: []const u8, value: []const u8, out: std.io.AnyWriter) !void {
    core.profiling.begin(print);
    defer core.profiling.stop();

    try out.print("{s} => {s}\r\n", .{ path, value });
}
