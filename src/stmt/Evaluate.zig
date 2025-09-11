const std = @import("std");
const core = @import("core");
const ly = @import("libyaml");
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

pub fn run(self: This, env: RuntimeEnv) anyerror!results.RuntimeResult(void) {
    core.profiling.begin(run);
    defer core.profiling.stop();

    const in = self.in orelse InTarget.default;
    const of = self.of;

    var dir = in.openDir(env, .{ .iterate = true, .access_sub_paths = true }) catch {
        return .ERR(.{
            .invalid_path = .{ .path = in.dir },
        });
    };
    defer dir.close();

    const guid = switch (try of.getGUID(env.cwd, env.allocator)) {
        .ok => |v| v,
        .err => |err| return .ERR(err),
    };
    defer env.allocator.free(guid);
    defer for (guid) |g| g.deinit(env.allocator);

    const show = core.stmt.Show{
        .mode = .indirect_uses,
        .of = of,
        .in = in,
    };

    log.info("Searching for references...", .{});

    const search_result = try show.search(env, null, null);
    if (search_result.isErr()) |err| {
        return .ERR(err);
    }
    const target_assets = search_result.ok;
    defer env.allocator.free(target_assets);
    defer for (target_assets) |asset| {
        env.allocator.free(asset);
    };

    log.info("Printing references...", .{});

    const result = try self.searchAndPrint(target_assets, guid, env);
    try env.out.flush();
    return switch (result) {
        .ok => .OK(void{}),
        .err => |err| .ERR(err),
    };
}

pub fn searchAndPrint(self: This, assets: []const []const u8, guid: []const GUID, env: RuntimeEnv) !results.RuntimeResult(void) {
    core.profiling.begin(searchAndPrint);
    defer core.profiling.stop();

    for (assets) |path| {
        const file = std.fs.openFileAbsolute(path, .{ .mode = .read_write }) catch |err| {
            log.warn("Error ({s}) opening file: '{s}'", .{ @errorName(err), path });
            continue;
        };
        defer file.close();

        const result = self.scanAndPrint(file, path, guid, env) catch |err| {
            log.warn("Error ({s}) scanning file: '{s}'", .{ @errorName(err), path });
            continue;
        };
        if (result.isErr()) |err| return .ERR(err);
    }
    return .OK(void{});
}

pub fn scanAndPrint(self: This, file: std.fs.File, file_path: []const u8, guid: []const GUID, env: RuntimeEnv) !results.RuntimeResult(void) {
    core.profiling.begin(scanAndPrint);
    defer core.profiling.stop();

    var iter = try ComponentIterator.init(file, env.allocator);
    defer iter.deinit();

    var changes = std.ArrayList(ComponentIterator.Component).empty;
    defer changes.deinit(env.allocator);
    defer for (changes.items) |change| env.allocator.free(change.document);

    while (try iter.next()) |comp| {
        const buf = try env.allocator.alloc(u8, comp.len * 2);
        defer env.allocator.free(buf);

        var out_yaml = buf;
        var yaml = Yaml.init(.{ .string = comp.document }, .{ .string = &out_yaml }, env.allocator);

        if (!(try core.stmt.Show.matchScriptOrPrefabGUID(guid, &yaml))) continue;

        var doc: Yaml.Document = undefined;
        try yaml.loadDocument(&doc);
        defer Yaml.deleteDocument(&doc);

        var vars = Expr.VarMap.init(env.allocator);
        const root = Expr.Value.Object{
            .node = @ptrCast(doc.nodes.start),
            .document = &doc,
        };

        const result = try self.expr.evaluateAuto(.{
            .allocator = env.allocator,
            .context = (root.get("MonoBehaviour") orelse unreachable).object,
            .vars = &vars,
        });

        const value = result.isOk() orelse return .ERR(result.err);
        defer value.cleanup(env.allocator);

        try yaml.dumpDocument(&doc);

        if (!std.mem.eql(u8, out_yaml, comp.document)) {
            try changes.append(env.allocator, .{
                .index = comp.index,
                .len = comp.len,
                .document = try env.allocator.dupe(u8, out_yaml),
            });
        }

        try print(file_path, value, env.out);
    }

    if (changes.items.len == 0) {
        return .OK(void{});
    }

    const temp = try env.transaction.getTemp();
    defer env.transaction.delTemp(temp);

    var patcher = core.runtime.FilePatcher.init(file, temp, env.allocator);
    defer patcher.deinit();

    try patcher.start();
    for (changes.items) |change| {
        try patcher.patch(change.index, change.len, change.document);
    }
    try patcher.flush();
    try patcher.apply();

    return .OK(void{});
}

pub fn print(path: []const u8, value: core.Expr.Value, out: *std.Io.Writer) !void {
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
