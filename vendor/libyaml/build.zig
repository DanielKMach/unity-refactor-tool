const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "libyaml",
        .target = target,
        .optimize = optimize,
    });

    lib.linkLibC();
    lib.addSystemIncludePath(b.path("lib/include"));
    lib.addCSourceFiles(.{
        .root = b.path("lib/src"),
        .files = &.{
            "api.c",
            "dumper.c",
            "emitter.c",
            "loader.c",
            "parser.c",
            "reader.c",
            "scanner.c",
            "writer.c",
            "yaml_private.h",
        },
    });

    lib.root_module.addCMacro("YAML_VERSION_STRING", "\"1.1\"");
    lib.root_module.addCMacro("YAML_VERSION_MAJOR", "1");
    lib.root_module.addCMacro("YAML_VERSION_MINOR", "1");
    lib.root_module.addCMacro("YAML_VERSION_PATCH", "0");

    b.installArtifact(lib);
}
