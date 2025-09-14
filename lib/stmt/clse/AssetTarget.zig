const std = @import("std");
const core = @import("core");

const This = @This();
const Stmt = core.Stmt;
const TokenIterator = core.Token.Iterator;
const Yaml = core.runtime.Yaml;
const GUID = core.runtime.GUID;

targets: []AssetTarget,

pub fn parse(tokens: *TokenIterator, env: Stmt.ParsingEnv) Stmt.ParseError!This {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.OF)) return error.TokenMismatch;

    var targets = std.ArrayList(AssetTarget).empty;
    defer targets.deinit(env.allocator);
    errdefer for (targets.items) |target| switch (target) {
        .guid => |guid| guid.cleanup(env.allocator),
        .name => |name| name.cleanup(env.allocator),
        .path => |path| path.cleanup(env.allocator),
    };

    while (true) {
        const tkn = try tokens.grabAny(&.{ .GUID, .literal, .string }, env.diag);
        switch (tkn.value) {
            .GUID => {
                const guid_tkn = try tokens.grab(.string, env.diag);
                if (GUID.isGUID(guid_tkn.value.string)) {
                    try targets.append(env.allocator, .{
                        .guid = try guid_tkn.dupe(env.allocator),
                    });
                } else return env.err(.{ .invalid_guid = .{
                    .token = guid_tkn,
                } });
            },
            .literal => |lit| {
                if (isCSharpIdentifier(lit)) {
                    try targets.append(env.allocator, .{
                        .name = try tkn.dupe(env.allocator),
                    });
                } else return env.err(.{ .invalid_csharp_identifier = .{
                    .token = tkn,
                } });
            },
            .string => try targets.append(env.allocator, .{
                .path = try tkn.dupe(env.allocator),
            }),
            else => unreachable,
        }

        if (!tokens.match(.comma)) break;
    }

    return .{ .targets = try targets.toOwnedSlice(env.allocator) };
}

pub fn cleanup(self: This, allocator: std.mem.Allocator) void {
    for (self.targets) |target| switch (target) {
        .guid => |guid| guid.cleanup(allocator),
        .name => |name| name.cleanup(allocator),
        .path => |path| path.cleanup(allocator),
    };
    allocator.free(self.targets);
}

pub fn getGUID(self: This, env: Stmt.RuntimeEnv) Stmt.RuntimeError![]GUID {
    core.profiling.begin(getGUID);
    defer core.profiling.stop();

    var guids = std.ArrayList(GUID).empty;
    defer guids.deinit(env.allocator);
    errdefer for (guids.items) |guid| guid.deinit(env.allocator);

    for (self.targets) |target| {
        try guids.append(env.allocator, switch (target) {
            .guid => |guid| try GUID.init(guid.value.string, null, env.allocator),
            .name => |name| blk: {
                const path = try searchComponent(name.value.literal, env.cwd, env.allocator) orelse {
                    return env.err(.{ .invalid_asset = .{ .path = name.value.literal } });
                };
                defer env.allocator.free(path);

                break :blk GUID.fromFile(path, env.allocator) catch |err| switch (err) {
                    error.InvalidMetaFile, error.FileNotFound => {
                        return env.err(.{ .invalid_asset = .{ .path = path } });
                    },
                    else => |e| return e,
                };
            },
            .path => |path| blk: {
                const abs_path = try env.cwd.realpathAlloc(env.allocator, path.value.string);
                defer env.allocator.free(abs_path);

                break :blk GUID.fromFile(abs_path, env.allocator) catch |err| switch (err) {
                    error.InvalidMetaFile, error.FileNotFound => {
                        return env.err(.{ .invalid_asset = .{ .path = abs_path } });
                    },
                    else => |e| return e,
                };
            },
        });
    }
    return try guids.toOwnedSlice(env.allocator);
}

fn isCSharpIdentifier(str: []const u8) bool {
    if (str.len == 0) return false;
    if (!std.ascii.isAlphabetic(str[0]) and str[0] != '_') return false;
    for (str[1..]) |c| {
        if (!std.ascii.isAlphanumeric(c) and c != '_') return false;
    }
    return true;
}

/// Returns the absolute path of the component file.
///
/// The return value is owned by the caller.
fn searchComponent(name: []const u8, dir: std.fs.Dir, allocator: std.mem.Allocator) !?[]u8 {
    core.profiling.begin(searchComponent);
    defer core.profiling.stop();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    const target_name = try std.mem.concat(allocator, u8, &.{ name, ".cs.meta" });
    defer allocator.free(target_name);

    while (try walker.next()) |e| {
        if (std.mem.eql(u8, e.basename, target_name)) {
            return try dir.realpathAlloc(allocator, e.path);
        }
    }
    return null;
}

const AssetTarget = union(enum) {
    path: core.Token,
    name: core.Token,
    guid: core.Token,
};
