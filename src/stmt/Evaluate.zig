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
const Expr = core.Expr;

const files = &.{ ".prefab", ".unity", ".asset" };

expr: *Expr,
of: AssetTarget,
in: ?InTarget,

pub fn parse(tokens: *Tokenizer.TokenIterator, env: core.parsing.ParsetimeEnv) anyerror!results.ParseResult(This) {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.EVAL)) return .ERR(.unknown);

    const expr = switch (try Expr.parse(tokens, env.allocator)) {
        .ok => |expr| expr,
        .err => |err| return .ERR(err),
    };

    const Clauses = struct {
        OF: AssetTarget,
        IN: ?InTarget = null,
    };
    const clauses = switch (try core.stmt.clse.parse(Clauses, tokens, env)) {
        .ok => |clses| clses,
        .err => |err| return .ERR(err),
    };

    return .OK(.{
        .expr = expr,
        .of = clauses.OF,
        .in = clauses.IN,
    });
}

pub fn cleanup(self: This, allocator: std.mem.Allocator) void {
    self.of.cleanup(allocator);
    if (self.in) |in| in.cleanup(allocator);
    self.expr.cleanup(allocator);
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

    const result = try self.searchAndPrint(target_assets, guid, data.allocator, data.out);
    return switch (result) {
        .ok => .OK(void{}),
        .err => |err| .ERR(err),
    };
}

pub fn searchAndPrint(self: This, assets: []const []const u8, guid: []const GUID, allocator: std.mem.Allocator, out: std.io.AnyWriter) !results.RuntimeResult(void) {
    core.profiling.begin(searchAndPrint);
    defer core.profiling.stop();

    for (assets) |path| {
        const file = std.fs.openFileAbsolute(path, .{ .mode = .read_only }) catch |err| {
            log.warn("Error ({s}) opening file: '{s}'", .{ @errorName(err), path });
            continue;
        };
        defer file.close();

        const result = self.scanAndPrint(file, path, guid, allocator, out) catch |err| {
            log.warn("Error ({s}) scanning file: '{s}'", .{ @errorName(err), path });
            continue;
        };
        if (result.isErr()) |err| return .ERR(err);
    }
    return .OK(void{});
}

pub fn scanAndPrint(self: This, file: std.fs.File, file_path: []const u8, guid: []const GUID, allocator: std.mem.Allocator, out: std.io.AnyWriter) !results.RuntimeResult(void) {
    core.profiling.begin(scanAndPrint);
    defer core.profiling.stop();

    var iter = ComponentIterator.init(file, allocator);
    defer iter.deinit();

    while (try iter.next()) |comp| {
        var yaml = Yaml.init(.{ .string = comp.document }, null, allocator);

        if (!(try core.stmt.Show.matchScriptOrPrefabGUID(guid, &yaml))) continue;

        const vars = std.StringHashMap(core.Expr.Value).init(allocator);
        const result = try self.expr.evaluateAuto(.{
            .allocator = allocator,
            .vars = &vars,
        });

        const value = result.isOk() orelse return .ERR(result.err);
        defer value.cleanup(allocator);

        try print(file_path, value, out);
    }
    return .OK(void{});
}

pub fn print(path: []const u8, value: core.Expr.Value, out: std.io.AnyWriter) !void {
    core.profiling.begin(print);
    defer core.profiling.stop();

    try out.print("{s} =>", .{path});
    switch (value) {
        .nil => try out.print(" nil\n", .{}),
        .string => |s| try out.print(" '{s}'\n", .{s}),
        .number => |n| try out.print(" {d}\n", .{n}),
        .object => try out.print(" object\n", .{}),
        .array => try out.print(" array\n", .{}),
    }
}
