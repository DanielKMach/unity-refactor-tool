const std = @import("std");

pub fn Scanner(T: type) type {
    return struct {
        const This = @This();
        const FragFn = *const fn (data: *T, entry: std.fs.Dir.Walker.Entry, file: std.fs.File) anyerror!void;
        const FilterFn = *const fn (data: *T, entry: std.fs.Dir.Walker.Entry) ?std.fs.File;

        fragFn: FragFn,
        filterFn: FilterFn,
        allocator: std.mem.Allocator,
        threads: []std.Thread,

        walker: ?std.fs.Dir.Walker,
        walkerMtx: std.Thread.Mutex,

        pub fn init(dir: std.fs.Dir, fragFn: FragFn, filterFn: ?FilterFn, allocator: std.mem.Allocator) !This {
            const walker = try dir.walk(allocator);

            return This{
                .fragFn = fragFn,
                .filterFn = filterFn orelse defaultFilter,
                .walker = walker,
                .walkerMtx = std.Thread.Mutex{},
                .allocator = allocator,
                .threads = try allocator.alloc(std.Thread, 4),
            };
        }

        pub fn deinit(self: *This) void {
            if (self.walker) |*wlkr| wlkr.deinit();
            self.allocator.free(self.threads);
        }

        pub fn scan(self: *This, data: *T) !void {
            for (self.threads) |*thread| {
                thread.* = try std.Thread.spawn(.{ .allocator = self.allocator }, loop, .{ self, data });
            }

            for (self.threads) |thread| {
                thread.join();
            }
        }

        pub fn defaultFilter(_: *T, entry: std.fs.Dir.Walker.Entry) ?std.fs.File {
            if (entry.kind == .file) {
                return entry.dir.openFile(entry.basename, .{ .mode = .read_only }) catch return null;
            }
            return null;
        }

        fn loop(self: *This, data: *T) !void {
            while (true) {
                var entry: std.fs.Dir.Walker.Entry = undefined;
                var file: ?std.fs.File = null;
                if (self.walker) |*wlkr| {
                    self.walkerMtx.lock();
                    defer self.walkerMtx.unlock();
                    const e = try wlkr.next() orelse break;
                    entry = try dupeEntry(e, self.allocator);
                    file = self.filterFn(data, entry);
                }
                if (file) |f| {
                    try self.fragFn(data, entry, f);
                    f.close();
                }
                freeEntry(entry, self.allocator);
            }
        }

        fn dupeEntry(entry: std.fs.Dir.Walker.Entry, allocator: std.mem.Allocator) !std.fs.Dir.Walker.Entry {
            return std.fs.Dir.Walker.Entry{
                .dir = entry.dir,
                .basename = try allocator.dupeZ(u8, entry.basename),
                .path = try allocator.dupeZ(u8, entry.path),
                .kind = entry.kind,
            };
        }

        fn freeEntry(entry: std.fs.Dir.Walker.Entry, allocator: std.mem.Allocator) void {
            allocator.free(entry.basename);
            allocator.free(entry.path);
        }
    };
}
