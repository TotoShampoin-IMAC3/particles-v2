const std = @import("std");
const glfw = @import("glfw");
const zgl = @import("zgl");
const imgui = @import("imgui.zig");

const alloc = @import("managers/allocator.zig");
const particle = @import("particle.zig");

pub var window: *glfw.Window = undefined;

const WINDOW_WIDTH = 1280;
const WINDOW_HEIGHT = 720;

pub fn init() !void {
    try alloc.init();
    try glfw.init();
    // glfw.windowHint(glfw.Resizable, 0);
    window = try glfw.createWindow(1280, 720, "Particles", null, null);
    glfw.makeContextCurrent(window);
    try loadGl();
    try particle.init();
    try imgui.initContext();
}
pub fn deinit() void {
    imgui.shutdownContext();
    particle.deinit();
    glfw.destroyWindow(window);
    glfw.terminate();
    alloc.deinit();
}

pub fn getProcAddressWrapper(
    comptime _: type,
    symbolName: [:0]const u8,
) ?*const anyopaque {
    return glfw.getProcAddress(symbolName);
}

pub fn loadGl() !void {
    try zgl.loadExtensions(void, getProcAddressWrapper);
}
