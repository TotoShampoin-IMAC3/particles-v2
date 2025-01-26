const std = @import("std");
const zimgui = @import("./build-zimgui.zig");

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
    exe.root_module.addImport("glfw", zglfw.module("glfw"));

    const zlm = b.dependency("zlm", .{});
    exe.root_module.addImport("zlm", zlm.module("zlm"));

    const glfw = b.dependency("glfw", .{
        .target = target,
        .optimize = optimize,
        .opengl = true,
    });
    exe.root_module.addIncludePath(glfw.path("include"));
    exe.root_module.linkLibrary(glfw.artifact("glfw"));

    const ZigImGui_dep = b.dependency("ZigImGui", .{
        .target = target,
        .optimize = optimize,
        .enable_freetype = true,
        .enable_lunasvg = false,
    });
    const imgui_dep = ZigImGui_dep.builder.dependency("imgui", .{ .target = target, .optimize = optimize });

    const imgui_glfw = zimgui.create_imgui_glfw_static_lib(
        b,
        target,
        optimize,
        glfw,
        imgui_dep,
        ZigImGui_dep,
    );
    const imgui_opengl = zimgui.create_imgui_opengl_static_lib(
        b,
        target,
        optimize,
        imgui_dep,
        ZigImGui_dep,
    );

    exe.root_module.addImport("Zig-ImGui", ZigImGui_dep.module("Zig-ImGui"));
    exe.linkLibrary(imgui_glfw);
    exe.linkLibrary(imgui_opengl);

    b.installArtifact(exe);

    const install = b.getInstallStep();
    const install_data = b.addInstallDirectory(.{
        .source_dir = b.path("res"),
        .install_dir = .{ .prefix = {} },
        .install_subdir = "bin/res",
    });
    install.dependOn(&install_data.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
