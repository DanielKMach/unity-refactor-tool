const std = @import("std");
const core = @import("core");
const tracy = @import("tracy");
const log = std.log.scoped(.show_statement);

const This = @This();
const Stmt = core.Stmt;
const clse = core.Stmt.clse;
const TokenIterator = core.Token.Iterator;
const Yaml = core.runtime.Yaml;
const ObjIterator = core.runtime.ObjIterator;
const Scanner = core.runtime.Scanner;
const GUID = core.runtime.GUID;

pub const SearchMode = enum {
    refs,
    direct_uses,
    indirect_uses,
};

const uses_files = &.{ ".prefab", ".unity", ".asset" };
const refs_files = &.{ ".prefab", ".unity", ".asset", ".mat", ".controller", ".anim" };

mode: SearchMode,
of: clse.Of,
in: ?clse.In,
where: ?clse.Where,

pub fn parse(tokens: *TokenIterator, env: Stmt.ParseEnv) Stmt.ParseError!This {
    const zone = tracy.Zone(@src());
    defer zone.End();

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
    const tkn = tokens.peek(0);

    const Clauses = struct {
        of: clse.Of,
        in: ?clse.In = null,
        where: ?clse.Where = null,
    };
    const clauses = try clse.parse(Clauses, tokens, env);

    if (clauses.where != null and mode == .refs) return env.err(.{ .invalid_mode_for_clause = .{
        .clause = "WHERE",
        .mode = mode,
        .location = tkn.loc,
    } });

    return .{
        .mode = mode,
        .of = clauses.of,
        .in = clauses.in,
        .where = clauses.where,
    };
}

pub fn cleanup(self: This, allocator: std.mem.Allocator) void {
    self.of.cleanup(allocator);
    if (self.where) |where| where.cleanup(allocator);
}

pub fn run(self: This, env: Stmt.RunEnv) Stmt.RunError!void {
    var loops: usize = 0;

    const start = std.time.milliTimestamp();
    const results = try self.search(&loops, env);
    defer env.allocator.free(results);
    defer for (results) |r| env.allocator.free(r);
    const time = std.time.milliTimestamp() - start;

    sort(@ptrCast(results));
    for (results) |path| try env.out.print("{s}\r\n", .{trimCwd(path)});
    log.info("Scanned project {d} times in {d} milliseconds", .{ loops, time });
    try env.out.flush();
}

pub fn search(self: This, times: ?*usize, env: Stmt.RunEnv) Stmt.RunError![][]u8 {
    const zone = tracy.Zone(@src());
    defer zone.End();

    const in = self.in orelse clse.In.default;
    const of = self.of;
    const where = self.where;

    var guids = std.ArrayList(GUID).empty;
    defer guids.deinit(env.allocator);
    var searched: usize = 0;

    var threadsafe = std.heap.ThreadSafeAllocator{ .child_allocator = env.allocator };
    const allocator = threadsafe.allocator();

    const dir = in.subpath();

    var references = try core.runtime.StringList.init(allocator);
    defer references.deinit();
    var scanned: usize = 0;

    {
        const filter: Stmt.clse.Of.Filter = if (self.where) |_| .components_only else if (self.mode == .refs) .any else .prefabs_and_components;
        const starting_targets = try of.getGUID(filter, env);
        defer env.allocator.free(starting_targets);

        try guids.appendSlice(env.allocator, starting_targets);
    }

    while (guids.items.len > searched) {
        var searchData = Search{
            .mode = self.mode,
            .condition = if (where) |w| w.expr else null,
            .diag = env.diag,
            .proj = env.proj,
            .guids = guids.items[searched..],
            .references = &references,
        };
        searched = guids.items.len;

        log.info("Scanning...", .{});
        env.proj.scan(
            &searchData,
            Search.filt,
            Search.frag,
            dir,
            env.pool,
            allocator,
        ) catch |err| switch (err) {
            error.FileNotFound => return env.err(.{ .invalid_path = .{ .path = in.path.?.loc } }),
            else => |e| return e,
        };

        // Feeds the guid list with any prefab references found in the files, if in indirect mode.
        if (self.mode == .indirect_uses) {
            for (references.ctx.items[scanned..]) |ref| {
                if (!std.mem.endsWith(u8, ref, ".prefab")) continue;
                try guids.append(env.allocator, try GUID.fromAsset(ref, env.allocator));
            }
            scanned = references.length();
        }
        if (times) |t| t.* += 1;
    }

    return try references.toOwnedSlice();
}

/// Check if the GUID of the document in `yaml` matches any of the GUIDs in `guids`.
pub fn matchScriptOrPrefabGUID(guids: []const GUID, yaml: *Yaml) Yaml.ParseError!bool {
    return try matchGUID(guids, yaml) != null;
}

/// Check if the GUID of the document in `yaml` matches any of the GUIDs in `guids`.
pub fn matchGUID(guids: []const GUID, yaml: *Yaml) Yaml.ParseError!?GUID {
    const zone = tracy.Zone(@src());
    defer zone.End();

    var buf: [32]u8 = undefined;
    var nullableGuid = try yaml.get(&.{ "MonoBehaviour", "m_Script", "guid" }, &buf);
    if (nullableGuid == null) {
        nullableGuid = try yaml.get(&.{ "PrefabInstance", "m_SourcePrefab", "guid" }, &buf);
    }
    const guid = nullableGuid orelse return null;

    return for (guids) |g| {
        if (g.eql(guid)) break g;
    } else null;
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

/// Trim the current working directory from the start of `path`, if possible and present.
pub fn trimCwd(path: []const u8) []const u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd = std.fs.cwd().realpath(".", &buf) catch return path;
    if (std.mem.startsWith(u8, path, cwd)) {
        const from = if (path.len > cwd.len and path[cwd.len] == std.fs.path.sep) cwd.len + 1 else cwd.len;
        return path[from..];
    } else {
        return path;
    }
}

const Search = struct {
    mode: SearchMode,
    guids: []const GUID,
    condition: ?*core.Expr,
    diag: *core.RuntimeDiagnostics,
    proj: core.Project,

    references: *core.runtime.StringList,
    refs_mtx: std.Thread.RwLock = .{},

    const VerifyError = ObjIterator.IterateError || Yaml.ParseError || core.runtime.GUID.FromFileError || core.Expr.eval.Error || std.mem.Allocator.Error;
    const AddPathError = VerifyError || std.fs.File.SeekError || std.mem.Allocator.Error;

    pub fn filt(data: *anyopaque, entry: std.fs.Dir.Walker.Entry, _: std.mem.Allocator) core.Project.SearchError!bool {
        if (entry.kind != .file) return false;

        const self: *Search = @ptrCast(@alignCast(data));
        const exts: []const []const u8 = switch (self.mode) {
            .refs => refs_files,
            .direct_uses => uses_files,
            .indirect_uses => uses_files,
        };

        return for (exts) |ext| {
            if (std.mem.endsWith(u8, entry.path, ext)) break true;
        } else false;
    }

    pub fn frag(data: *anyopaque, dir: std.fs.Dir, path: []const u8, allocator: std.mem.Allocator) core.Project.SearchError!void {
        const zone = tracy.Zone(@src());
        defer zone.End();

        var zonemsg: [512]u8 = undefined;
        tracy.Message(std.fmt.bufPrint(&zonemsg, "Scanning '{s}'", .{path}) catch "Too long");

        const file = dir.openFile(path, .{ .mode = .read_only }) catch |err| {
            log.warn("Error ({s}) reading file: '{s}'", .{ @errorName(err), path });
            return error.SearchFailed;
        };
        defer file.close();

        const self: *Search = @ptrCast(@alignCast(data));

        var buf: [4096]u8 = undefined;
        var fread = file.reader(&buf);
        var reader = &fread.interface;
        var maybe_guid: [32]u8 = undefined;
        var n: usize = 0;

        main: while (true) {
            while (true) {
                if (reader.bufferedLen() == 0) reader.fillMore() catch |err| {
                    if (err != error.EndOfStream) {
                        log.warn("Error ({s}) reading file: '{s}'", .{ @errorName(err), path });
                        return error.SearchFailed;
                    }
                };
                if (reader.takeByte()) |b| {
                    if (std.ascii.isHex(b)) {
                        if (n == 32) {
                            @memmove(maybe_guid[0..31], maybe_guid[1..]);
                            n -= 1;
                        }
                        maybe_guid[n] = b;
                        n += 1;
                        if (n == 32) break;
                    } else n = 0;
                } else |err| {
                    if (err == error.EndOfStream) break :main;
                    log.warn("Error ({s}) reading file: '{s}'", .{ @errorName(err), path });
                    return error.SearchFailed;
                }
            }

            std.debug.assert(n == 32);
            for (self.guids) |guid| {
                if (!guid.eql(&maybe_guid)) continue;
                const abspath = dir.realpath(path, &buf) catch return error.SearchFailed;
                self.addPath(abspath, file, allocator) catch return error.SearchFailed;
                break :main;
            }
        }
    }

    /// Adds an absolute path to the list of references if it's not already present.
    /// `abspath` does not need to be allocated, as it will be duplicated.
    ///
    /// This function is thread-safe.
    fn addPath(self: *Search, abspath: []const u8, file: std.fs.File, allocator: std.mem.Allocator) AddPathError!void {
        const zone = tracy.Zone(@src());
        defer zone.End();

        {
            self.refs_mtx.lockShared();
            defer self.refs_mtx.unlockShared();
            if (self.references.has(abspath)) return;
        }

        if (self.mode == .indirect_uses or self.mode == .direct_uses) {
            try file.seekTo(0);
            if (!try self.verifyUse(file, abspath, allocator)) {
                return;
            }
        }

        self.refs_mtx.lock();
        defer self.refs_mtx.unlock();
        try self.references.push(abspath);
    }

    /// Verify if a component or prefab instance of guid `guid` is being used within the file at `path`.
    fn verifyUse(self: *Search, file: std.fs.File, fpath: []const u8, allocator: std.mem.Allocator) VerifyError!bool {
        const zone = tracy.Zone(@src());
        defer zone.End();

        var iterator = try ObjIterator.init(file, allocator);
        defer iterator.deinit();

        var assets: core.runtime.AssetMap = .init(allocator, self.proj);
        defer assets.deinit();
        var objs: core.runtime.ObjMap = .init(allocator);
        defer objs.deinit();

        return while (try iterator.next()) |e| {
            if (e.info.stripped or e.info.class_id != .MonoBehaviour and e.info.class_id != .PrefabInstance) continue;

            var yaml = Yaml.init(.{ .string = e.content }, null, allocator);
            switch (e.info.class_id) {
                .MonoBehaviour => {
                    if (try matchGUID(self.guids, &yaml) == null) continue;
                    if (self.condition == null) break true;
                    const guid = try assets.put(fpath);

                    const ctx: core.Expr.Value.Asset = .{
                        .file_id = e.info.file_id,
                        .guid = guid,
                        .type = 3, // TODO: determine type
                    };

                    const doc = objs.new(guid, e.info.file_id, e.info.class_id) catch |err| switch (err) {
                        error.OutOfMemory => |er| return er,
                        error.AlreadyExists => unreachable,
                    };
                    try yaml.loadDocument(doc);

                    var vars: core.Expr.VarMap = try .default(allocator);
                    defer vars.deinit();

                    const value = try self.condition.?.evaluateAuto(.{
                        .allocator = allocator,
                        .root = undefined, // Will be set by evaluateAuto
                        .diag = self.diag,
                        .context = ctx,
                        .assets = &assets,
                        .objs = &objs,
                        .vars = &vars,
                        .readonly = true,
                    });
                    defer value.cleanup(allocator);
                    if (value.isTruthy()) break true;
                },
                .PrefabInstance => {
                    // Just checking prefab instance GUID usage is enough for now.
                    if (try matchGUID(self.guids, &yaml) != null) break true;
                },
                else => unreachable,
            }
        } else false;
    }
};
