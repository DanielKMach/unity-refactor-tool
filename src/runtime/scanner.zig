const std = @import("std");

pub fn Scanner(T: type) type {
    return struct {
        const This = @This();
        const FragFn = fn (*T, std.fs.Dir.Walker.Entry, std.fs.File, std.mem.Allocator) anyerror!void;
        const FilterFn = fn (*T, std.fs.Dir.Walker.Entry, std.mem.Allocator) ?std.fs.File;

        const fragFn: FragFn = if (@hasDecl(T, "scan") and @TypeOf(T.scan) == FragFn) T.scan else @compileError("scan function not defined");
        const filterFn: FilterFn = if (@hasDecl(T, "filter") and @TypeOf(T.filter) == FilterFn) T.filter else defaultFilter;

        allocator: std.mem.Allocator,
        threads: []std.Thread,

        walker: ?std.fs.Dir.Walker,
        walkerMtx: std.Thread.Mutex,

        pub fn init(dir: std.fs.Dir, allocator: std.mem.Allocator) !This {
            const walker = try dir.walk(allocator);

            return This{
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
            var thread_safe_alloc = std.heap.ThreadSafeAllocator{
                .child_allocator = self.allocator,
            };

            for (self.threads) |*thread| {
                thread.* = try std.Thread.spawn(
                    .{ .allocator = thread_safe_alloc.allocator() },
                    loop,
                    .{ self, data, thread_safe_alloc.allocator() },
                );
            }

            for (self.threads) |thread| {
                thread.join();
            }
        }

        fn loop(self: *This, data: *T, allocator: std.mem.Allocator) !void {
            while (true) {
                var entry: std.fs.Dir.Walker.Entry = undefined;
                var file: ?std.fs.File = null;
                if (self.walker) |*wlkr| {
                    self.walkerMtx.lock();
                    defer self.walkerMtx.unlock();
                    const e = try wlkr.next() orelse break;
                    entry = try dupeEntry(e, allocator);
                    file = filterFn(data, entry, allocator);
                }
                if (file) |f| {
                    try fragFn(data, entry, f, allocator);
                    f.close();
                }
                freeEntry(entry, allocator);
            }
        }

        fn defaultFilter(_: *T, entry: std.fs.Dir.Walker.Entry, _: std.mem.Allocator) ?std.fs.File {
            if (entry.kind == .file) {
                return entry.dir.openFile(entry.basename, .{ .mode = .read_only }) catch return null;
            }
            return null;
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
