const std = @import("std");
const core = @import("core");
const ly = @import("libyaml");
const log = std.log.scoped(.evaluate_statement);

const This = @This();
const Stmt = core.Stmt;
const clse = core.Stmt.clse;
const TokenIterator = core.Token.Iterator;
const Scanner = core.runtime.Scanner;
const ObjIterator = core.runtime.ObjIterator;
const Yaml = core.runtime.Yaml;
const GUID = core.runtime.GUID;
const Expr = core.Expr;

expr: *Expr,
of: clse.Of,
in: ?clse.In,

pub fn parse(tokens: *TokenIterator, env: Stmt.ParseEnv) Stmt.ParseError!This {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.EVAL)) return error.TokenMismatch;

    const expr = try Expr.parse(tokens, .{
        .allocator = env.allocator,
        .diag = env.diag,
    });

    const Clauses = struct {
        OF: clse.Of,
        IN: ?clse.In = null,
    };
    const clauses = try clse.parse(Clauses, tokens, env);

    return .{
        .expr = expr,
        .of = clauses.OF,
        .in = clauses.IN,
    };
}

pub fn cleanup(self: This, allocator: std.mem.Allocator) void {
    self.of.cleanup(allocator);
    if (self.in) |in| in.cleanup(allocator);
    self.expr.cleanup(allocator);
}

pub fn run(self: This, env: core.Stmt.RunEnv) core.Stmt.RunError!void {
    core.profiling.begin(run);
    defer core.profiling.stop();

    const guid = try self.of.getGUID(env);
    defer env.allocator.free(guid);

    const show = Stmt.Show{
        .mode = .indirect_uses,
        .of = self.of,
        .in = self.in,
    };

    log.info("Searching for references...", .{});

    const target_assets = try show.search(null, null, env);
    defer env.allocator.free(target_assets);
    defer for (target_assets) |asset| {
        env.allocator.free(asset);
    };

    log.info("Printing references...", .{});

    try self.searchAndPrint(target_assets, guid, env);
}

pub fn searchAndPrint(self: This, refs: []const []const u8, guid: []const GUID, env: core.Stmt.RunEnv) core.Stmt.RunError!void {
    core.profiling.begin(searchAndPrint);
    defer core.profiling.stop();

    var objs: core.runtime.ObjMap = .init(env.allocator);
    defer objs.deinit();

    var assets: core.runtime.AssetMap = .init(env.allocator);
    defer assets.deinit();

    for (refs) |path| {
        self.scanAndPrint(path, guid, &assets, &objs, env) catch |err| {
            if (err != error.USRLRuntimeError) {
                log.warn("Error ({s}) scanning file: '{s}'", .{ @errorName(err), path });
            }
            return err;
        };
    }
    try env.out.flush();

    var fetched = assets.entries();
    while (fetched.next()) |entry| {
        try env.out.flush();
        try env.transaction.include(entry.value_ptr.*);

        const file = try std.fs.openFileAbsolute(entry.value_ptr.*, .{ .mode = .read_write });
        defer file.close();

        const temp = try env.transaction.getTemp();
        defer env.transaction.delTemp(temp);

        var patcher = core.runtime.FilePatcher.init(file, temp, env.allocator);
        defer patcher.deinit();

        var iter = try ObjIterator.init(file, env.allocator);
        defer iter.deinit();

        try patcher.start();

        while (try iter.next()) |obj| {
            const change = objs.get(entry.key_ptr.*, obj.info.file_id) orelse continue;

            const buf = try env.allocator.alloc(u8, obj.content.len * 2);
            defer env.allocator.free(buf);

            var out = std.Io.Writer.fixed(buf);
            var yml = Yaml.init(.{ .string = obj.content }, .{ .writer = &out }, env.allocator);

            try yml.dumpDocument(change.doc);
            if (std.mem.eql(u8, obj.content, out.buffered())) continue;

            try patcher.patch(obj.info.pos, obj.info.len, out.buffered());
        }
        try patcher.flush();
        try patcher.apply();
    }
}

pub fn scanAndPrint(self: This, path: []const u8, guids: []const GUID, assets: *core.runtime.AssetMap, objs: *core.runtime.ObjMap, env: core.Stmt.RunEnv) !void {
    core.profiling.begin(scanAndPrint);
    defer core.profiling.stop();

    const file = try std.fs.openFileAbsolute(path, .{ .mode = .read_write });
    defer file.close();

    var iter: ObjIterator = try .init(file, env.allocator);
    defer iter.deinit();

    while (try iter.next()) |e| {
        var yaml = Yaml.init(.{ .string = e.content }, null, env.allocator);

        if (try Stmt.Show.matchGUID(guids, &yaml) == null) continue;
        const guid = try assets.put(path);

        const ctx: Expr.Value.Asset = .{
            .file_id = e.info.file_id,
            .guid = guid,
            .type = 3, // TODO: determine type
        };

        const doc = try objs.new(guid, e.info.file_id, e.info.class_id);
        try yaml.loadDocument(doc);

        var vars: Expr.VarMap = try .default(env.allocator);
        const value = try self.expr.evaluateAuto(.{
            .allocator = env.allocator,
            .root = undefined, // Will be set by evaluateAuto
            .diag = env.diag,
            .context = ctx,
            .assets = assets,
            .objs = objs,
            .vars = &vars,
        });
        defer value.cleanup(env.allocator);
        try print(path, value, env.out);
    }
}

pub fn print(path: []const u8, value: core.Expr.Value, out: *std.Io.Writer) !void {
    core.profiling.begin(print);
    defer core.profiling.stop();

    try out.print("{s} => {f}\r\n", .{ path, value });
}
