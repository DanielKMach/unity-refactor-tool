const std = @import("std");
const core = @import("core");
const ly = @import("libyaml");
const log = std.log.scoped(.evaluate_statement);

const This = @This();
const Stmt = core.Stmt;
const clse = core.Stmt.clse;
const TokenIterator = core.Token.Iterator;
const Scanner = core.runtime.Scanner;
const ComponentIterator = core.runtime.ComponentIterator;
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
    try env.out.flush();
}

pub fn searchAndPrint(self: This, assets: []const []const u8, guid: []const GUID, env: core.Stmt.RunEnv) core.Stmt.RunError!void {
    core.profiling.begin(searchAndPrint);
    defer core.profiling.stop();

    for (assets) |path| {
        const file = std.fs.openFileAbsolute(path, .{ .mode = .read_write }) catch |err| {
            log.warn("Error ({s}) opening file: '{s}'", .{ @errorName(err), path });
            return err;
        };
        defer file.close();

        self.scanAndPrint(file, path, guid, env) catch |err| {
            if (err != error.USRLRuntimeError) {
                log.warn("Error ({s}) scanning file: '{s}'", .{ @errorName(err), path });
            }
            return err;
        };
    }
}

pub fn scanAndPrint(self: This, file: std.fs.File, file_path: []const u8, guids: []const GUID, env: core.Stmt.RunEnv) !void {
    core.profiling.begin(scanAndPrint);
    defer core.profiling.stop();

    var iter = try ComponentIterator.init(file, env.allocator);
    defer iter.deinit();

    var changes = std.ArrayList(ComponentIterator.Entry).empty;
    defer changes.deinit(env.allocator);
    defer for (changes.items) |change| env.allocator.free(change.content);

    while (try iter.next()) |e| {
        const buf = try env.allocator.alloc(u8, e.content.len * 2);
        defer env.allocator.free(buf);

        var out_yaml = buf;
        var yaml = Yaml.init(.{ .string = e.content }, .{ .string = &out_yaml }, env.allocator);

        const guid = try Stmt.Show.matchGUID(guids, &yaml) orelse continue;

        var objs: core.runtime.ObjMap = .init(env.allocator);
        defer objs.deinit();

        const ctx: Expr.Value.Asset = .{
            .file_id = e.info.file_id,
            .guid = guid,
        };
        const doc = try objs.new(guid, e.info.file_id, e.info.class_id);
        try yaml.loadDocument(doc);

        var vars: Expr.VarMap = try .default(env.allocator);
        const value = try self.expr.evaluateAuto(.{
            .allocator = env.allocator,
            .diag = env.diag,
            .context = ctx,
            .objs = &objs,
            .vars = &vars,
        });
        defer value.cleanup(env.allocator);
        try print(file_path, value, env.out);

        try yaml.dumpDocument(doc);

        if (!std.mem.eql(u8, out_yaml, e.content)) {
            try changes.append(env.allocator, .{
                .info = e.info,
                .content = try env.allocator.dupe(u8, out_yaml),
            });
        }
    }

    if (changes.items.len == 0) {
        return;
    }

    try env.transaction.include(file_path);

    const temp = try env.transaction.getTemp();
    defer env.transaction.delTemp(temp);

    var patcher = core.runtime.FilePatcher.init(file, temp, env.allocator);
    defer patcher.deinit();

    try patcher.start();
    for (changes.items) |change| {
        try patcher.patch(change.info.pos, change.info.len, change.content);
    }
    try patcher.flush();
    try patcher.apply();
}

pub fn print(path: []const u8, value: core.Expr.Value, out: *std.Io.Writer) !void {
    core.profiling.begin(print);
    defer core.profiling.stop();

    try out.print("{s} => {f}\r\n", .{ path, value });
}
