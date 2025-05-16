const YamlFile = struct {
    path: []const u8,
    kv_pairs: []const KeyValuePair,
};

const KeyValuePair = struct {
    path: []const []const u8,
    value: []const u8,
};

pub const test_file: YamlFile = .{
    .path = "data2/file.yaml",
    .kv_pairs = &.{
        .{
            .path = &.{"a"},
            .value = "1",
        },
        .{
            .path = &.{"b"},
            .value = "2",
        },
        .{
            .path = &.{"c"},
            .value = "3",
        },
        .{
            .path = &.{ "d", "a" },
            .value = "4",
        },
        .{
            .path = &.{ "d", "b" },
            .value = "5",
        },
        .{
            .path = &.{ "d", "c", "a" },
            .value = "6",
        },
    },
};
