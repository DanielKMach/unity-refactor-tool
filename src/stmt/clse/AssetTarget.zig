const std = @import("std");
const core = @import("root");
const results = core.results;

const This = @This();
const Tokenizer = core.language.Tokenizer;
const Yaml = core.runtime.Yaml;
const GUID = core.runtime.GUID;

targets: std.BoundedArray(AssetTarget, 10),

pub fn parse(tokens: *Tokenizer.TokenIterator) !results.ParseResult(This) {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (tokens.next()) |tkn| {
        if (!tkn.is(.OF)) {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected = &.{.OF},
                },
            });
        }
    } else {
        return .ERR(.{
            .unexpected_eof = .{
                .expected = &.{.OF},
            },
        });
    }

    var targets = std.BoundedArray(AssetTarget, 10){};
    while (true) {
        if (tokens.next()) |tkn| {
            if (tkn.is(.GUID)) {
                if (tokens.next()) |guid| {
                    if (guid.is(.string)) {
                        if (GUID.isGUID(guid.value.string)) {
                            try targets.append(.{
                                .tpe = .guid,
                                .str = guid.value.string,
                            });
                        } else {
                            return .ERR(.{
                                .invalid_guid = .{
                                    .token = guid,
                                    .guid = guid.value.string,
                                },
                            });
                        }
                    } else {
                        return .ERR(.{
                            .unexpected_token = .{
                                .found = guid,
                                .expected = &.{.string},
                            },
                        });
                    }
                } else {
                    return .ERR(.{
                        .unexpected_eof = .{
                            .expected = &.{.string},
                        },
                    });
                }
            } else if (tkn.is(.literal)) {
                if (isCSharpIdentifier(tkn.value.literal)) {
                    try targets.append(.{
                        .tpe = .name,
                        .str = tkn.value.literal,
                    });
                } else {
                    return .ERR(.{
                        .invalid_csharp_identifier = .{
                            .token = tkn,
                            .identifier = tkn.value.literal,
                        },
                    });
                }
            } else if (tkn.is(.string)) {
                if (isCSharpIdentifier(tkn.value.string)) {
                    try targets.append(.{
                        .tpe = .name,
                        .str = tkn.value.string,
                    });
                } else {
                    try targets.append(.{
                        .tpe = .path,
                        .str = tkn.value.string,
                    });
                }
            } else {
                return .ERR(.{
                    .unexpected_token = .{
                        .found = tkn,
                        .expected = &.{ .GUID, .literal, .string },
                    },
                });
            }
        } else {
            return .ERR(.{
                .unexpected_eof = .{
                    .expected = &.{ .GUID, .literal, .string },
                },
            });
        }

        if (tokens.peek(1)) |comma| {
            if (!comma.is(.comma)) break;
        }
        _ = tokens.next(); // Consume the comma
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
