const std = @import("std");
const testing = std.testing;
const urt = @import("urt");

const ComponentIterator = urt.runtime.ComponentIterator;

const data1 = @import("data1/info.zig");
const test_prefab = data1.test_prefab;
const empty_prefab = data1.empty_prefab;

test "component iteration" {
    const file = try std.fs.cwd().openFile(test_prefab.path, .{ .mode = .read_only });
    defer file.close();

    var iterator = try ComponentIterator.init(file, testing.allocator);
    defer iterator.deinit();

    inline for (test_prefab.components) |comp| {
        const got = try iterator.next();
        try testing.expect(got != null);
        try testing.expectEqualStrings(comp.content, got.?.document);
    }
    try testing.expectEqual(null, try iterator.next());
}

test "empty asset" {
    const file = try std.fs.cwd().openFile(empty_prefab.path, .{ .mode = .read_only });
    defer file.close();

    var iterator = try ComponentIterator.init(file, testing.allocator);
    defer iterator.deinit();

    try testing.expectEqual(null, try iterator.next());
}

test "free on early return" {
    const file = try std.fs.cwd().openFile(test_prefab.path, .{ .mode = .read_only });
    defer file.close();

    var iterator = try ComponentIterator.init(file, testing.allocator);
    defer iterator.deinit();

    try testing.expect(try iterator.next() != null);
    try testing.expect(try iterator.next() != null);
}

test "out of memory" {
    const file = try std.fs.cwd().openFile(test_prefab.path, .{ .mode = .read_only });
    defer file.close();

    const iterator = ComponentIterator.init(file, testing.failing_allocator);
    try testing.expectError(error.OutOfMemory, iterator);
}
