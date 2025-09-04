const std = @import("std");
const core = @import("core");

const This = @This();
const log = std.log.scoped(.script);

allocator: std.mem.Allocator,
statements: []core.stmt.Statement,

pub fn run(this: This, options: RunConfig) !core.results.RuntimeResult(void) {
    core.profiling.begin(run);
    defer core.profiling.stop();

    var transaction = core.runtime.Transaction.init(options.allocator);
    defer transaction.deinit();
    errdefer transaction.rollback();

    const env = core.runtime.RuntimeEnv{
        .allocator = options.allocator,
        .transaction = &transaction,
        .out = options.out,
        .cwd = options.cwd,
    };

    for (this.statements) |stmt| {
        const result = try stmt.run(env);
        if (result.isErr()) |err| {
            transaction.rollback();
            return .ERR(err);
        }
    }
    transaction.commit();
    return .OK(void{});
}

pub fn deinit(this: This) void {
    for (this.statements) |stmt| {
        stmt.deinit(this.allocator);
    }
    this.allocator.free(this.statements);
}

pub const RunConfig = struct {
    allocator: std.mem.Allocator,
    out: *std.Io.Writer,
    cwd: std.fs.Dir,
};
