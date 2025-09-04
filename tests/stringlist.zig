const std = @import("std");
const urt = @import("urt");
const testing = std.testing;

const StringList = urt.runtime.StringList;

test "init and deinit" {
    var list = try StringList.init(testing.allocator);
    defer list.deinit();

    try list.push("Hello");
    try list.push("World");

    try testing.expectEqual(2, list.length());
}

test "push and pop" {
    var list = try StringList.init(testing.allocator);
    defer list.deinit();

    try list.push("Hello");
    try list.push("World");

    try testing.expectEqual(2, list.length());
    try testing.expectEqualStrings("Hello", try list.get(0));
    try testing.expectEqualStrings("World", try list.get(1));

    const second = try list.pop(testing.allocator) orelse unreachable;
    defer testing.allocator.free(second);
    const first = try list.pop(testing.allocator) orelse unreachable;
    defer testing.allocator.free(first);

    try testing.expectEqual(0, list.length());
    try testing.expectEqualStrings("Hello", first);
    try testing.expectEqualStrings("World", second);
}

test "remove" {
    var list = try StringList.init(testing.allocator);
    defer list.deinit();

    try list.push("Hello");
    try list.push("World");
    try list.push("!");

    try list.remove(1); // Remove "World"

    try testing.expectEqual(2, list.length());
    try testing.expectEqualStrings("Hello", try list.get(0));
    try testing.expectEqualStrings("!", try list.get(1));

    try list.remove(0); // Remove "Hello"

    try testing.expectEqual(1, list.length());
    try testing.expectEqualStrings("!", try list.get(0));
}

test "pull" {
    var list = try StringList.init(testing.allocator);
    defer list.deinit();

    try list.push("Hello");
    try list.push("World");

    const popped = try list.pull(1, testing.allocator);
    defer testing.allocator.free(popped);

    try testing.expectEqual(1, list.length());
    try testing.expectEqualStrings("Hello", try list.get(0));
    try testing.expectEqualStrings("World", popped);
}

test "clear" {
    var list = try StringList.init(testing.allocator);
    defer list.deinit();

    try list.push("Hello");
    try list.push("World");

    list.clear();

    try testing.expectEqual(0, list.length());
}

test "error out of bounds" {
    var list = try StringList.init(testing.allocator);
    defer list.deinit();

    try list.push("Hello");

    try testing.expectError(error.OutOfBounds, list.get(1));
    try testing.expectError(error.OutOfBounds, list.set(1, "World"));
    try testing.expectError(error.OutOfBounds, list.remove(1));
    try testing.expectError(error.OutOfBounds, list.pull(1, testing.allocator));
}

test "error out of memory" {
    const list = StringList.init(testing.failing_allocator);
    try testing.expectError(error.OutOfMemory, list);
}
