const std = @import("std");
const core = @import("core");

const This = @This();
const Stmt = core.Stmt;
const TokenIterator = core.Token.Iterator;

const open_options = std.fs.Dir.OpenOptions{
    .iterate = true,
    .access_sub_paths = true,
};

path: ?core.Token,

pub const default: This = .{ .path = null };

pub fn parse(tokens: *TokenIterator, env: Stmt.ParseEnv) Stmt.ParseError!This {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.IN)) return error.TokenMismatch;

    const path = try (try tokens.grabAny(&.{ .string, .literal }, env.diag)).dupe(env.allocator);
    errdefer path.cleanup(env.allocator);

    if (std.fs.path.isAbsolute(path.asSlice())) {
        return env.err(.{ .absolute_path = .{ .token = path } });
    }

    return .{ .path = path };
}

pub fn cleanup(self: This, allocator: std.mem.Allocator) void {
    if (self.path) |p| p.cleanup(allocator);
}

pub fn subpath(self: This) ?[]const u8 {
    return if (self.path) |p| p.asSlice() else null;
}
