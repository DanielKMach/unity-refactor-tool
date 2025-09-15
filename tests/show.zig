const std = @import("std");
const testing = std.testing;
const usrl = @import("usrl");

const Show = usrl.Stmt.Show;
const data1 = @import("data1/info.zig");

test "guid test" {
    inline for (data1.test_prefab.components) |comp| {
        var yaml = usrl.runtime.Yaml.init(.{ .string = comp.content }, null, testing.allocator);
        if (comp.guid) |g| {
            const guid = usrl.runtime.GUID{
                .value = g,
                .source = null,
            };
            try testing.expect(try Show.matchScriptOrPrefabGUID(&.{guid}, &yaml));
        }
    }
}
