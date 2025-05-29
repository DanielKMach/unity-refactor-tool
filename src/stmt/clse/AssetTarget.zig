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
        if (!tkn.is(.keyword, "OF")) {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected_type = .keyword,
                    .expected_value = "OF",
                },
            });
        }
    } else {
        return .ERR(.{
            .unexpected_eof = .{
                .expected_type = .keyword,
                .expected_value = "OF",
            },
        });
    }

    var targets = std.BoundedArray(AssetTarget, 10){};
    while (true) {
        if (tokens.next()) |tkn| {
            if (tkn.is(.keyword, "GUID")) {
                if (tokens.next()) |tkn_guid| {
                    if ((tkn_guid.isType(.string) or tkn_guid.isType(.literal)) and GUID.isGUID(tkn_guid.value)) {
                        try targets.append(.{
                            .tpe = .guid,
                            .str = tkn_guid.value,
                        });
                    } else {
                        return .ERR(.{
                            .unexpected_token = .{
                                .found = tkn_guid,
                                .expected_type = .string,
                            },
                        });
                    }
                } else {
                    return .ERR(.{
                        .unexpected_eof = .{
                            .expected_type = .string,
                        },
                    });
                }
            } else if (tkn.isType(.literal) or tkn.isType(.string)) {
                if (isCSharpIdentifier(tkn.value)) {
                    try targets.append(.{
                        .tpe = .name,
                        .str = tkn.value,
                    });
                } else if (tkn.isType(.string)) {
                    try targets.append(.{
                        .tpe = .path,
                        .str = tkn.value,
                    });
                } else {
                    return .ERR(.{
                        .unexpected_token = .{
                            .found = tkn,
                            .expected_type = .string,
                        },
                    });
                }
            } else {
                return .ERR(.{
                    .unexpected_token = .{
                        .found = tkn,
                        .expected_type = .string,
                    },
                });
            }
        } else {
            return .ERR(.{
                .unexpected_eof = .{
                    .expected_type = .string,
                },
            });
        }

        if (tokens.peek(1)) |comma| {
            if (comma.is(.operator, ",")) {
                _ = tokens.next();
                continue;
            }
        }
        break;
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
