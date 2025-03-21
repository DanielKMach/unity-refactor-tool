const std = @import("std");
const core = @import("root");
const Yaml = core.Yaml;
const errors = core.errors;
const log = std.log.scoped(.rename_command);

const This = @This();
const Scanner = core.Scanner;
const Tokenizer = core.language.Tokenizer;
const RuntimeData = core.RuntimeData;
const InTarget = core.cmds.sub.InTarget;
const AssetTarget = core.cmds.sub.AssetTarget;

const files = &.{ ".prefab", ".unity", ".asset" };

old_name: []const u8,
new_name: []const u8,
of: AssetTarget,
in: InTarget,

pub fn parse(tokens: *Tokenizer.TokenIterator) !errors.CompilerError(This) {
    if (tokens.next()) |tkn| {
        if (!tkn.is(.keyword, "RENAME")) {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected_type = .keyword,
                    .expected_value = "RENAME",
                },
            });
        }
    } else {
        return .ERR(.{
            .unexpected_eof = .{
                .expected_type = .keyword,
                .expected_value = "RENAME",
            },
        });
    }

    var old_name: []const u8 = undefined;
    var new_name: []const u8 = undefined;
    var of: ?AssetTarget = null;
    var in: ?InTarget = null;

    if (tokens.next()) |tkn| {
        if (tkn.isType(.literal) or tkn.isType(.literal_string)) {
            old_name = tkn.value;
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

    if (tokens.next()) |tkn| {
        if (!tkn.is(.keyword, "FOR")) {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected_type = .keyword,
                    .expected_value = "FOR",
                },
            });
        }
    } else {
        return .ERR(.{
            .unexpected_eof = .{
                .expected_type = .keyword,
                .expected_value = "FOR",
            },
        });
    }

    if (tokens.next()) |tkn| {
        if (tkn.isType(.literal) or tkn.isType(.literal_string)) {
            new_name = tkn.value;
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

    while (tokens.peek(1)) |tkn| {
        if (of == null and tkn.is(.keyword, "OF")) {
            const res = try AssetTarget.parse(tokens);
            if (res.isErr()) |err| return .ERR(err);
            of = res.ok;
        } else if (in == null and tkn.is(.keyword, "IN")) {
            const res = try InTarget.parse(tokens);
            if (res.isErr()) |err| return .ERR(err);
            in = res.ok;
        } else {
            break;
        }
    }

    if (of == null)
        return .ERR(.{
            .unexpected_eof = .{
                .expected_type = .keyword,
                .expected_value = "OF",
            },
        });

    return .OK(.{
        .old_name = old_name,
        .new_name = new_name,
        .of = of.?,
        .in = in orelse InTarget.default,
    });
}

pub fn run(self: This, data: RuntimeData) !errors.RuntimeError(void) {
    const in = self.in;
    const of = self.of;

    var dir = in.openDir(data, .{ .iterate = true, .access_sub_paths = true }) catch {
        return .ERR(.{
            .invalid_path = .{ .path = in.dir },
        });
    };
    defer dir.close();

    const guid = of.getGUID(data) catch return .ERR(.{
        .invalid_asset = .{ .path = of.str },
    });
    defer data.allocator.free(guid);

    var buf = std.ArrayList(u8).init(data.allocator);
    defer buf.deinit();

    const writer = buf.writer();

    const show = core.cmds.Show{
        .exts = &.{ ".unity", ".prefab", ".asset" },
        .of = of,
        .in = in,
    };

    const rundata = core.RuntimeData{
        .allocator = data.allocator,
        .out = writer.any(),
        .cwd = data.cwd,
        .query = data.query,
        .verbose = false,
    };

    var res = try show.run(rundata);
    if (res.isErr()) |e| {
        return .ERR(e);
    }

    var start: usize = 0;
    for (0..buf.items.len) |i| {
        if (buf.items[i] == '\n') {
            const trimmed_name = std.mem.trim(u8, buf.items[start..i], " \t\r\n");
            const path = std.fs.path.join(data.allocator, &.{ show.in.dir, trimmed_name }) catch |err| {
                log.warn("Error joining path: '{s}'", .{@errorName(err)});
                return .ERR(.{ .invalid_path = .{ .path = show.in.dir } });
            };
            start = i + 1;
            if (path.len == 0) continue;

            const file = data.cwd.openFile(path, .{ .mode = .read_only }) catch |err| {
                log.warn("Error ({s}) opening file: '{s}'", .{ @errorName(err), path });
                continue;
            };

            try self.scopeAndReplace(data, file, guid);
        }
    }

    return .OK(void{});
}

pub fn scopeAndReplace(self: This, data: RuntimeData, file: std.fs.File, guid: []const u8) !void {
    const content = try file.readToEndAlloc(data.allocator, std.math.maxInt(u16));
    defer data.allocator.free(content);

    const docs = try dissectAsset(content, data.allocator);
    defer data.allocator.free(docs);

    var modified = std.ArrayList(?[]u8).init(data.allocator);
    defer modified.deinit();

    for (docs) |doc| {
        var buf = try data.allocator.alloc(u8, doc.len * 2);

        var yaml = Yaml.init(.{ .string = doc }, .{ .string = &buf }, data.allocator);

        if (try yaml.matchGUID(guid)) {
            try yaml.rename(self.old_name, self.new_name);
            try modified.append(buf);
        } else {
            try modified.append(null);
        }
    }

    const new_content = try consolidateAsset(content, docs, modified.items, data.allocator);

    log.info("'{s}' updated to '{s}'", .{ content, new_content });
}

fn consolidateAsset(content: []u8, parts: [][]u8, modified: []?[]u8, allocator: std.mem.Allocator) std.mem.Allocator.Error![]u8 {
    var all = std.ArrayList([]u8).init(allocator);
    defer all.deinit();

    std.debug.assert(parts.len == modified.len);

    if (parts.len == 0) {
        return allocator.dupe(u8, content);
    }

    if (parts[0].ptr != content.ptr) {
        try all.append(content[0 .. parts[0].ptr - content.ptr]);
    }

    for (0..parts.len) |i| {
        if (i < modified.len and modified[i] != null) {
            try all.append(modified[i].?);
        } else {
            try all.append(parts[i]);
        }

        if (i + 1 < parts.len) {
            const start_index = (parts[i].ptr + parts[i].len) - content.ptr;
            const end_index = parts[i + 1].ptr - content.ptr;
            try all.append(content[start_index..end_index]);
        } else if (@as(usize, @intFromPtr(parts[i].ptr)) + parts[i].len < @as(usize, @intFromPtr(content.ptr)) + content.len) {
            const start_index = (parts[i].ptr + parts[i].len) - content.ptr;
            try all.append(content[start_index..content.len]);
        }
    }

    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();
    const writer = buf.writer();
    for (all.items) |item| {
        _ = try writer.write(item);
    }

    return buf.toOwnedSlice();
}

fn dissectAsset(content: []u8, allocator: std.mem.Allocator) std.mem.Allocator.Error![][]u8 {
    var docs = std.ArrayList([]u8).init(allocator);
    defer docs.deinit();

    var i: usize = 0;
    var start: usize = 0;
    while (i < content.len) : (i += 1) {
        if (content[i] == '%') {
            while (content[i] != '\n' and i < content.len) {
                i += 1;
            }
            if (content[i + 1] == '\r' and i < content.len) {
                i += 1;
            }
            start = i + 1;
        }
        if (content[i] == '-' and content[i + 1] == '-') {
            if (start < i) {
                const doc = content[start..i];
                try docs.append(doc);
            }
            while (i < content.len and content[i] != '\n') {
                i += 1;
            }
            if (i < content.len and content[i + 1] == '\r') {
                i += 1;
            }
            start = i + 1;
        }
    }

    if (start < i) {
        const doc = content[start..i];
        try docs.append(doc);
    }

    return docs.toOwnedSlice();
}
