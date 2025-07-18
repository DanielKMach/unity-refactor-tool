const std = @import("std");
const core = @import("core");
const results = core.results;
const log = std.log.scoped(.evaluate_statement);

const This = @This();
const Tokenizer = core.parsing.Tokenizer;
const Scanner = core.runtime.Scanner;
const RuntimeEnv = core.runtime.RuntimeEnv;
const ComponentIterator = core.runtime.ComponentIterator;
const Yaml = core.runtime.Yaml;
const InTarget = core.stmt.clse.InTarget;
const AssetTarget = core.stmt.clse.AssetTarget;
const GUID = core.runtime.GUID;

const files = &.{ ".prefab", ".unity", ".asset" };

path: [][]const u8,
of: AssetTarget,
in: ?InTarget,

pub fn parse(tokens: *Tokenizer.TokenIterator, env: core.parsing.ParsetimeEnv) anyerror!results.ParseResult(This) {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.EVAL)) return .ERR(.unknown);

    var path = std.ArrayList([]const u8).init(env.allocator);
    defer path.deinit();
    errdefer for (path.items) |p| env.allocator.free(p);

    while (true) {
        switch (tokens.next().value) {
            .string => |str| try path.append(try env.allocator.dupe(u8, str)),
            .literal => |lit| try path.append(try env.allocator.dupe(u8, lit)),
            else => return .ERR(.{
                .unexpected_token = .{
                    .found = tokens.peek(0),
                    .expected = &.{ .literal, .string },
                },
            }),
        }

        if (!tokens.match(.dot)) break;
    }

    const Clauses = struct {
        OF: AssetTarget,
        IN: ?InTarget = null,
    };
    const clauses = switch (try core.stmt.clse.parse(Clauses, tokens, env)) {
        .ok => |clses| clses,
        .err => |err| return .ERR(err),
    };

    return .OK(.{
        .path = try path.toOwnedSlice(),
        .of = clauses.OF,
        .in = clauses.IN,
    });
}

pub fn deinit(self: This, allocator: std.mem.Allocator) void {
    self.of.deinit(allocator);
    if (self.in) |in| in.deinit(allocator);
    for (self.path) |p| allocator.free(p);
}

pub fn run(self: This, data: RuntimeEnv) anyerror!results.RuntimeResult(void) {
    core.profiling.begin(run);
    defer core.profiling.stop();

    const in = self.in orelse InTarget.default;
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

        const path = self.path;
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
