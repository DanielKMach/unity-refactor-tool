const std = @import("std");
const core = @import("core");
const results = core.results;

const This = @This();
const Tokenizer = core.language.Tokenizer;
const Yaml = core.runtime.Yaml;
const GUID = core.runtime.GUID;

targets: std.BoundedArray(AssetTarget, 10),

pub fn parse(tokens: *Tokenizer.TokenIterator) anyerror!results.ParseResult(This) {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.OF)) return .ERR(.unknown);

    var targets = std.BoundedArray(AssetTarget, 10){};

    while (true) {
        switch (tokens.next().value) {
            .GUID => switch (tokens.next().value) {
                .string => |guid_str| if (GUID.isGUID(guid_str)) {
                    try targets.append(.{
                        .tpe = .guid,
                        .str = guid_str,
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
                    .tpe = .name,
                    .str = lit,
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
                    .tpe = .name,
                    .str = str,
                });
            } else {
                try targets.append(.{
                    .tpe = .path,
                    .str = str,
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
        .targets = targets,
    });
}

pub fn getGUID(self: This, dir: std.fs.Dir, allocator: std.mem.Allocator) !results.RuntimeResult([]GUID) {
    core.profiling.begin(getGUID);
    defer core.profiling.stop();

    var guids = std.ArrayList(GUID).init(allocator);
    errdefer {
        for (guids.items) |guid| guid.deinit(allocator);
        guids.deinit();
    }

    for (self.targets.slice()) |target| {
        const value = target.str;
        try guids.append(switch (target.tpe) {
            .guid => try GUID.init(value, null, allocator),
            .name => blk: {
                const path = try searchComponent(value, dir, allocator) orelse {
                    return .ERR(.{ .invalid_asset = .{ .path = value } });
                };
                defer allocator.free(path);

                break :blk GUID.fromFile(path, allocator) catch {
                    return .ERR(.{ .invalid_asset = .{ .path = value } });
                };
            },
            .path => blk: {
                const abs_path = try dir.realpathAlloc(allocator, value);
                defer allocator.free(abs_path);

                break :blk GUID.fromFile(abs_path, allocator) catch {
                    return .ERR(.{ .invalid_asset = .{ .path = value } });
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

const AssetTarget = struct {
    tpe: Type,
    str: []const u8,
};

const Type = enum { path, guid, name };
