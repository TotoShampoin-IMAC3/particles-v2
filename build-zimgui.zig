const std = @import("std");
const ZigImGui_build_script = @import("ZigImGui");

pub fn create_imgui_opengl_static_lib(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    imgui_dep: *std.Build.Dependency,
    ZigImGui_dep: *std.Build.Dependency,
) *std.Build.Step.Compile {
    // compile the desired backend into a separate static library
    const imgui_opengl = b.addStaticLibrary(.{
        .name = "imgui_opengl",
        .target = target,
        .optimize = optimize,
    });
    imgui_opengl.root_module.link_libcpp = true;
    // link in the necessary symbols from ImGui base
    imgui_opengl.linkLibrary(ZigImGui_dep.artifact("cimgui"));

    // use the same override DEFINES that the ImGui base does
    for (ZigImGui_build_script.IMGUI_C_DEFINES) |c_define| {
        imgui_opengl.root_module.addCMacro(c_define[0], c_define[1]);
    }

    // ensure the backend has access to the ImGui headers it expects
    imgui_opengl.addIncludePath(imgui_dep.path("."));
    imgui_opengl.addIncludePath(imgui_dep.path("backends/"));

    imgui_opengl.addCSourceFile(.{
        .file = imgui_dep.path("backends/imgui_impl_opengl3.cpp"),
        // use the same compile flags that the ImGui base does
        .flags = ZigImGui_build_script.IMGUI_C_FLAGS,
    });

    return imgui_opengl;
}

pub fn create_imgui_glfw_static_lib(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    glfw_dep: *std.Build.Dependency,
    imgui_dep: *std.Build.Dependency,
    ZigImGui_dep: *std.Build.Dependency,
    // lazy_xcode_dep: ?*std.Build.Dependency,
) *std.Build.Step.Compile {
    // compile the desired backend into a separate static library
    const imgui_glfw = b.addStaticLibrary(.{
        .name = "imgui_glfw",
        .target = target,
        .optimize = optimize,
    });
    imgui_glfw.linkLibCpp();
    // link in the necessary symbols from ImGui base
    imgui_glfw.linkLibrary(ZigImGui_dep.artifact("cimgui"));

    // use the same override DEFINES that the ImGui base does
    for (ZigImGui_build_script.IMGUI_C_DEFINES) |c_define| {
        imgui_glfw.root_module.addCMacro(c_define[0], c_define[1]);
    }

    // ensure only a basic version of glfw is given to `imgui_impl_glfw.cpp` to
    // ensure it can be loaded with no extra headers.
    imgui_glfw.root_module.addCMacro("GLFW_INCLUDE_NONE", "1");

    // ensure the backend has access to the ImGui headers it expects
    imgui_glfw.addIncludePath(imgui_dep.path("."));
    imgui_glfw.addIncludePath(imgui_dep.path("backends/"));

    // Linking a compiled artifact auto-includes its headers now, fetch it here
    // so Dear ImGui's GLFW implementation can use it.
    const glfw_lib = glfw_dep.artifact("glfw");
    imgui_glfw.linkLibrary(glfw_lib);

    imgui_glfw.addCSourceFile(.{
        .file = imgui_dep.path("backends/imgui_impl_glfw.cpp"),
        // use the same compile flags that the ImGui base does
        .flags = ZigImGui_build_script.IMGUI_C_FLAGS,
    });

    return imgui_glfw;
}
