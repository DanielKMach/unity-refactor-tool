const std = @import("std");
const core = @import("root");

const Tokenizer = core.language.Tokenizer;

pub fn parse(reader: std.io.AnyReader, allocator: std.mem.Allocator) !core.results.ParseResult(core.runtime.Script) {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    const str = try reader.readAllAlloc(allocator, std.math.maxInt(u32));
    var tokens = switch (try Tokenizer.tokenize(str, allocator)) {
        .ok => |it| it,
        .err => |err| return .ERR(err),
    };

    const iterators = try tokens.split(Tokenizer.Token.new(.eos, ";"), allocator);
    defer allocator.free(iterators);

    var statements = std.ArrayList(core.stmt.Statement).init(allocator);
    defer statements.deinit();

    for (iterators) |*it| {
        if (it.len() == 0) continue; // Skip empty iterators
        const stmt = switch (try core.stmt.Statement.parse(it)) {
            .ok => |stmt| stmt,
            .err => |err| return .ERR(err),
        };
        try statements.append(stmt);
    }

    return .OK(core.runtime.Script{ .statements = try statements.toOwnedSlice() });
}
