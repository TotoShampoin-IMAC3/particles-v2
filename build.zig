const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "particles",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zgl = b.dependency("zgl", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zgl", zgl.module("zgl"));

    const zglfw = b.dependency("zglfw", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zglfw", zglfw.module("glfw"));

    const zlm = b.dependency("zlm", .{
        // .target = target,
        // .optimize = optimize,
    });
    exe.root_module.addImport("zlm", zlm.module("zlm"));

    const glfw = b.dependency("glfw", .{
        .target = target,
        .optimize = optimize,
        .opengl = true,
    });
    exe.root_module.addIncludePath(glfw.path("include"));
    exe.root_module.linkLibrary(glfw.artifact("glfw"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
