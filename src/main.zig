const std = @import("std");
const glfw = @import("glfw");
const zgl = @import("zgl");
const zlm = @import("zlm");

const init = @import("init.zig");
const shader = @import("shader.zig");
const shapes = @import("shapes.zig");
const particle = @import("particle.zig");

pub fn main() !void {
    try init.init();
    defer init.deinit();

    const particle_mesh = init.particle_mesh;
    const particle_program = init.particle_program;
    const particle_compute = init.particle_compute;

    zgl.Program.use(particle_program);
    const particle_view =
        particle_program.uniformLocation("u_view");
    const particle_projection =
        particle_program.uniformLocation("u_projection");

    zgl.Program.use(particle_compute);
    const particle_compute_delta_time =
        particle_compute.uniformLocation("u_delta_time");

    // ===== CAMERA =====

    const view_matrix = zlm.Mat4
        .createLookAt(zlm.Vec3.unitZ.scale(-5), zlm.Vec3.zero, zlm.Vec3.unitY);
    const perspective_zlm = zlm.Mat4
        .createPerspective(std.math.rad_per_deg * 45, 800.0 / 600.0, 0.1, 100.0);

    zgl.enable(.depth_test);

    // ===== MAIN LOOP =====

    const start = glfw.getTime();
    while (glfw.windowShouldClose(init.window) == false) {
        const now = glfw.getTime();
        const delta = now - start;

        zgl.Program.use(particle_compute);
        particle_compute.uniform1f(particle_compute_delta_time, @floatCast(delta));

        zgl.Program.use(particle_program);
        particle_program.uniformMatrix4(particle_view, false, &.{view_matrix.fields});
        particle_program.uniformMatrix4(particle_projection, false, &.{perspective_zlm.fields});

        zgl.clear(.{ .color = true, .depth = true });

        zgl.Program.use(particle_compute);
        zgl.bindBufferBase(.shader_storage_buffer, 0, particle_mesh.instance);
        zgl.binding.dispatchCompute(@intCast(particle_mesh.instance_count), 1, 1);
        zgl.binding.memoryBarrier(zgl.binding.SHADER_STORAGE_BARRIER_BIT);

        zgl.cullFace(.back);

        zgl.Program.use(particle_program);
        zgl.VertexArray.bind(particle_mesh.vao);
        zgl.drawElementsInstanced(.triangles, 6, .unsigned_int, 0, particle.initial_array.len);

        glfw.pollEvents();
        glfw.swapBuffers(init.window);
    }
}
