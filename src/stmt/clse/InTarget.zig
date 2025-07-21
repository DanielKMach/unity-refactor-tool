const std = @import("std");
const core = @import("core");
const results = core.results;

const This = @This();
const RuntimeEnv = core.runtime.RuntimeEnv;
const Tokenizer = core.parsing.Tokenizer;

dir: []const u8,

pub const default: This = .{ .dir = "." };

pub fn parse(tokens: *Tokenizer.TokenIterator, env: core.parsing.ParsetimeEnv) anyerror!results.ParseResult(This) {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.IN)) return .ERR(.unknown);

    var dir: []const u8 = undefined;
    switch (tokens.next().value) {
        .string => |str| dir = try env.allocator.dupe(u8, str),
        .literal => |lit| dir = try env.allocator.dupe(u8, lit),
        else => return .ERR(.{
            .unexpected_token = .{
                .found = tokens.peek(0),
                .expected = &.{ .string, .literal },
            },
        }),
    }

    return .OK(.{ .dir = dir });
}

pub fn cleanup(self: This, allocator: std.mem.Allocator) void {
    allocator.free(self.dir);
}

pub fn openDir(self: This, data: RuntimeEnv, options: std.fs.Dir.OpenDirOptions) !std.fs.Dir {
    const dir = try data.cwd.openDir(self.dir, options);
    return dir;
}
