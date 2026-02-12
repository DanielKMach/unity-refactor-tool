const std = @import("std");
const core = @import("core");

const Parser = @This();

const Tokenizer = core.Tokenizer;

allocator: std.mem.Allocator,

/// Parses the given query source code into a script.
///
/// `source` must only be freed after the returned script is deinitialized.
pub fn parse(self: Parser, source: core.Source) std.mem.Allocator.Error!core.Result(core.Script, []core.ParseProblem) {
    var diag = core.ParseDiagnostics.init(self.allocator);
    defer diag.deinit();

    const env = core.Stmt.ParseEnv{
        .allocator = self.allocator,
        .diag = &diag,
    };

    const script = self.parseEnv(source, env) catch |err| {
        switch (err) {
            error.USRLParseError => {},
            else => |e| diag.push(.{ .unexpected = e }) catch {},
        }
        return .ERR(try diag.toOwnedSlice());
    };
    return .OK(script);
}

pub fn parseEnv(self: Parser, source: core.Source, env: core.Stmt.ParseEnv) core.ParseAllocError!core.Script {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    const tokens = try Tokenizer.tokenize(source.source, env.allocator, env.diag);
    defer self.allocator.free(tokens);

    var iterator = core.Token.Iterator.init(tokens);

    var statements = std.ArrayList(core.Stmt).empty;
    defer statements.deinit(self.allocator);
    errdefer for (statements.items) |stmt| stmt.deinit(self.allocator);

    while (!iterator.match(.eof) and iterator.remaining() > 0) {
        const stmt = try core.Stmt.parse(&iterator, env);
        try statements.append(self.allocator, stmt);
        const end = try iterator.grabAny(&.{ .semicolon, .eof }, env.diag);
        if (end.is(.eof)) break;
    }

    return .{
        .allocator = self.allocator,
        .statements = try statements.toOwnedSlice(self.allocator),
    };
}
