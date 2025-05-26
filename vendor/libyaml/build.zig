const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const include = b.path("lib/include");
    const src = b.path("lib/src");

    const lib = b.addStaticLibrary(.{
        .name = "libyaml",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib.addIncludePath(include);
    lib.addCSourceFiles(.{
        .root = src,
        .files = &.{
            "api.c",
            "dumper.c",
            "emitter.c",
            "loader.c",
            "parser.c",
            "reader.c",
            "scanner.c",
            "writer.c",
        },
    });

    lib.root_module.addCMacro("YAML_VERSION_STRING", "\"1.1\"");
    lib.root_module.addCMacro("YAML_VERSION_MAJOR", "1");
    lib.root_module.addCMacro("YAML_VERSION_MINOR", "1");
    lib.root_module.addCMacro("YAML_VERSION_PATCH", "0");

    const header = b.addTranslateC(.{
        .root_source_file = include.path(b, "yaml.h"),
        .target = target,
        .optimize = optimize,
    });

    const mod = header.addModule("libyaml");
    mod.linkLibrary(lib);
}
