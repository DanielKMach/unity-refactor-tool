const std = @import("std");
const core = @import("root");
const results = core.results;

const This = @This();
const RuntimeEnv = core.runtime.RuntimeEnv;
const Tokenizer = core.language.Tokenizer;

dir: []const u8,

pub const default: This = .{ .dir = "." };

pub fn parse(tokens: *Tokenizer.TokenIterator) !results.ParseResult(This) {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.IN)) return .ERR(.{
        .unexpected_token = .{
            .found = tokens.peek(1),
            .expected = &.{.IN},
        },
    });

    var dir: []const u8 = undefined;
    switch (tokens.next().value) {
        .string => |str| dir = str,
        .literal => |lit| dir = lit,
        else => return .ERR(.{
            .unexpected_token = .{
                .found = tokens.peek(0),
                .expected = &.{ .string, .literal },
            },
        }),
    }

    return .OK(.{ .dir = dir });
}

pub fn openDir(self: This, data: RuntimeEnv, options: std.fs.Dir.OpenDirOptions) !std.fs.Dir {
    const dir = try data.cwd.openDir(self.dir, options);
    return dir;
}
