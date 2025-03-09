const std = @import("std");
const libyaml = @cImport(@cInclude("yaml.h"));
const errors = @import("../errors.zig");

const This = @This();
const Tokenizer = @import("../Tokenizer.zig");
const RuntimeData = @import("../RuntimeData.zig");

tpe: Type,
str: []const u8,

pub fn parse(tokens: *Tokenizer.TokenIterator) !errors.CompilerError(This) {
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

    var tpe: Type = undefined;
    var str: []const u8 = undefined;
    if (tokens.next()) |tkn| {
        if (tkn.is(.keyword, "GUID")) {
            if (tokens.next()) |tkn_guid| {
                if ((tkn_guid.isType(.literal_string) or tkn_guid.isType(.literal)) and isGUID(tkn_guid.value)) {
                    tpe = .guid;
                    str = tkn_guid.value;
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
                tpe = .name;
                str = tkn.value;
            } else if (tkn.isType(.literal_string)) {
                tpe = .path;
                str = tkn.value;
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

    return .OK(.{
        .tpe = tpe,
        .str = str,
    });
}

pub fn getGUID(self: This, data: RuntimeData) ![]u8 {
    return switch (self.tpe) {
        .guid => try data.allocator.dupe(u8, self.str),
        .name => blk: {
            const path = try searchComponent(self.str, data);
            defer data.allocator.free(path);

            const file = try data.cwd.openFile(path, .{});
            defer file.close();

            break :blk try scanMetafile(file, data.allocator);
        },
        .path => blk: {
            const metafile = try std.mem.concat(data.allocator, u8, &.{ self.str, ".meta" });
            defer data.allocator.free(metafile);

            const file = try data.cwd.openFile(metafile, .{ .mode = .read_only });
            defer file.close();

            break :blk try scanMetafile(file, data.allocator);
        },
    };
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
fn searchComponent(
    name: []const u8,
    data: RuntimeData,
) ![]u8 {
    var dir = data.cwd.openDir(".", .{ .iterate = true, .access_sub_paths = true }) catch {
        return error.InvalidPath;
    };
    defer dir.close();

    var walker = try dir.walk(data.allocator);
    defer walker.deinit();

    const targetName = try std.mem.concat(data.allocator, u8, &.{ name, ".cs.meta" });
    defer data.allocator.free(targetName);

    while (try walker.next()) |e| {
        if (std.mem.endsWith(u8, e.basename, targetName)) {
            return data.allocator.dupe(u8, e.path);
        }
    }
    return error.ComponentNotFound;
}

/// The return value is owned by the caller.
fn scanMetafile(file: std.fs.File, alloc: std.mem.Allocator) ![]u8 {
    const contents = try file.readToEndAlloc(alloc, 4096);
    defer alloc.free(contents);

    var parser: libyaml.yaml_parser_t = undefined;
    _ = libyaml.yaml_parser_initialize(&parser);
    defer libyaml.yaml_parser_delete(&parser);

    libyaml.yaml_parser_set_input_string(&parser, contents.ptr, contents.len);

    var guid: []u8 = undefined;

    var done: bool = false;
    var next_guid: bool = false;
    while (!done) {
        var event: libyaml.yaml_event_t = undefined;
        if (libyaml.yaml_parser_parse(&parser, &event) == 0) {
            return error.InvalidMetaFile;
        }
        defer libyaml.yaml_event_delete(&event);

        if (next_guid and event.type != libyaml.YAML_SCALAR_EVENT) {
            return error.InvalidMetaFile;
        }

        if (event.type == libyaml.YAML_SCALAR_EVENT) {
            const scalar = event.data.scalar.value[0..event.data.scalar.length];
            if (next_guid) {
                guid = try alloc.dupe(u8, scalar);
                break;
            } else {
                next_guid = std.mem.eql(u8, scalar, "guid");
                continue;
            }
        }

        done = event.type == libyaml.YAML_STREAM_END_EVENT;
    }

    if (guid.len != 32) {
        alloc.free(guid);
        return error.InvalidMetaFile;
    }

    return guid;
}

const Type = enum { path, guid, name };
