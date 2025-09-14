const std = @import("std");
const core = @import("core");

const This = @This();
const log = std.log.scoped(.script);

allocator: std.mem.Allocator,
statements: []core.Stmt,

pub fn run(self: This, options: RunConfig) !core.Result(void, []core.RuntimeProblem) {
    var transaction = core.Transaction.init(options.allocator);
    defer transaction.deinit();

    var diag = core.RuntimeDiagnostics.init(options.allocator);
    defer diag.deinit();

    const env = core.Stmt.RunEnv{
        .diag = &diag,
        .transaction = &transaction,
        .allocator = options.allocator,
        .out = options.out,
        .cwd = options.cwd,
    };

    self.runEnv(env) catch |err| {
        transaction.rollback();
        return switch (err) {
            error.USRLRuntimeError => .ERR(try diag.toOwnedSlice()),
            else => |e| e,
        };
    };

    transaction.commit();
    return .OK(void{});
}

pub fn runEnv(self: This, env: core.Stmt.RunEnv) anyerror!void {
    core.profiling.begin(run);
    defer core.profiling.stop();

    for (self.statements) |stmt| {
        try stmt.run(env);
    }
}

pub fn deinit(self: This) void {
    for (self.statements) |stmt| {
        stmt.deinit(self.allocator);
    }
    self.allocator.free(self.statements);
}

pub const RunConfig = struct {
    allocator: std.mem.Allocator,
    out: *std.Io.Writer,
    cwd: std.fs.Dir,
};
