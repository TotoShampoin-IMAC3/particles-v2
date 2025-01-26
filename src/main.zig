const std = @import("std");
const glfw = @import("glfw");
const zgl = @import("zgl");
const zlm = @import("zlm");
const zgui = @import("zgui");

const init = @import("init.zig");
const alloc = @import("managers/allocator.zig");
const shader = @import("managers/shader.zig");
const shapes = @import("managers/shapes.zig");
const _particle = @import("managers/particle.zig");

const particle = @import("particle.zig");

pub fn main() !void {
    try init.init();
    defer init.deinit();

    zgui.init(alloc.allocator);
    defer zgui.deinit();

    zgui.backend.init(init.window);
    defer zgui.backend.deinit();

    try particle.loadProgram("res/test.glsl");
    defer particle.unloadProgram();

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

    // ===== MAIN LOOP =====

    const start = glfw.getTime();
    while (glfw.windowShouldClose(init.window) == false) {
        const now = glfw.getTime();
        const delta = now - start;

        if (particle.update_program) |program| {
            zgl.Program.use(program);
            program.uniform1f(particle.uniform_delta_time.?, @floatCast(delta));

            particle.runProgram(program);
        }

        zgl.clear(.{ .color = true, .depth = true });

        zgl.Program.use(particle_program);
        particle_program.uniformMatrix4(particle_view, false, &.{view_matrix.fields});
        particle_program.uniformMatrix4(particle_projection, false, &.{perspective_zlm.fields});

        particle.drawParticles();

        zgui.backend.newFrame(800, 600);

        zgui.setNextWindowPos(.{ .x = 0, .y = 0 });
        if (zgui.begin("My window", .{ .flags = .{ .no_move = true } })) {
            zgui.text("Hello, world!", .{});
        }

        zgui.end();
        zgui.backend.draw();

        glfw.pollEvents();
        glfw.swapBuffers(init.window);
    }
}
