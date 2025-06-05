const std = @import("std");
const config = @import("config");
const log = std.log.scoped(.profiling);

pub const Profiler = @import("profiling/Profiler.zig");

pub const output_path = "perf.json";

var prof: ?Profiler = null;
var mtx: std.Thread.Mutex = .{};

fn setup() !void {
    mtx.lock();
    defer mtx.unlock();

    if (prof != null) return;
    prof = try Profiler.init(output_path, std.heap.page_allocator);
}

pub fn begin(comptime func: anytype) void {
    if (!config.profiling) return;
    if (prof == null) setup() catch |err| {
        log.err("Failed to setup profiler: {s}", .{@errorName(err)});
        return;
    };
    (prof orelse unreachable).begin(func) catch |err| {
        log.err("Failed to begin profiling: {s}", .{@errorName(err)});
    };
}

pub fn stop() void {
    if (!config.profiling) return;
    (prof orelse return).stop() catch |err| {
        log.err("Failed to stop profiling: {s}", .{@errorName(err)});
    };
}

pub fn finalize() void {
    if (!config.profiling) return;
    const success = (prof orelse return).finalize();

    if (success) {
        log.info("Profiling data written to '{s}'", .{output_path});
    } else |err| {
        log.err("Failed to finalize profiling: {s}", .{@errorName(err)});
        prof.?.deinit();
    }
    prof = null;
}
