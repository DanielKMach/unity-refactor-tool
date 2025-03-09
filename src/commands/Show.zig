const std = @import("std");
const libyaml = @cImport(@cInclude("yaml.h"));
const errors = @import("../errors.zig");
const log = std.log.scoped(.show_command);

const This = @This();
const Scanner = @import("../Scanner.zig");
const Tokenizer = @import("../Tokenizer.zig");
const RuntimeData = @import("../RuntimeData.zig");
const InTarget = @import("InTarget.zig");
const AssetTarget = @import("AssetTarget.zig");

const uses_files = &.{ ".prefab", ".unity" };
const refs_files = &.{ ".prefab", ".unity", ".asset" };

exts: []const []const u8,
of: AssetTarget,
in: InTarget,

pub fn parse(tokens: *Tokenizer.TokenIterator) !errors.CompilerError(This) {
    if (tokens.next()) |tkn| {
        if (!tkn.is(.keyword, "SHOW")) {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected_type = .keyword,
                    .expected_value = "SHOW",
                },
            });
        }
    } else {
        return .ERR(.{
            .unexpected_eof = .{
                .expected_type = .keyword,
                .expected_value = "SHOW",
            },
        });
    }

    var exts: []const []const u8 = undefined;
    var of: ?AssetTarget = null;
    var in: ?InTarget = null;

    if (tokens.next()) |tkn| {
        if (tkn.is(.literal, "refs")) {
            exts = refs_files;
        } else if (tkn.is(.literal, "uses")) {
            exts = uses_files;
        } else {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected_type = .literal,
                    .expected_value = "refs",
                },
            });
        }
    } else {
        return .ERR(.{
            .unexpected_eof = .{
                .expected_type = .literal,
                .expected_value = "refs",
            },
        });
    }

    while (tokens.peek(0)) |tkn| {
        if (of == null and tkn.is(.keyword, "OF")) {
            const res = try AssetTarget.parse(tokens);
            if (res.isErr()) |err| return .ERR(err);
            of = res.ok;
        } else if (in == null and tkn.is(.keyword, "IN")) {
            const res = try InTarget.parse(tokens);
            if (res.isErr()) |err| return .ERR(err);
            in = res.ok;
        } else {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected_type = .keyword,
                },
            });
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
        .exts = exts,
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

    var searchData = SearchData{
        .cmd = &self,
        .guid = guid,
        .data = data,
    };

    var scanner = try Scanner.init(dir, search, data.allocator);
    defer scanner.deinit();

    try scanner.scan(&searchData);

    std.debug.print("\r\n", .{});
    return .OK(void{});
}

fn search(self: *anyopaque, entry: std.fs.Dir.Walker.Entry) !void {
    if (entry.kind != .file) return;

    const data: *SearchData = @alignCast(@ptrCast(self));
    for (data.cmd.exts) |ext| {
        if (std.mem.endsWith(u8, entry.path, ext)) break;
    } else return;

    var file = entry.dir.openFile(entry.basename, .{ .mode = .read_only }) catch |err| {
        log.warn("Error ({s}) opening file: '{s}'", .{ @errorName(err), entry.path });
        return;
    };
    defer file.close();

    const reader = file.reader();
    main: while (true) {
        try reader.skipUntilDelimiterOrEof(data.guid[0]);
        for (1..data.guid.len) |i| {
            const c = reader.readByte() catch |err| {
                data.logMtx.lock();
                defer data.logMtx.unlock();
                switch (err) {
                    error.EndOfStream => void{},
                    else => log.warn("Error ({s}) reading file: '{s}'", .{ @errorName(err), entry.path }),
                }
                break :main;
            };
            if (c != data.guid[i]) break;
        } else {
            data.logMtx.lock();
            defer data.logMtx.unlock();
            std.debug.print("{s}\r\n", .{entry.path});
            break;
        }
    }

    data.logMtx.lock();
    defer data.logMtx.unlock();
    data.fileCount += 1;
    std.debug.print("{d} files scanned\r", .{data.fileCount});
}

const SearchData = struct {
    cmd: *const This,
    data: RuntimeData,
    guid: []const u8,
    fileCount: usize = 0,
    logMtx: std.Thread.Mutex = .{},
};

pub fn getGUID(asset: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const metaPath = try std.mem.concat(allocator, u8, &.{ asset, ".meta" });
    defer allocator.free(metaPath);

    var file = try std.fs.cwd().openFile(metaPath, .{ .mode = .read_only });
    const contents = try file.readToEndAlloc(allocator, 4096);
    defer allocator.free(contents);

    var parser: libyaml.yaml_parser_t = undefined;
    _ = libyaml.yaml_parser_initialize(&parser);
    defer libyaml.yaml_parser_delete(&parser);

    libyaml.yaml_parser_set_input_string(&parser, contents.ptr, contents.len);

    var guid: []const u8 = undefined;

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
                guid = try allocator.dupe(u8, scalar);
                break;
            } else {
                next_guid = std.mem.eql(u8, scalar, "guid");
                continue;
            }
        }

        done = event.type == libyaml.YAML_STREAM_END_EVENT;
    }

    if (guid.len != 32) {
        return error.InvalidMetaFile;
    }

    return guid;
}
