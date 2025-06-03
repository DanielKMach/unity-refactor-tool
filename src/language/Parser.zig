const std = @import("std");
const core = @import("root");

const Tokenizer = core.language.Tokenizer;

pub fn parse(source: []const u8, allocator: std.mem.Allocator) !core.results.ParseResult(core.runtime.Script) {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    var tokens = switch (try Tokenizer.tokenize(source, allocator)) {
        .ok => |it| it,
        .err => |err| return .ERR(err),
    };
    defer tokens.deinit();

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

    return .OK(core.runtime.Script{
        .allocator = allocator,
        .source = source,
        .statements = try statements.toOwnedSlice(),
    });
}

pub fn parseFrom(reader: std.io.AnyReader, allocator: std.mem.Allocator, out_source: ?*[]u8) !core.results.ParseResult(core.runtime.Script) {
    core.profiling.begin(parseFrom);
    defer core.profiling.stop();

    const source = try reader.readAllAlloc(allocator, std.math.maxInt(u16));
    if (out_source) |src| {
        src.* = source;
    }
    return parse(source, allocator);
}
