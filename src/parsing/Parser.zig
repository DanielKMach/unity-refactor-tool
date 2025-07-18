const std = @import("std");
const core = @import("core");

const Parser = @This();

const Tokenizer = core.parsing.Tokenizer;

allocator: std.mem.Allocator,

/// Parses the given query source code into a script.
///
/// `source` must only be freed after the returned script is deinitialized.
pub fn parse(self: Parser, source: core.Source) !core.results.ParseResult(core.runtime.Script) {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    const tokens = switch (try Tokenizer.tokenize(source.source, self.allocator)) {
        .ok => |it| it,
        .err => |err| return .ERR(err),
    };
    defer self.allocator.free(tokens);

    var iterator = Tokenizer.TokenIterator.init(tokens);
    const env = core.parsing.ParsetimeEnv{
        .allocator = self.allocator,
    };

    var statements = std.ArrayList(core.stmt.Statement).init(self.allocator);
    defer statements.deinit();

    while (iterator.remaining() > 0) {
        const stmt = switch (try core.stmt.Statement.parse(&iterator, env)) {
            .ok => |stmt| stmt,
            .err => |err| return .ERR(err),
        };
        try statements.append(stmt);
        if (!iterator.match(.eos)) {
            return .ERR(.{
                .unexpected_token = .{
                    .found = iterator.next(),
                    .expected = &.{.eos},
                },
            });
        }
    }

    return .OK(core.runtime.Script{
        .allocator = self.allocator,
        .statements = try statements.toOwnedSlice(),
    });
}
