const std = @import("std");
const testing = std.testing;
const urt = @import("urt");

const Yaml = urt.runtime.Yaml;

const data1 = @import("data1/info.zig");
const data2 = @import("data2/info.zig");

const test_file = data2.test_file;

test "string parsing (buffer)" {
    const content = try std.fs.cwd().readFileAlloc(testing.allocator, test_file.path, std.math.maxInt(u16));
    defer testing.allocator.free(content);

    var yaml = Yaml.init(.{ .string = content }, null, testing.allocator);
    var buf: [256]u8 = undefined;

    for (test_file.kv_pairs) |kv| {
        try testing.expectEqualStrings(kv.value, (try yaml.get(kv.path, &buf)).?);
    }
}

test "string parsing (alloc)" {
    const content = try std.fs.cwd().readFileAlloc(testing.allocator, test_file.path, std.math.maxInt(u16));
    defer testing.allocator.free(content);

    var yaml = Yaml.init(.{ .string = content }, null, testing.allocator);

    for (test_file.kv_pairs) |kv| {
        const value = try yaml.getAlloc(kv.path, testing.allocator);
        defer testing.allocator.free(value.?);
        try testing.expectEqualStrings(kv.value, value.?);
    }
}

test "file reader parsing" {
    const file = try std.fs.cwd().openFile(test_file.path, .{ .mode = .read_only });
    defer file.close();
    const reader = file.reader();

    var yaml = Yaml.init(.{ .reader = reader.any() }, null, testing.allocator);
    var buf: [256]u8 = undefined;

    for (test_file.kv_pairs) |kv| {
        try file.seekTo(0);
        try testing.expectEqualStrings(kv.value, (try yaml.get(kv.path, &buf)).?);
    }
}

test "buffered reader parsing" {
    const file = try std.fs.cwd().openFile(test_file.path, .{ .mode = .read_only });
    defer file.close();
    const freader = file.reader();

    var bufrdr = std.io.bufferedReader(freader);
    const reader = bufrdr.reader();

    var yaml = Yaml.init(.{ .reader = reader.any() }, null, testing.allocator);
    var buf: [256]u8 = undefined;

    for (test_file.kv_pairs) |kv| {
        try file.seekTo(0);
        try testing.expectEqualStrings(kv.value, (try yaml.get(kv.path, &buf)).?);
    }
}

test "match script guid" {
    for (data1.test_prefab.components) |doc| {
        var yaml = Yaml.init(.{ .string = doc.content }, null, testing.allocator);

        const result = try yaml.matchScriptGUID(doc.guid orelse "");
        try testing.expect((doc.guid != null) == result);
    }
}

test "out of memory" {
    const content = try std.fs.cwd().readFileAlloc(testing.allocator, test_file.path, std.math.maxInt(u16));
    defer testing.allocator.free(content);

    var yaml = Yaml.init(.{ .string = content }, null, testing.failing_allocator);
    var buf: [256]u8 = undefined;

    const result = yaml.get(&.{"a"}, &buf);
    try testing.expectError(error.OutOfMemory, result);
}
