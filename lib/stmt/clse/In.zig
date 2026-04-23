const std = @import("std");
const core = @import("core");
const tracy = @import("tracy");

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
    const zone = tracy.Zone(@src());
    defer zone.End();

    if (!tokens.match(.IN)) return error.TokenMismatch;

    const path = try tokens.grabAny(&.{ .string, .literal }, env.diag);

    if (std.fs.path.isAbsolute(path.asSlice())) {
        return env.err(.{ .absolute_path = .{ .token = path } });
    }

    return .{ .path = path };
}

pub fn subpath(self: This) ?[]const u8 {
    return if (self.path) |p| p.asSlice() else null;
}
