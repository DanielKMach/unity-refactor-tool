const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const profile = b.option(bool, "profile", "Enable profiling") orelse false;

    const install_step = b.getInstallStep();
    const run_step = b.step("run", "Run the CLI");
    const test_step = b.step("test", "Run unit tests");
    const check_step = b.step("check", "Check the code for errors");

    const libyaml = b.dependency("libyaml", .{
        .target = target,
        .optimize = optimize,
    });

    // main executable
    const exe = b.addExecutable(.{
        .name = "urt",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.linkLibrary(libyaml.artifact("libyaml"));
    exe.root_module.addIncludePath(libyaml.path("lib/include"));

    const options = b.addOptions();
    options.addOption(bool, "profiling", profile);
    exe.root_module.addImport("config", options.createModule());

    const install_urt = b.addInstallArtifact(exe, .{});
    install_step.dependOn(&install_urt.step);
    check_step.dependOn(&install_urt.step);

    const run_urt = b.addRunArtifact(exe);
    run_urt.step.dependOn(install_step);
    run_step.dependOn(&run_urt.step);

    if (b.args) |args| {
        run_urt.addArgs(args);
    }

    // Tests
    const tests = b.addTest(.{
        .root_source_file = b.path("tests/tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    const urt_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    urt_mod.linkLibrary(libyaml.artifact("libyaml"));
    urt_mod.addIncludePath(libyaml.path("lib/include"));
    tests.root_module.addImport("urt", urt_mod);

    const run_tests = b.addRunArtifact(tests);
    run_tests.setCwd(b.path("tests"));

    test_step.dependOn(&run_tests.step);
}
