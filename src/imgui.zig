const std = @import("std");
const alloc = @import("managers/allocator.zig");
const glfw = @import("glfw");
pub const zimgui = @import("Zig-ImGui");

var ini_filename: ?[:0]u8 = null;

pub extern fn ImGui_ImplGlfw_InitForOpenGL(window: *glfw.Window, install_callbacks: bool) bool;
pub extern fn ImGui_ImplGlfw_NewFrame() void;
pub extern fn ImGui_ImplGlfw_Shutdown() void;
pub extern fn ImGui_ImplOpenGL3_Init(glsl_version: ?[*:0]const u8) bool;
pub extern fn ImGui_ImplOpenGL3_Shutdown() void;
pub extern fn ImGui_ImplOpenGL3_NewFrame() void;
pub extern fn ImGui_ImplOpenGL3_RenderDrawData(draw_data: *const anyopaque) void;

pub fn initContext() !void {
    if (ini_filename == null) {
        const dir = try std.fs.selfExeDirPathAlloc(alloc.allocator);
        defer alloc.allocator.free(dir);
        ini_filename = try std.mem.concatWithSentinel(alloc.allocator, u8, &.{ dir, "/imgui.ini" }, 0);
    }
    const context = zimgui.CreateContext();
    zimgui.SetCurrentContext(context);
    {
        const io = zimgui.GetIO();
        // io.IniFilename = null;
        io.IniFilename = ini_filename.?;
        io.ConfigFlags = zimgui.ConfigFlags.with(
            io.ConfigFlags,
            .{ .NavEnableKeyboard = true, .NavEnableGamepad = true },
        );
    }
}
pub fn shutdownContext() void {
    zimgui.DestroyContext();
    if (ini_filename) |file| {
        alloc.allocator.free(file);
        ini_filename = null;
    }
}

pub fn start(window: *glfw.Window) void {
    _ = ImGui_ImplGlfw_InitForOpenGL(window, true);
    _ = ImGui_ImplOpenGL3_Init("#version 330");
}
pub fn stop() void {
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
}

pub fn beginDrawing() void {
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    zimgui.NewFrame();
}
pub fn endDrawing() void {
    zimgui.Render();
    ImGui_ImplOpenGL3_RenderDrawData(zimgui.GetDrawData());
}
