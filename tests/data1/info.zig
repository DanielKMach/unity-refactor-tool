const Prefab = struct {
    path: []const u8,
    components: []const Component,
};

const Component = struct {
    path: []const u8,
    content: []const u8,
    guid: ?[]const u8,
};

pub const test_prefab: Prefab = .{
    .path = "data1/Test.prefab",
    .components = &.{
        .{
            .path = "data1/Test.doc0.yaml",
            .content = @embedFile("Test.doc0.yaml"),
            .guid = null,
        },
        .{
            .path = "data1/Test.doc1.yaml",
            .content = @embedFile("Test.doc1.yaml"),
            .guid = null,
        },
        .{
            .path = "data1/Test.doc2.yaml",
            .content = @embedFile("Test.doc2.yaml"),
            .guid = null,
        },
        .{
            .path = "data1/Test.doc3.yaml",
            .content = @embedFile("Test.doc3.yaml"),
            .guid = "4750e0cf3c0c6454d9834ea56a3898a0",
        },
        .{
            .path = "data1/Test.doc4.yaml",
            .content = @embedFile("Test.doc4.yaml"),
            .guid = "9b5f4716637736c43b4cb802eb5cabfe",
        },
        .{
            .path = "data1/Test.doc5.yaml",
            .content = @embedFile("Test.doc5.yaml"),
            .guid = "6c8e8358cefa7764d9b8836e3b251a31",
        },
    },
};

pub const empty_prefab: Prefab = .{
    .path = "data1/Empty.prefab",
    .components = &.{},
};
