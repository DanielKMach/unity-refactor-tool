const std = @import("std");
const core = @import("core");

const This = @This();
const Stmt = core.Stmt;
const TokenIterator = core.Token.Iterator;
const Yaml = core.runtime.Yaml;
const GUID = core.runtime.GUID;

targets: []AssetTarget,

pub fn parse(tokens: *TokenIterator, env: Stmt.ParseEnv) Stmt.ParseError!This {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.OF)) return error.TokenMismatch;

    var targets = std.ArrayList(AssetTarget).empty;
    defer targets.deinit(env.allocator);

    while (true) {
        const tkn = try tokens.grabAny(&.{ .GUID, .literal, .string }, env.diag);
        switch (tkn.value) {
            .GUID => {
                const guid_tkn = try tokens.grab(.string, env.diag);
                if (GUID.isGUID(guid_tkn.value.string)) {
                    try targets.append(env.allocator, .{ .guid = guid_tkn });
                } else return env.err(.{ .invalid_guid = .{
                    .token = guid_tkn,
                } });
            },
            .literal => |lit| {
                if (isCSharpIdentifier(lit)) {
                    try targets.append(env.allocator, .{ .name = tkn });
                } else return env.err(.{ .invalid_csharp_identifier = .{
                    .token = tkn,
                } });
            },
            .string => |str| {
                if (!std.fs.path.isAbsolute(str)) {
                    try targets.append(env.allocator, .{ .path = tkn });
                } else return env.err(.{ .absolute_path = .{
                    .token = tkn,
                } });
            },
            else => unreachable,
        }

        if (!tokens.match(.comma)) break;
    }

    return .{ .targets = try targets.toOwnedSlice(env.allocator) };
}

pub fn cleanup(self: This, allocator: std.mem.Allocator) void {
    allocator.free(self.targets);
}

pub fn getGUID(self: This, filter: Filter, env: Stmt.RunEnv) Stmt.RunError![]GUID {
    core.profiling.begin(getGUID);
    defer core.profiling.stop();

    var guids = std.ArrayList(GUID).empty;
    defer guids.deinit(env.allocator);

    for (self.targets) |target| {
        try guids.append(env.allocator, switch (target) {
            .guid => |guid| try GUID.fromText(guid.value.string),
            .name => |name| blk: {
                const path = try searchComponent(name.value.literal, env.proj, env.allocator) orelse {
                    return env.err(.{ .invalid_asset = .{ .path = name.loc } });
                };
                defer env.allocator.free(path);

                std.debug.assert(validatePath(path, filter));

                break :blk GUID.fromFile(path, env.allocator) catch |err| switch (err) {
                    error.InvalidMetaFile, error.FileNotFound => {
                        return env.err(.{ .invalid_asset = .{ .path = name.loc } });
                    },
                    else => |e| return e,
                };
            },
            .path => |path| blk: {
                const abs_path = env.proj.root.realpathAlloc(env.allocator, path.value.string) catch |e| switch (e) {
                    error.FileNotFound => {
                        return env.err(.{ .invalid_asset = .{ .path = path.loc } });
                    },
                    else => |err| return err,
                };
                defer env.allocator.free(abs_path);

                if (!validatePath(abs_path, filter)) return env.err(.{ .invalid_target_asset = .{
                    .filter = filter,
                    .location = path.loc,
                } });

                break :blk GUID.fromFile(abs_path, env.allocator) catch |e| switch (e) {
                    error.InvalidMetaFile, error.FileNotFound => {
                        return env.err(.{ .invalid_asset = .{ .path = path.loc } });
                    },
                    else => |err| return err,
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

fn searchComponent(name: []const u8, proj: core.Project, allocator: std.mem.Allocator) !?[]u8 {
    core.profiling.begin(searchComponent);
    defer core.profiling.stop();

    const filename = try std.mem.concat(allocator, u8, &.{ name, ".cs.meta" });
    defer allocator.free(filename);

    return try proj.find(@ptrCast(&filename), &findComponent, allocator);
}

fn findComponent(data: *const anyopaque, e: std.fs.Dir.Walker.Entry, _: std.mem.Allocator) core.Project.SearchError!bool {
    const filename = @as(*const []const u8, @ptrCast(@alignCast(data))).*;
    return std.mem.eql(u8, e.basename, filename);
}

fn validatePath(path: []const u8, filter: Filter) bool {
    const ends = std.mem.endsWith;
    return switch (filter) {
        .prefabs_and_components => ends(u8, path, ".prefab.meta") or ends(u8, path, ".prefab") or ends(u8, path, ".cs.meta") or ends(u8, path, ".cs"),
        .components_only => ends(u8, path, ".cs.meta") or ends(u8, path, ".cs"),
        .any => true,
    };
}

const AssetTarget = union(enum) {
    path: core.Token,
    name: core.Token,
    guid: core.Token,
};

pub const Filter = enum {
    any,
    prefabs_and_components,
    components_only,
};
