const std = @import("std");

pub fn Scanner(T: type) type {
    return struct {
        const This = @This();
        const FragFn = fn (*T, [:0]const u8, std.fs.File, std.mem.Allocator) anyerror!void;
        const FilterFn = fn (*T, std.fs.Dir.Walker.Entry, std.mem.Allocator) ?std.fs.File;

        const fragFn: FragFn = if (@hasDecl(T, "scan") and @TypeOf(T.scan) == FragFn) T.scan else @compileError("scan function not defined");
        const filterFn: FilterFn = if (@hasDecl(T, "filter") and @TypeOf(T.filter) == FilterFn) T.filter else defaultFilter;

        allocator: std.heap.ThreadSafeAllocator,
        dir: std.fs.Dir,

        walker: ?std.fs.Dir.Walker = null,
        walker_mtx: std.Thread.Mutex = .{},

        pub fn init(dir: std.fs.Dir, allocator: std.mem.Allocator) This {
            return This{
                .dir = dir,
                .allocator = .{
                    .child_allocator = allocator,
                },
            };
        }

        pub fn scan(self: *This, data: *T) !void {
            const allocator = self.allocator.allocator();
            var walker = try self.dir.walk(allocator);
            defer walker.deinit();

            // var pool: std.Thread.Pool = undefined;
            // var wg: std.Thread.WaitGroup = .{};

            // try std.Thread.Pool.init(&pool, .{
            //     .n_jobs = 4,
            //     .allocator = allocator,
            // });
            // pool.spawnWg(&wg, loop, .{ data, &walker, &self.walker_mtx, allocator });
            // wg.wait(); // Why is thread pool 3 times slower than just spawning threads?
            const threads = try allocator.alloc(std.Thread, 4);
            defer allocator.free(threads);

            for (threads) |*t| {
                t.* = try std.Thread.spawn(
                    .{ .allocator = allocator },
                    loop,
                    .{ data, &walker, &self.walker_mtx, allocator },
                );
            }

            for (threads) |thread| {
                thread.join();
            }
        }

        fn loop(data: *T, walker: *std.fs.Dir.Walker, w_mtx: *std.Thread.Mutex, allocator: std.mem.Allocator) void {
            while (true) {
                var file: ?std.fs.File = null;
                defer if (file) |f| f.close();
                var path: ?[:0]const u8 = null;
                defer if (path) |p| allocator.free(p);

                {
                    w_mtx.lock();
                    defer w_mtx.unlock();

                    const entry = walker.next() catch unreachable orelse break;
                    file = filterFn(data, entry, allocator);
                    path = allocator.dupeZ(u8, entry.path) catch unreachable;
                }

                if (file != null and path != null) {
                    fragFn(data, path.?, file.?, allocator) catch unreachable;
                }
            }
        }

        fn defaultFilter(_: *T, entry: std.fs.Dir.Walker.Entry, _: std.mem.Allocator) ?std.fs.File {
            if (entry.kind == .file) {
                return entry.dir.openFile(entry.basename, .{ .mode = .read_only }) catch return null;
            }
            return null;
        }
    };
}
