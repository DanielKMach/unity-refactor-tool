const std = @import("std");
const core = @import("root");
const errors = core.errors;
const log = std.log.scoped(.show_command);

const This = @This();
const Tokenizer = core.language.Tokenizer;
const Scanner = core.runtime.Scanner;
const RuntimeData = core.runtime.RuntimeData;
const InTarget = core.cmds.sub.InTarget;
const AssetTarget = core.cmds.sub.AssetTarget;

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

    var searchData = Search{
        .cmd = &self,
        .guid = guid,
        .data = data,
    };

    var scanner = try Scanner(Search).init(dir, &Search.search, Search.filter, data.allocator);
    defer scanner.deinit();

    const start = std.time.milliTimestamp();

    try scanner.scan(&searchData);

    const time = std.time.milliTimestamp() - start;

    if (data.verbose) {
        std.debug.print("Scanned {d} files in {d} milliseconds \r\n", .{ searchData.fileCount, time });
    }
    return .OK(void{});
}

const Search = struct {
    cmd: *const This,
    data: RuntimeData,
    guid: []const u8,
    fileCount: usize = 0,
    logMtx: std.Thread.Mutex = .{},

    fn filter(self: *Search, entry: std.fs.Dir.Walker.Entry) ?std.fs.File {
        if (entry.kind != .file) return null;

        for (self.cmd.exts) |ext| {
            if (std.mem.endsWith(u8, entry.path, ext)) break;
        } else return null;

        return entry.dir.openFile(entry.basename, .{ .mode = .read_only }) catch |err| {
            log.warn("Error ({s}) opening file: '{s}'", .{ @errorName(err), entry.path });
            return null;
        };
    }

    fn search(self: *Search, entry: std.fs.Dir.Walker.Entry, file: std.fs.File) !void {
        var bufrdr = std.io.bufferedReader(file.reader());
        const reader = bufrdr.reader();

        main: while (true) {
            try reader.skipUntilDelimiterOrEof(self.guid[0]);
            for (1..self.guid.len) |i| {
                const c = reader.readByte() catch |err| {
                    self.logMtx.lock();
                    defer self.logMtx.unlock();
                    switch (err) {
                        error.EndOfStream => void{},
                        else => log.warn("Error ({s}) reading file: '{s}'", .{ @errorName(err), entry.path }),
                    }
                    break :main;
                };
                if (c != self.guid[i]) break;
            } else {
                self.logMtx.lock();
                defer self.logMtx.unlock();
                try self.data.out.print("{s}\r\n", .{entry.path});
                break;
            }
        }

        self.logMtx.lock();
        defer self.logMtx.unlock();
        self.fileCount += 1;
        if (self.data.verbose) {
            try self.data.out.print("{d} files scanned\r", .{self.fileCount});
        }
    }
};
