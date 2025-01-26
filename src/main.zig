const std = @import("std");
const glfw = @import("glfw");
const zgl = @import("zgl");
const zlm = @import("zlm");
const zimgui = @import("Zig-ImGui");

const init = @import("init.zig");
const imgui = @import("imgui.zig");
const alloc = @import("managers/allocator.zig");
const shader = @import("managers/shader.zig");
const shapes = @import("managers/shapes.zig");
const _particle = @import("managers/particle.zig");

const particle = @import("particle.zig");

pub fn main() !void {
    try init.init();
    defer init.deinit();

    try particle.loadProgram("res/test.glsl");
    defer particle.unloadProgram();

    var vsync = true;

    glfw.swapInterval(@intFromBool(vsync));

    const particle_program = particle.render_program;

    const particle_view = particle_program.uniformLocation("u_view");
    const particle_projection = particle_program.uniformLocation("u_projection");

    // ===== CAMERA =====

    const view_matrix = zlm.Mat4
        .createLookAt(zlm.Vec3.unitZ.scale(-5), zlm.Vec3.zero, zlm.Vec3.unitY);
    const perspective_zlm = zlm.Mat4
        .createPerspective(std.math.rad_per_deg * 45, 800.0 / 600.0, 0.1, 100.0);

    zgl.enable(.depth_test);

    particle.runProgram(particle.init_program.?);

    // ===== EVENTS =====

    imgui.start(init.window);

    // ===== MAIN LOOP =====

    const start = glfw.getTime();
    var last = start;
    while (glfw.windowShouldClose(init.window) == false) {
        const now = glfw.getTime();
        // const elapsed = now - start;
        const delta = now - last;

        zgl.Program.use(particle.update_program.?);
        particle.update_program.?.uniform1f(particle.uniform_delta_time.?, @floatCast(delta));

        zgl.Program.use(particle_program);
        particle_program.uniformMatrix4(particle_view, false, &.{view_matrix.fields});
        particle_program.uniformMatrix4(particle_projection, false, &.{perspective_zlm.fields});

        particle.runProgram(particle.update_program.?);

        zgl.clear(.{ .color = true, .depth = true });

        particle.drawParticles();

        imgui.beginDrawing();

        zimgui.SetNextWindowPosExt(zimgui.Vec2.init(0, 0), .{}, zimgui.Vec2.init(0, 0));
        if (zimgui.Begin("Particle System")) {
            zimgui.Text("%.3f ms/frame (%.1f FPS)", 1000.0 / delta, 1.0 / delta);
            if (zimgui.Checkbox("VSync", &vsync)) {
                glfw.swapInterval(@intFromBool(vsync));
            }
            if (zimgui.Button("Reset particles")) {
                particle.runProgram(particle.init_program.?);
            }
            zimgui.End();
        }

        imgui.endDrawing();

        glfw.pollEvents();
        glfw.swapBuffers(init.window);

        last = now;
    }
}
