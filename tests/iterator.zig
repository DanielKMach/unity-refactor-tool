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

    var iterator = ComponentIterator.init(file, testing.allocator);
    defer iterator.deinit();

    var i: usize = 0;
    while (try iterator.next()) |comp| : (i += 1) {
        const expected = test_prefab.components[i].content;
        try testing.expectEqualStrings(expected, comp.document);
    }
}

test "empty asset" {
    const file = try std.fs.cwd().openFile(empty_prefab.path, .{ .mode = .read_only });
    defer file.close();

    var iterator = ComponentIterator.init(file, testing.allocator);
    defer iterator.deinit();

    var i: usize = 0;
    while (try iterator.next()) |_| {
        i += 1;
    }

    try testing.expectEqual(0, i);
}

test "leak on early return" {
    const file = try std.fs.cwd().openFile(test_prefab.path, .{ .mode = .read_only });
    defer file.close();

    var iterator = ComponentIterator.init(file, testing.allocator);
    defer iterator.deinit();

    var i: usize = 0;
    while (try iterator.next()) |_| {
        i += 1;
        if (i == 2) break;
    }
}

test "out of memory" {
    const file = try std.fs.cwd().openFile(test_prefab.path, .{ .mode = .read_only });
    defer file.close();

    var iterator = ComponentIterator.init(file, testing.failing_allocator);
    defer iterator.deinit();

    const result = iterator.next();
    try testing.expectError(error.OutOfMemory, result);
}
