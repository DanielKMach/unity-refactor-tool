const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const include = b.path("lib/include");
    const src = b.path("lib/src");

    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    mod.addIncludePath(include);
    mod.addCSourceFiles(.{
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
    mod.addCMacro("YAML_VERSION_STRING", "\"1.1\"");
    mod.addCMacro("YAML_VERSION_MAJOR", "1");
    mod.addCMacro("YAML_VERSION_MINOR", "1");
    mod.addCMacro("YAML_VERSION_PATCH", "0");

    const lib = b.addLibrary(.{
        .name = "libyaml",
        .root_module = mod,
    });

    const header = b.addTranslateC(.{
        .root_source_file = include.path(b, "yaml.h"),
        .target = target,
        .optimize = optimize,
    });

    const libyaml = header.addModule("libyaml");
    libyaml.linkLibrary(lib);
}
