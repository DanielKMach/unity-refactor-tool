const std = @import("std");
const yaml = @import("yaml");
const Tokenizer = @import("Tokenizer.zig");

const This = @This();

const log = std.log.scoped(.interpreter);

allocator: std.mem.Allocator,

pub fn interpret(self: *This, tokens: Tokenizer.TokenIterator) !void {
    _ = self.allocator;
    for (tokens) |tkn| {
        log.info("{s} => '{s}'", .{ @tagName(tkn.type), tkn.value });
    }

    const data = try parseShowCommandData(tokens);
    try self.runShowCommand(data);
}

const ShowCommandMode = enum {
    refs,
    uses,
};

const ShowCommandData = struct {
    mode: ShowCommandMode,
    of: []const u8,
    in: ?[]const u8,
};

fn parseShowCommandData(tokens: Tokenizer.TokenIterator) !ShowCommandData {
    if (tokens[0].type != .Keyword or !std.mem.eql(u8, tokens[0].value, "SHOW"))
        return error.UnknownCommand;

    var mode: ShowCommandMode = .refs;
    if (std.mem.eql(u8, tokens[1].value, "refs")) {
        mode = .refs;
    } else if (std.mem.eql(u8, tokens[1].value, "uses")) {
        mode = .uses;
    } else {
        return error.InvalidMode;
    }

    const of: []const u8 = tokens[3].value;

    var in: ?[]const u8 = null;
    if (tokens.len > 4 and tokens[4].type == .Keyword and std.mem.eql(u8, tokens[4].value, "IN")) {
        in = tokens[5].value;
    }

    return ShowCommandData{ .mode = mode, .of = of, .in = in };
}

fn runShowCommand(self: *This, data: ShowCommandData) !void {
    var dir: std.fs.Dir = undefined;
    defer dir.close();

    if (data.in) |in| {
        dir = try std.fs.cwd().openDir(in, .{ .iterate = true, .access_sub_paths = true });
    } else {
        dir = try std.fs.cwd().openDir(".", .{ .iterate = true, .access_sub_paths = true });
    }

    const guid = try getGUID(data.of, self.allocator);
    log.info("Locating: {s}", .{guid});
    defer self.allocator.free(guid);

    var files = try dir.walk(self.allocator);
    defer files.deinit();

    var fileCount: usize = 0;

    while (try files.next()) |e| {
        if (e.kind != .file or !std.mem.endsWith(u8, e.path, ".prefab"))
            continue;

        var file = try e.dir.openFile(e.basename, .{ .mode = .read_only });
        defer file.close();

        const reader = file.reader();
        const buf = try self.allocator.alloc(u8, guid.len - 1);
        defer self.allocator.free(buf);
        while (true) {
            try reader.skipUntilDelimiterOrEof(guid[0]);
            const c = try reader.read(buf);
            if (c == 0) break;
            if (c == guid.len and std.mem.eql(u8, buf, guid[1..])) {
                log.info("Found reference in {s}\r\n", .{e.basename});
                break;
            }
        }

        fileCount += 1;
        std.debug.print("\r{d} files scanned", .{fileCount});
    }
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
