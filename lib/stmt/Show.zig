const std = @import("std");
const core = @import("core");
const log = std.log.scoped(.show_statement);

const This = @This();
const Stmt = core.Stmt;
const clse = core.Stmt.clse;
const TokenIterator = core.Token.Iterator;
const Yaml = core.runtime.Yaml;
const ComponentIterator = core.runtime.ComponentIterator;
const Scanner = core.runtime.Scanner;
const GUID = core.runtime.GUID;

pub const SearchMode = enum {
    refs,
    direct_uses,
    indirect_uses,
};

const uses_files = &.{ ".prefab", ".unity" };
const refs_files = &.{ ".prefab", ".unity", ".asset", ".mat" };

mode: SearchMode,
of: clse.Of,
in: ?clse.In,

pub fn parse(tokens: *TokenIterator, env: Stmt.ParseEnv) Stmt.ParseError!This {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (!tokens.match(.SHOW)) return error.TokenMismatch;

    const direct = if (tokens.consumeAny(&.{ .DIRECT, .INDIRECT })) |t| blk: {
        break :blk t.is(.DIRECT);
    } else null;

    const mode: SearchMode = if (direct) |d| blk: {
        _ = try tokens.grab(.USES, env.diag);
        break :blk if (d) .direct_uses else .indirect_uses;
    } else blk: {
        const t = try tokens.grabAny(&.{ .USES, .REFS }, env.diag);
        break :blk if (t.is(.USES)) .indirect_uses else .refs;
    };

    const Clauses = struct {
        OF: clse.Of,
        IN: ?clse.In = null,
    };
    const clauses = try clse.parse(Clauses, tokens, env);

    return .{
        .mode = mode,
        .of = clauses.OF,
        .in = clauses.IN,
    };
}

pub fn cleanup(self: This, allocator: std.mem.Allocator) void {
    self.of.cleanup(allocator);
    if (self.in) |in| in.cleanup(allocator);
}

pub fn run(self: This, env: Stmt.RunEnv) Stmt.RunError!void {
    var fileCount: usize = 0;
    var loops: usize = 0;

    const start = std.time.milliTimestamp();
    const results = try self.search(&fileCount, &loops, env);
    defer env.allocator.free(results);
    defer for (results) |r| env.allocator.free(r);
    const time = std.time.milliTimestamp() - start;

    sort(@ptrCast(results));
    for (results) |path| try env.out.print("{s}\r\n", .{path});
    try env.out.print("Scanned {d} files {d} times in {d} milliseconds \r\n", .{ fileCount, loops, time });
    try env.out.flush();
}

pub fn search(self: This, count: ?*usize, times: ?*usize, env: Stmt.RunEnv) ![][]u8 {
    core.profiling.begin(search);
    defer core.profiling.stop();

    const in = self.in orelse clse.In.default;
    const of = self.of;

    var guids = std.ArrayList(GUID).empty;
    defer guids.deinit(env.allocator);
    defer for (guids.items) |g| g.deinit(env.allocator);
    var searched: usize = 0;

    var dir = try in.dir(env);
    defer dir.close();

    var scanner = Scanner(Search).init(dir, env.allocator);

    var references = try core.runtime.StringList.init(scanner.allocator.allocator());
    defer references.deinit();
    var scanned: usize = 0;

    {
        const starting_targets = try of.getGUID(env);
        defer env.allocator.free(starting_targets);
        errdefer for (starting_targets) |g| g.deinit(env.allocator);

        try guids.appendSlice(env.allocator, starting_targets);
    }

    while (guids.items.len > searched) {
        var searchData = Search{
            .mode = self.mode,
            .dir = dir,
            .guid = guids.items[searched..],
            .references = &references,
        };
        searched = guids.items.len;

        log.info("Scanning...", .{});

        try scanner.scan(&searchData);

        if (count) |c| c.* = searchData.file_count;

        // Feeds the guid list with any prefab references found in the files, if in indirect mode.
        if (self.mode == .indirect_uses) {
            for (references.ctx.items[scanned..]) |ref| {
                if (!std.mem.endsWith(u8, ref, ".prefab")) continue;
                const guid = try GUID.fromFile(ref, env.allocator);
                errdefer guid.deinit(env.allocator);

                try guids.append(env.allocator, guid);
            }
            scanned = references.length();
        }
        if (times) |t| t.* += 1;
    }

    return try references.toOwnedSlice();
}

/// Verify if a component or prefab instance of guid `guid` is being used within the file at `path`.
///
/// `cwd` is the directory relative to `path`.
fn verifyUse(file: std.fs.File, guid: []const GUID, allocator: std.mem.Allocator) !bool {
    core.profiling.begin(verifyUse);
    defer core.profiling.stop();

    var iterator = try ComponentIterator.init(file, allocator);
    defer iterator.deinit();

    return while (try iterator.next()) |comp| {
        var yaml = Yaml.init(.{ .string = comp.document }, null, allocator);
        if (try matchScriptOrPrefabGUID(guid, &yaml)) break true;
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
    guid: []const GUID,

    dir: std.fs.Dir,

    file_count: usize = 0,
    count_mtx: std.Thread.Mutex = .{},

    references: *core.runtime.StringList,
    refs_mtx: std.Thread.Mutex = .{},

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

    pub fn scan(self: *Search, path: [:0]const u8, file: std.fs.File, allocator: std.mem.Allocator) anyerror!void {
        core.profiling.begin(scan);
        defer core.profiling.stop();

        var buf: [4096]u8 = undefined;
        var fread = file.reader(&buf);
        var reader = &fread.interface;

        const progress = try allocator.alloc(usize, self.guid.len);
        defer allocator.free(progress);
        @memset(progress, 0);

        main: while (true) {
            if (reader.bufferedLen() == 0) {
                reader.fillMore() catch |err| {
                    if (err != error.EndOfStream) {
                        log.warn("Error ({s}) reading file: '{s}'", .{ @errorName(err), path });
                    }
                    break;
                };
            }
            const c = reader.takeByte() catch unreachable; // Because already filled.

            for (0..self.guid.len) |i| {
                if (c == self.guid[i].value[progress[i]]) {
                    progress[i] += 1;
                    if (progress[i] == self.guid[i].value.len) {
                        try self.addPath(path, file, allocator);
                        break :main;
                    }
                } else {
                    progress[i] = 0;
                }
            }
        }

        self.count_mtx.lock();
        defer self.count_mtx.unlock();
        self.file_count += 1;
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

        {
            self.refs_mtx.lock();
            defer self.refs_mtx.unlock();
            if (self.references.has(abs_path)) return;
        }

        if (self.mode == .indirect_uses or self.mode == .direct_uses) {
            try file.seekTo(0);
            if (!try verifyUse(file, self.guid, allocator)) {
                return;
            }
        }

        self.refs_mtx.lock();
        defer self.refs_mtx.unlock();
        try self.references.push(abs_path);
    }
};
