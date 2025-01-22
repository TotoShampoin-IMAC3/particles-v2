const std = @import("std");
const zgl = @import("zgl");
const zglfw = @import("zglfw");

const init = @import("init.zig");
const helper = @import("helper.zig");

const data = [_]helper.Vertex{
    .{ .position = .{ -0.5, -0.5, 0.0 }, .texcoord = .{ 0.0, 0.0 } },
    .{ .position = .{ 0.5, -0.5, 0.0 }, .texcoord = .{ 1.0, 0.0 } },
    .{ .position = .{ -0.5, 0.5, 0.0 }, .texcoord = .{ 0.0, 1.0 } },
    .{ .position = .{ 0.5, 0.5, 0.0 }, .texcoord = .{ 1.0, 1.0 } },
};
const indices = [_]u32{ 0, 1, 2, 1, 2, 3 };
const instances = [_]helper.Particle{
    .{ .position = .{ 0.0, 0.0, 0.0 } },
    .{ .position = .{ 0.5, 0.5, 0.0 } },
    .{ .position = .{ -0.5, -0.5, 0.0 } },
    .{ .position = .{ -0.5, 0.5, 0.0 } },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() == .leak)
            std.debug.print("Memory leak detected!\n", .{});
    }
    init.allocator = gpa.allocator();

    try zglfw.init();
    defer zglfw.terminate();

    const window = try zglfw.createWindow(800, 600, "Hello, World!", null, null);
    defer zglfw.destroyWindow(window);
    zglfw.makeContextCurrent(window);
    try init.loadGl();

    const program = try helper.loadShaders(
        @embedFile("shaders/basic.vert"),
        @embedFile("shaders/basic.frag"),
    );
    defer zgl.Program.delete(program);

    var mesh = helper.InstancedMesh.create();
    defer mesh.delete();
    helper.setupAndFillParticle(&mesh, data[0..], indices[0..], instances[0..]);

    zgl.Program.use(program);
    zgl.VertexArray.bind(mesh.vao);

    zgl.enable(.depth_test);

    while (zglfw.windowShouldClose(window) == false) {
        zgl.clear(.{
            .color = true,
            .depth = true,
        });

        zgl.drawElementsInstanced(.triangles, 6, .unsigned_int, 0, instances.len);

        zglfw.pollEvents();
        zglfw.swapBuffers(window);
    }
}
