const std = @import("std");
const yaml = @import("yaml");
const errors = @import("../errors.zig");
const log = std.log.scoped(.show_command);

const Tokenizer = @import("../Tokenizer.zig");
const CompilerError = errors.CompilerError(This);
const RuntimeError = errors.RuntimeError(void);
const This = @This();
const Scanner = @import("../Scanner.zig");

const uses_files = &.{ ".prefab", ".unity" };
const refs_files = &.{ ".prefab", ".unity", ".asset" };

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

    var searchData = SearchData{
        .cmd = &self,
        .guid = guid,
        .allocator = alloc,
    };

    var scanner = try Scanner.init(dir, search, alloc);
    defer scanner.deinit();

    try scanner.scan(&searchData);

    std.debug.print("\r\n", .{});
    return RuntimeError.ok(void{});
}

fn search(self: *anyopaque, entry: std.fs.Dir.Walker.Entry) !void {
    if (entry.kind != .file) return;

    const data: *SearchData = @alignCast(@ptrCast(self));
    const extensions: []const []const u8 = switch (data.cmd.mode) {
        .refs => refs_files,
        .uses => uses_files,
    };

    for (extensions) |ext| {
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
    allocator: std.mem.Allocator,
    guid: []const u8,
    fileCount: usize = 0,
    logMtx: std.Thread.Mutex = std.Thread.Mutex{},
};

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
