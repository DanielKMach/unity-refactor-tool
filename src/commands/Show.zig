const std = @import("std");
const yaml = @import("yaml");
const errors = @import("../errors.zig");
const log = std.log.scoped(.show_command);

const Tokenizer = @import("../Tokenizer.zig");
const CompilerError = errors.CompilerError(This);
const RuntimeError = errors.RuntimeError(void);
const This = @This();

mode: Mode,
of: []const u8,
in: ?[]const u8,

const Mode = enum {
    refs,
    uses,
};

pub fn parse(tokens: Tokenizer.TokenIterator) !CompilerError {
    if (tokens[0].type != .keyword or !std.mem.eql(u8, tokens[0].value, "SHOW"))
        return CompilerError.err(.{ .unknown_command = void{} });

    var mode: Mode = .refs;
    if (std.mem.eql(u8, tokens[1].value, "refs")) {
        mode = .refs;
    } else if (std.mem.eql(u8, tokens[1].value, "uses")) {
        mode = .uses;
    } else {
        return CompilerError.err(.{
            .unexpected_token = .{
                .found = tokens[1],
                .expected = Tokenizer.Token.new(.literal, "refs"),
            },
        });
    }

    if (tokens[2].type != .keyword or !std.mem.eql(u8, tokens[2].value, "OF"))
        return CompilerError.err(.{
            .unexpected_token = .{
                .found = tokens[2],
                .expected = Tokenizer.Token.new(.keyword, "OF"),
            },
        });

    if (tokens[3].type != .literal_string)
        return CompilerError.err(.{
            .unexpected_token_type = .{
                .found = tokens[3],
                .expected = .literal_string,
            },
        });

    const of: []const u8 = tokens[3].value;

    var in: ?[]const u8 = null;
    if (tokens.len > 4 and tokens[4].type == .keyword and std.mem.eql(u8, tokens[4].value, "IN")) {
        in = tokens[5].value;
    }

    return CompilerError.ok(.{
        .mode = mode,
        .of = of,
        .in = in,
    });
}

pub fn run(self: This, alloc: std.mem.Allocator) !RuntimeError {
    const path = if (self.in) |in| in else ".";

    var dir = try std.fs.cwd().openDir(path, .{ .iterate = true, .access_sub_paths = true });
    defer dir.close();

    const guid = getGUID(self.of, alloc) catch return RuntimeError.err(.{
        .invalid_asset = .{ .path = self.of },
    });
    defer alloc.free(guid);

    std.debug.print("Locating: {s}\r\n", .{guid});

    var files = try dir.walk(alloc);
    defer files.deinit();

    var fileCount: usize = 0;

    while (try files.next()) |e| {
        if (e.kind != .file or !std.mem.endsWith(u8, e.path, ".prefab"))
            continue;

        var file = e.dir.openFile(e.basename, .{ .mode = .read_only }) catch |err| {
            log.warn("Error ({s}) opening file: {s}", .{ @errorName(err), e.path });
            continue;
        };
        defer file.close();

        const reader = file.reader();
        const buf = try alloc.alloc(u8, guid.len - 1);
        defer alloc.free(buf);
        while (true) {
            try reader.skipUntilDelimiterOrEof(guid[0]);
            const c = reader.read(buf) catch |err| {
                log.warn("Error ({s}) reading file: {s}", .{ @errorName(err), e.path });
                break;
            };
            if (c == 0) break;
            if (c == guid.len and std.mem.eql(u8, buf, guid[1..])) {
                log.info("{s}", .{e.basename});
                break;
            }
        }

        fileCount += 1;
        std.debug.print("{d} files scanned\r", .{fileCount});
    }

    std.debug.print("\r\n", .{});
    return RuntimeError.ok(void{});
}

pub fn getGUID(asset: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const metaPath = try std.mem.concat(allocator, u8, &.{ asset, ".meta" });
    defer allocator.free(metaPath);

    var file = try std.fs.cwd().openFile(metaPath, .{ .mode = .read_only });
    const contents = try file.readToEndAlloc(allocator, 4096);
    defer allocator.free(contents);

    var metaYaml = try yaml.Yaml.load(allocator, contents);
    defer metaYaml.deinit();

    const meta = try metaYaml.parse(Meta);
    return try allocator.dupe(u8, meta.guid);
}

const Meta = struct {
    guid: []const u8,
};
