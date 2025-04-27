const std = @import("std");
const core = @import("root");
const results = core.results;

const This = @This();
const Tokenizer = core.language.Tokenizer;
const Yaml = core.runtime.Yaml;

targets: std.BoundedArray(AssetTarget, 10),

pub fn parse(tokens: *Tokenizer.TokenIterator) !results.ParseResult(This) {
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
                    if ((tkn_guid.isType(.literal_string) or tkn_guid.isType(.literal)) and isGUID(tkn_guid.value)) {
                        try targets.append(.{
                            .tpe = .guid,
                            .str = tkn_guid.value,
                        });
                    } else {
                        return .ERR(.{
                            .unexpected_token = .{
                                .found = tkn_guid,
                                .expected_type = .literal_string,
                            },
                        });
                    }
                } else {
                    return .ERR(.{
                        .unexpected_eof = .{
                            .expected_type = .literal_string,
                        },
                    });
                }
            } else if (tkn.isType(.literal) or tkn.isType(.literal_string)) {
                if (isCSharpIdentifier(tkn.value)) {
                    try targets.append(.{
                        .tpe = .name,
                        .str = tkn.value,
                    });
                } else if (tkn.isType(.literal_string)) {
                    try targets.append(.{
                        .tpe = .path,
                        .str = tkn.value,
                    });
                } else {
                    return .ERR(.{
                        .unexpected_token = .{
                            .found = tkn,
                            .expected_type = .literal_string,
                        },
                    });
                }
            } else {
                return .ERR(.{
                    .unexpected_token = .{
                        .found = tkn,
                        .expected_type = .literal_string,
                    },
                });
            }
        } else {
            return .ERR(.{
                .unexpected_eof = .{
                    .expected_type = .literal_string,
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

pub fn getGUID(self: This, allocator: std.mem.Allocator, dir: std.fs.Dir) !results.RuntimeResult([][]u8) {
    var guids = std.ArrayList([]u8).init(allocator);
    errdefer {
        for (guids.items) |guid| allocator.free(guid);
        guids.deinit();
    }

    for (0..self.targets.len) |i| {
        const str = self.targets.buffer[i].str;
        const tpe = self.targets.buffer[i].tpe;
        try guids.append(switch (tpe) {
            .guid => try allocator.dupe(u8, str),
            .name => blk: {
                const path = searchComponent(str, allocator, dir) catch {
                    return .ERR(.{ .invalid_asset = .{ .path = str } });
                };
                defer allocator.free(path);

                const file = dir.openFile(path, .{}) catch {
                    return .ERR(.{ .invalid_asset = .{ .path = str } });
                };
                defer file.close();

                break :blk scanMetafileAlloc(file, allocator) catch {
                    return .ERR(.{ .invalid_asset = .{ .path = str } });
                };
            },
            .path => blk: {
                const metafile = try std.mem.concat(allocator, u8, &.{ str, ".meta" });
                defer allocator.free(metafile);

                const file = dir.openFile(metafile, .{ .mode = .read_only }) catch {
                    return .ERR(.{ .invalid_asset = .{ .path = str } });
                };
                defer file.close();

                break :blk scanMetafileAlloc(file, allocator) catch {
                    return .ERR(.{ .invalid_asset = .{ .path = str } });
                };
            },
        });
    }
    return .OK(try guids.toOwnedSlice());
}

fn isGUID(str: []const u8) bool {
    if (str.len != 32) return false;
    for (str) |c| {
        if (!std.ascii.isHex(c)) return false;
    }
    return true;
}

fn isCSharpIdentifier(str: []const u8) bool {
    if (str.len == 0) return false;
    if (!std.ascii.isAlphabetic(str[0]) and str[0] != '_') return false;
    for (str[1..]) |c| {
        if (!std.ascii.isAlphanumeric(c) and c != '_') return false;
    }
    return true;
}

/// The return value is owned by the caller.
fn searchComponent(name: []const u8, allocator: std.mem.Allocator, dir: std.fs.Dir) ![]u8 {
    var walker = try dir.walk(allocator);
    defer walker.deinit();

    const targetName = try std.mem.concat(allocator, u8, &.{ name, ".cs.meta" });
    defer allocator.free(targetName);

    while (try walker.next()) |e| {
        if (std.mem.eql(u8, e.basename, targetName)) {
            return allocator.dupe(u8, e.path);
        }
    }
    return error.ComponentNotFound;
}

pub fn scanMetafile(file: std.fs.File, buf: []u8, alloc: std.mem.Allocator) ![]u8 {
    std.debug.assert(buf.len >= 32);

    const contents = try file.readToEndAlloc(alloc, std.math.maxInt(u16));
    defer alloc.free(contents);

    var yaml = Yaml.init(.{ .string = contents }, null, alloc);

    const nullableGuid = try yaml.get(&.{"guid"}, buf);
    const guid = nullableGuid orelse return error.InvalidMetaFile;

    if (!isGUID(guid)) {
        return error.InvalidMetaFile;
    }

    return guid;
}

/// The return value is owned by the caller.
pub fn scanMetafileAlloc(file: std.fs.File, alloc: std.mem.Allocator) ![]u8 {
    var buf: [32]u8 = undefined;
    const guid = try scanMetafile(file, &buf, alloc);
    return try alloc.dupe(u8, guid);
}

const AssetTarget = struct {
    tpe: Type,
    str: []const u8,
};

const Type = enum { path, guid, name };
