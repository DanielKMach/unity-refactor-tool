const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const install_step = b.getInstallStep();
    const run_step = b.step("run", "Run the CLI");
    const test_step = b.step("test", "Run unit tests");

    const exe = b.addExecutable(.{
        .name = "urt",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const yaml = b.dependency("yaml", .{
        .target = target,
        .optimize = .ReleaseSafe,
    });

    exe.root_module.addImport("yaml", yaml.module("yaml"));

    const install = b.addInstallArtifact(exe, .{});
    install_step.dependOn(&install.step);

    const run = b.addRunArtifact(exe);
    run.step.dependOn(install_step);
    run_step.dependOn(&run.step);

    if (b.args) |args| {
        run.addArgs(args);
    }

    const tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_tests = b.addRunArtifact(tests);
    test_step.dependOn(&run_tests.step);
}
