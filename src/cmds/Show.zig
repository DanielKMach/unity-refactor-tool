const std = @import("std");
const core = @import("root");
const results = core.results;
const log = std.log.scoped(.show_command);

const This = @This();
const Tokenizer = core.language.Tokenizer;
const Yaml = core.runtime.Yaml;
const ComponentIterator = core.runtime.ComponentIterator;
const Scanner = core.runtime.Scanner;
const RuntimeData = core.runtime.RuntimeData;
const InTarget = core.cmds.sub.InTarget;
const AssetTarget = core.cmds.sub.AssetTarget;

pub const SearchMode = enum {
    refs,
    direct_uses,
    indirect_uses,
};

const uses_files = &.{ ".prefab", ".unity" };
const refs_files = &.{ ".prefab", ".unity", ".asset", ".mat" };

mode: SearchMode,
of: AssetTarget,
in: InTarget,

pub fn parse(tokens: *Tokenizer.TokenIterator) !results.ParseResult(This) {
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

    var direct: ?bool = null;
    var mode: ?SearchMode = null;
    var of: ?AssetTarget = null;
    var in: ?InTarget = null;

    if (tokens.peek(1)) |tkn| {
        if (tkn.is(.literal, "direct")) {
            direct = true;
            _ = tokens.next();
        } else if (tkn.is(.literal, "indirect")) {
            direct = false;
            _ = tokens.next();
        }
    }

    if (tokens.next()) |tkn| {
        if (direct == null and tkn.is(.literal, "refs")) {
            mode = .refs;
        } else if (tkn.is(.literal, "uses")) {
            mode = if (direct orelse false) .direct_uses else .indirect_uses;
        } else {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected_type = .literal,
                    .expected_value = "refs",
                },
            });
        }

        if (direct != null and mode != .direct_uses and mode != .indirect_uses) {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected_type = .literal,
                    .expected_value = "uses",
                },
            });
        }
    } else {
        return .ERR(.{
            .unexpected_eof = .{
                .expected_type = .literal,
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
        .mode = mode.?,
        .of = of.?,
        .in = in orelse InTarget.default,
    });
}

pub fn run(self: This, data: RuntimeData) !results.RuntimeResult(void) {
    var fileCount: usize = 0;
    var loops: usize = 0;

    const start = std.time.milliTimestamp();
    const result = try self.search(data, &fileCount, &loops);
    const time = std.time.milliTimestamp() - start;

    if (result.isErr()) |err| {
        return .ERR(err);
    }

    const references = result.ok;
    defer {
        for (references) |r| data.allocator.free(r);
        data.allocator.free(references);
    }

    sort(@ptrCast(references));
    for (references) |r| {
        try data.out.print("{s}\r\n", .{r});
    }

    if (data.verbose) {
        std.debug.print("Scanned {d} files {d} times in {d} milliseconds \r\n", .{ fileCount, loops, time });
    }
    return .OK(void{});
}

pub fn search(self: This, data: RuntimeData, count: ?*usize, times: ?*usize) !results.RuntimeResult([][]u8) {
    var guids = core.runtime.StringList.init(data.allocator);
    defer guids.deinit();
    var searched: usize = 0;

    var references = core.runtime.StringList.init(data.allocator);
    defer references.deinit();
    var scanned: usize = 0;

    var dir = self.in.openDir(data, .{ .iterate = true, .access_sub_paths = true }) catch {
        return .ERR(.{
            .invalid_path = .{ .path = self.in.dir },
        });
    };
    defer dir.close();

    const assets = switch (try self.of.getGUID(data.allocator, data.cwd)) {
        .ok => |v| v,
        .err => |err| return .ERR(err),
    };
    defer {
        for (assets) |g| data.allocator.free(g);
        data.allocator.free(assets);
    }
    try guids.pushSlice(assets);

    while (guids.length() > searched) {
        var searchData = Search{
            .mode = self.mode,
            .guid = guids.ctx.items[searched..],
            .data = data,
            .references = &references,
        };
        searched = guids.length();

        var scanner = try Scanner(Search).init(dir, Search.search, Search.filter, data.allocator);
        defer scanner.deinit();

        try scanner.scan(&searchData);

        if (count) |c| c.* = searchData.fileCount;

        if (self.mode == .indirect_uses or self.mode == .direct_uses) {
            var i: usize = references.length() - 1;
            while (i > 0) : (i -= 1) {
                const ref = references.get(i) catch break;
                if (!try verifyUse(dir, ref, searchData.guid, data.allocator)) {
                    try references.remove(i);
                }
            }
        }

        // Feeds the guid list with any prefab references found in the files, if in indirect mode.
        if (self.mode == .indirect_uses) {
            const prefab_guids = try getPrefabGuids(dir, references.ctx.items[scanned..], data.allocator);
            defer data.allocator.free(prefab_guids);
            try guids.pushSlice(prefab_guids);
            scanned = references.length();
        }
        if (times) |t| t.* += 1;
    }

    return .OK(@ptrCast(try references.toOwnedSlice()));
}

/// Get the GUIDs of all prefabs in `assets`.
/// If a non prefab asset is found, it will be ignored.
///
/// `cwd` is the directory relative to the paths in `assets`.
///
/// The caller owns the returned slice and its children.
fn getPrefabGuids(cwd: std.fs.Dir, assets: []const []const u8, allocator: std.mem.Allocator) ![]const []const u8 {
    var guids = core.runtime.StringList.init(allocator);
    defer guids.deinit();
    for (assets) |ass| {
        if (!std.mem.endsWith(u8, ass, ".prefab")) continue;

        const path = try std.mem.concat(allocator, u8, &.{ ass, ".meta" });
        defer allocator.free(path);
        const file = try cwd.openFile(path, .{ .mode = .read_only });
        defer file.close();
        const prefab_guid = AssetTarget.scanMetafile(file, allocator) catch continue;
        defer allocator.free(prefab_guid);
        try guids.push(prefab_guid);
    }
    return guids.toOwnedSlice();
}

/// Verify if a component or prefab instance of guid `guid` is being used within the file at `path`.
///
/// `cwd` is the directory relative to `path`.
fn verifyUse(cwd: std.fs.Dir, path: []const u8, guid: []const []const u8, allocator: std.mem.Allocator) !bool {
    const file = try cwd.openFile(path, .{ .mode = .read_only });
    defer file.close();
    var iterator = ComponentIterator.init(file, allocator);
    defer iterator.deinit();

    while (try iterator.next()) |comp| {
        var yaml = Yaml.init(.{ .string = comp.document }, null, allocator);
        for (guid) |g| {
            if (try yaml.matchScriptGUID(g) or try yaml.matchPrefabGUID(g)) {
                return true;
            }
        }
    }
    return false;
}

fn sort(arr: [][]const u8) void {
    const Context = struct {
        pub fn lessThanFn(_: @This(), lhs: []const u8, rhs: []const u8) bool {
            for (0..@min(lhs.len, rhs.len)) |i| {
                if (lhs[i] != rhs[i]) {
                    return lhs[i] < rhs[i];
                }
            }
            return false;
        }
    };
    std.mem.sort([]const u8, arr, Context{}, Context.lessThanFn);
}

const Search = struct {
    data: RuntimeData,
    mode: SearchMode,
    guid: []const []const u8,
    fileCount: usize = 0,
    dataMtx: std.Thread.Mutex = .{},

    references: *core.runtime.StringList,
    refsMtx: std.Thread.Mutex = .{},

    logMtx: std.Thread.Mutex = .{},

    fn filter(self: *Search, entry: std.fs.Dir.Walker.Entry) ?std.fs.File {
        if (entry.kind != .file) return null;

        const exts: []const []const u8 = switch (self.mode) {
            .refs => refs_files,
            .direct_uses => uses_files,
            .indirect_uses => uses_files,
        };

        for (exts) |ext| {
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

        const progress = try self.data.allocator.alloc(usize, self.guid.len);
        for (0..self.guid.len) |i| {
            progress[i] = 0;
        }
        defer self.data.allocator.free(progress);

        main: while (true) {
            const c = reader.readByte() catch |err| {
                if (err != error.EndOfStream) {
                    self.logMtx.lock();
                    defer self.logMtx.unlock();
                    log.warn("Error ({s}) reading file: '{s}'", .{ @errorName(err), entry.path });
                }
                break;
            };

            for (0..self.guid.len) |i| {
                if (c == self.guid[i][progress[i]]) {
                    progress[i] += 1;
                    if (progress[i] == self.guid[i].len) {
                        try self.addPath(entry.path);
                        break :main;
                    }
                } else {
                    progress[i] = 0;
                }
            }
        }

        self.dataMtx.lock();
        defer self.dataMtx.unlock();
        self.fileCount += 1;
    }

    /// Add a path to the list of references if it is not already present.
    /// `path` does not need to be allocated, as it will be duplicated.
    ///
    /// This function is thread-safe.
    fn addPath(self: *Search, path: []const u8) !void {
        self.refsMtx.lock();
        defer self.refsMtx.unlock();
        for (self.references.ctx.items) |g| {
            if (std.mem.eql(u8, g, path)) {
                return;
            }
        }
        try self.references.push(path);
    }
};
