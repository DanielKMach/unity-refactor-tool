const std = @import("std");
const core = @import("core");
const results = core.results;

const This = @This();
const Tokenizer = core.parsing.Tokenizer;

dir: []const u8,

pub const default: This = .{ .dir = "." };

pub fn parse(tokens: *Tokenizer.TokenIterator, env: core.Stmt.ParsingEnv) core.Stmt.ParseError!This {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.IN)) return error.TokenMismatch;

    var dir: []const u8 = undefined;
    switch (tokens.next().value) {
        .string => |str| dir = try env.allocator.dupe(u8, str),
        .literal => |lit| dir = try env.allocator.dupe(u8, lit),
        else => return env.err(.{ .unexpected_token = .{
            .found = tokens.peek(0),
            .expected = &.{ .string, .literal },
        } }),
    }

    return .{ .dir = dir };
}

pub fn cleanup(self: This, allocator: std.mem.Allocator) void {
    allocator.free(self.dir);
}

pub fn openDir(self: This, env: core.Stmt.RuntimeEnv, options: std.fs.Dir.OpenOptions) core.Stmt.RuntimeError!std.fs.Dir {
    return env.cwd.openDir(self.dir, options) catch |err| switch (err) {
        error.FileNotFound => env.err(.{ .invalid_path = .{
            .path = self.dir,
        } }),
        else => |e| e,
    };
}
