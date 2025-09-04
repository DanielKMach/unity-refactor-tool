const std = @import("std");
const testing = std.testing;
const urt = @import("urt");

const ComponentIterator = urt.runtime.ComponentIterator;

const data1 = @import("data1/info.zig");
const test_prefab = data1.test_prefab;
const empty_prefab = data1.empty_prefab;

test "patching" {
    const file = try std.fs.cwd().openFile(test_prefab.path, .{ .mode = .read_only });
    defer file.close();

    var iterator = try ComponentIterator.init(file, testing.allocator);
    defer iterator.deinit();

    const yaml = try std.fs.cwd().readFileAlloc(testing.allocator, "data1/Test.doc5.patched.yaml", std.math.maxInt(usize));
    defer testing.allocator.free(yaml);

    const comp: ComponentIterator.Component = .{
        .index = 5131,
        .len = 5507 - 5131,
        .document = yaml,
    };

    var writer = std.Io.Writer.Allocating.init(testing.allocator);
    defer writer.deinit();

    try iterator.patch(&writer.writer, &.{comp});

    const patched = try std.fs.cwd().readFileAlloc(testing.allocator, "data1/Test.patched.prefab", std.math.maxInt(usize));
    defer testing.allocator.free(patched);

    try testing.expectEqualStrings(patched, writer.written());
}
