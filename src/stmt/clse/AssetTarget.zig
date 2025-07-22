const std = @import("std");
const core = @import("core");
const results = core.results;

const This = @This();
const Tokenizer = core.parsing.Tokenizer;
const Yaml = core.runtime.Yaml;
const GUID = core.runtime.GUID;

targets: []AssetTarget,

pub fn parse(tokens: *Tokenizer.TokenIterator, env: core.parsing.ParsetimeEnv) anyerror!results.ParseResult(This) {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.OF)) return .ERR(.unknown);

    var targets = std.ArrayList(AssetTarget).init(env.allocator);
    defer targets.deinit();

    while (true) {
        switch (tokens.next().value) {
            .GUID => switch (tokens.next().value) {
                .string => |guid_str| if (GUID.isGUID(guid_str)) {
                    try targets.append(.{
                        .guid = try env.allocator.dupe(u8, guid_str),
                    });
                } else {
                    return .ERR(.{
                        .invalid_guid = .{
                            .token = tokens.peek(0),
                        },
                    });
                },
                else => return .ERR(.{
                    .unexpected_token = .{
                        .found = tokens.peek(0),
                        .expected = &.{.string},
                    },
                }),
            },
            .literal => |lit| if (isCSharpIdentifier(lit)) {
                try targets.append(.{
                    .name = try env.allocator.dupe(u8, lit),
                });
            } else {
                return .ERR(.{
                    .invalid_csharp_identifier = .{
                        .token = tokens.peek(0),
                    },
                });
            },
            .string => |str| if (isCSharpIdentifier(str)) {
                try targets.append(.{
                    .name = try env.allocator.dupe(u8, str),
                });
            } else {
                try targets.append(.{
                    .path = try env.allocator.dupe(u8, str),
                });
            },
            else => return .ERR(.{
                .unexpected_token = .{
                    .found = tokens.peek(0),
                    .expected = &.{ .GUID, .literal, .string },
                },
            }),
        }

        if (!tokens.match(.comma)) break;
    }

    return .OK(.{
        .targets = try targets.toOwnedSlice(),
    });
}

pub fn cleanup(self: This, allocator: std.mem.Allocator) void {
    for (self.targets) |target| {
        switch (target) {
            .guid => |guid| allocator.free(guid),
            .name => |name| allocator.free(name),
            .path => |path| allocator.free(path),
        }
    }
    allocator.free(self.targets);
}

pub fn getGUID(self: This, dir: std.fs.Dir, allocator: std.mem.Allocator) !results.RuntimeResult([]GUID) {
    core.profiling.begin(getGUID);
    defer core.profiling.stop();

    var guids = std.ArrayList(GUID).init(allocator);
    errdefer {
        for (guids.items) |guid| guid.deinit(allocator);
        guids.deinit();
    }

    for (self.targets) |target| {
        try guids.append(switch (target) {
            .guid => |guid| try GUID.init(guid, null, allocator),
            .name => |comp| blk: {
                const path = try searchComponent(comp, dir, allocator) orelse {
                    return .ERR(.{ .invalid_asset = .{ .path = comp } });
                };
                defer allocator.free(path);

                break :blk GUID.fromFile(path, allocator) catch {
                    return .ERR(.{ .invalid_asset = .{ .path = comp } });
                };
            },
            .path => |path| blk: {
                const abs_path = try dir.realpathAlloc(allocator, path);
                defer allocator.free(abs_path);

                break :blk GUID.fromFile(abs_path, allocator) catch {
                    return .ERR(.{ .invalid_asset = .{ .path = path } });
                };
            },
        });
    }
    return .OK(try guids.toOwnedSlice());
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
    path: []const u8,
    name: []const u8,
    guid: []const u8,
};
