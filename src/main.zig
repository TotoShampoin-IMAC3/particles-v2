const std = @import("std");
const zgl = @import("zgl");
const glfw = @import("glfw");

fn getProcAddressWrapper(comptime _: type, symbolName: [:0]const u8) ?*const anyopaque {
    return glfw.getProcAddress(symbolName);
}

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    const window = try glfw.createWindow(800, 600, "Hello, World!", null, null);
    defer glfw.destroyWindow(window);

    glfw.makeContextCurrent(window);

    try zgl.loadExtensions(void, getProcAddressWrapper);

    while (glfw.windowShouldClose(window) == false) {
        zgl.clear(.{
            .color = true,
            .depth = true,
        });

        glfw.pollEvents();
        glfw.swapBuffers(window);
    }
}
