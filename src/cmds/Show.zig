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
const GUID = core.runtime.GUID;

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
    core.profiling.begin(parse);
    defer core.profiling.stop();

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
    core.profiling.begin(search);
    defer core.profiling.stop();

    var guids = std.ArrayList(GUID).init(data.allocator);
    defer guids.deinit();
    defer for (guids.items) |g| g.deinit(data.allocator);
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

    {
        const starting_targets: []GUID = switch (try self.of.getGUID(data.cwd, data.allocator)) {
            .ok => |v| v,
            .err => |err| return .ERR(err),
        };
        defer data.allocator.free(starting_targets);
        errdefer for (starting_targets) |g| g.deinit(data.allocator);

        try guids.appendSlice(starting_targets);
    }

    while (guids.items.len > searched) {
        var searchData = Search{
            .mode = self.mode,
            .dir = dir,
            .guid = guids.items[searched..],
            .references = &references,
        };
        searched = guids.items.len;

        var scanner = try Scanner(Search).init(dir, data.allocator);
        defer scanner.deinit();

        log.debug("Scanning...", .{});

        try scanner.scan(&searchData);

        if (count) |c| c.* = searchData.fileCount;

        // Feeds the guid list with any prefab references found in the files, if in indirect mode.
        if (self.mode == .indirect_uses) {
            for (references.ctx.items[scanned..]) |ref| {
                if (!std.mem.endsWith(u8, ref, ".prefab")) continue;
                const guid = try GUID.fromFile(ref, data.allocator);
                errdefer guid.deinit(data.allocator);

                try guids.append(guid);
            }
            scanned = references.length();
        }
        if (times) |t| t.* += 1;
    }

    return .OK(@ptrCast(try references.toOwnedSlice()));
}

/// Verify if a component or prefab instance of guid `guid` is being used within the file at `path`.
///
/// `cwd` is the directory relative to `path`.
fn verifyUse(file: std.fs.File, guid: []const GUID, allocator: std.mem.Allocator) !bool {
    core.profiling.begin(verifyUse);
    defer core.profiling.stop();

    var iterator = ComponentIterator.init(file, allocator);
    defer iterator.deinit();

    return while (try iterator.next()) |comp| {
        var yaml = Yaml.init(.{ .string = comp.document }, null, allocator);
        if (try matchScriptOrPrefabGUID(guid, &yaml)) return true;
    } else false;
}

/// Check if the GUID of the document in `yaml` matches any of the GUIDs in `guids`.
pub fn matchScriptOrPrefabGUID(guids: []const GUID, yaml: *Yaml) Yaml.ParseError!bool {
    core.profiling.begin(matchScriptOrPrefabGUID);
    defer core.profiling.stop();

    var buf: [32]u8 = undefined;
    var nullableGuid = try yaml.get(&.{ "MonoBehaviour", "m_Script", "guid" }, &buf);
    if (nullableGuid == null) {
        nullableGuid = try yaml.get(&.{ "PrefabInstance", "m_SourcePrefab", "guid" }, &buf);
    }
    const guid = nullableGuid orelse return false;

    return for (guids) |g| {
        if (std.mem.eql(u8, g.value, guid)) break true;
    } else false;
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
    mode: SearchMode,
    dir: std.fs.Dir,
    guid: []const GUID,
    fileCount: usize = 0,
    dataMtx: std.Thread.Mutex = .{},

    references: *core.runtime.StringList,
    refsMtx: std.Thread.Mutex = .{},

    logMtx: std.Thread.Mutex = .{},

    pub fn filter(self: *Search, entry: std.fs.Dir.Walker.Entry, _: std.mem.Allocator) ?std.fs.File {
        core.profiling.begin(filter);
        defer core.profiling.stop();

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

    pub fn scan(self: *Search, entry: std.fs.Dir.Walker.Entry, file: std.fs.File, allocator: std.mem.Allocator) anyerror!void {
        core.profiling.begin(scan);
        defer core.profiling.stop();

        var bufrdr = std.io.bufferedReader(file.reader());
        const reader = bufrdr.reader();

        const progress = try allocator.alloc(usize, self.guid.len);
        for (0..self.guid.len) |i| {
            progress[i] = 0;
        }
        defer allocator.free(progress);

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
                if (c == self.guid[i].value[progress[i]]) {
                    progress[i] += 1;
                    if (progress[i] == self.guid[i].value.len) {
                        try self.addPath(entry.path, file, allocator);
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
    fn addPath(self: *Search, path: []const u8, file: std.fs.File, allocator: std.mem.Allocator) !void {
        core.profiling.begin(addPath);
        defer core.profiling.stop();

        const abs_path = try self.dir.realpathAlloc(allocator, path);
        defer allocator.free(abs_path);

        for (self.references.ctx.items) |g| {
            if (std.mem.eql(u8, g, abs_path)) {
                return;
            }
        }

        if (self.mode == .indirect_uses or self.mode == .direct_uses) {
            try file.seekTo(0);
            if (!try verifyUse(file, self.guid, allocator)) {
                return;
            }
        }

        self.refsMtx.lock();
        defer self.refsMtx.unlock();
        try self.references.push(abs_path);
    }
};
