const std = @import("std");
const glfw = @import("glfw");
pub const zimgui = @import("Zig-ImGui");

pub extern fn ImGui_ImplGlfw_InitForOpenGL(window: *glfw.Window, install_callbacks: bool) bool;
pub extern fn ImGui_ImplGlfw_NewFrame() void;
pub extern fn ImGui_ImplGlfw_Shutdown() void;
pub extern fn ImGui_ImplOpenGL3_Init(glsl_version: ?[*:0]const u8) bool;
pub extern fn ImGui_ImplOpenGL3_Shutdown() void;
pub extern fn ImGui_ImplOpenGL3_NewFrame() void;
pub extern fn ImGui_ImplOpenGL3_RenderDrawData(draw_data: *const anyopaque) void;

pub fn initContext() void {
    const context = zimgui.CreateContext();
    zimgui.SetCurrentContext(context);
    {
        const io = zimgui.GetIO();
        io.IniFilename = null;
        io.ConfigFlags = zimgui.ConfigFlags.with(
            io.ConfigFlags,
            .{ .NavEnableKeyboard = true, .NavEnableGamepad = true },
        );
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
