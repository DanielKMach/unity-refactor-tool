const std = @import("std");
const core = @import("core");

const Tokenizer = core.language.Tokenizer;

/// Parses the given query source code into a script.
///
/// `source` must only be freed after the returned script is deinitialized.
pub fn parse(source: []const u8, allocator: std.mem.Allocator) !core.results.ParseResult(core.runtime.Script) {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    const tokens = switch (try Tokenizer.tokenize(source, allocator)) {
        .ok => |it| it,
        .err => |err| return .ERR(err),
    };
    defer allocator.free(tokens);

    var iterator = Tokenizer.TokenIterator.init(tokens);

    var statements = std.ArrayList(core.stmt.Statement).init(allocator);
    defer statements.deinit();

    while (iterator.remaining() > 0) {
        const stmt = switch (try core.stmt.Statement.parse(&iterator)) {
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
        .allocator = allocator,
        .source = source,
        .statements = try statements.toOwnedSlice(),
    });
}
