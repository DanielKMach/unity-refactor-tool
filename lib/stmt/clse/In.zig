const std = @import("std");
const core = @import("core");

const This = @This();
const Stmt = core.Stmt;
const TokenIterator = core.Token.Iterator;

const open_options = std.fs.Dir.OpenOptions{
    .iterate = true,
    .access_sub_paths = true,
};

path: core.Token,

pub const default: This = .{
    .path = .new(.{ .string = "." }, .{ .index = 0, .len = 1 }),
};

pub fn parse(tokens: *TokenIterator, env: Stmt.ParseEnv) Stmt.ParseError!This {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.IN)) return error.TokenMismatch;

    const path = try (try tokens.grabAny(&.{ .string, .literal }, env.diag)).dupe(env.allocator);
    errdefer path.cleanup(env.allocator);

    return .{ .path = path };
}

pub fn cleanup(self: This, allocator: std.mem.Allocator) void {
    self.path.cleanup(allocator);
}

pub fn dir(self: This, env: Stmt.RunEnv) Stmt.RunError!std.fs.Dir {
    return switch (self.path.value) {
        .literal => |lit| openDir(lit, false, self.path, env),
        .string => |str| openDir(str, true, self.path, env),
        else => unreachable,
    };
}

fn openDir(path: []const u8, possibly_abs: bool, token: core.Token, env: Stmt.RunEnv) Stmt.RunError!std.fs.Dir {
    return if (possibly_abs and std.fs.path.isAbsolute(path))
        std.fs.openDirAbsolute(path, open_options) catch |err| switch (err) {
            error.FileNotFound => env.err(.{ .invalid_path = .{ .path = token.loc } }),
            else => |e| e,
        }
    else
        env.cwd.openDir(path, open_options) catch |err| switch (err) {
            error.FileNotFound => env.err(.{ .invalid_path = .{ .path = token.loc } }),
            else => |e| e,
        };
}
