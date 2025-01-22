const std = @import("std");
const zgl = @import("zgl");
const zglfw = @import("zglfw");

fn getProcAddressWrapper(
    comptime _: type,
    symbolName: [:0]const u8,
) ?*const anyopaque {
    return zglfw.getProcAddress(symbolName);
}

pub fn main() !void {
    try zglfw.init();
    defer zglfw.terminate();

    const window = try zglfw.createWindow(800, 600, "Hello, World!", null, null);
    defer zglfw.destroyWindow(window);

    zglfw.makeContextCurrent(window);

    try zgl.loadExtensions(void, getProcAddressWrapper);

    while (zglfw.windowShouldClose(window) == false) {
        zgl.clear(.{
            .color = true,
            .depth = true,
        });

        zglfw.pollEvents();
        zglfw.swapBuffers(window);
    }
}
