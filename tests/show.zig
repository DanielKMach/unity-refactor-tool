const std = @import("std");
const testing = std.testing;
const urt = @import("urt");

const Show = urt.stmt.Show;
const data1 = @import("data1/info.zig");

test "guid test" {
    inline for (data1.test_prefab.components) |comp| {
        var yaml = urt.runtime.Yaml.init(.{ .string = comp.content }, null, testing.allocator);
        if (comp.guid) |g| {
            const guid = urt.runtime.GUID{
                .value = g,
                .source = null,
            };
            try testing.expect(try Show.matchScriptOrPrefabGUID(&.{guid}, &yaml));
        }
    }
}
