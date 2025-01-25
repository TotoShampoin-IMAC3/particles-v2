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

    const init_compute, const update_compute = block: {
        const file = try std.fs.cwd().readFileAlloc(init.allocator, "res/test.glsl", 8192);
        defer init.allocator.free(file);

        const init_compute = try shader.loadComputeMultiSources(2, .{ @embedFile("shaders/init.comp"), file });
        const update_compute = try shader.loadComputeMultiSources(2, .{ @embedFile("shaders/update.comp"), file });

        break :block .{ init_compute, update_compute };
    };
    defer {
        zgl.Program.delete(init_compute);
        zgl.Program.delete(update_compute);
    }

    const particles_count: c_uint = @intCast(particle.initial_array.len);
    const particles_now = particle_mesh.instance;
    const particles_init = init.particles_init_array;
    const particles_velocity = init.particles_velocity_array;

    const particle_view = particle_program.uniformLocation("u_view");
    const particle_projection = particle_program.uniformLocation("u_projection");

    const particle_compute_delta_time = update_compute.uniformLocation("u_delta_time");

    // ===== CAMERA =====

    const view_matrix = zlm.Mat4
        .createLookAt(zlm.Vec3.unitZ.scale(-5), zlm.Vec3.zero, zlm.Vec3.unitY);
    const perspective_zlm = zlm.Mat4
        .createPerspective(std.math.rad_per_deg * 45, 800.0 / 600.0, 0.1, 100.0);

    zgl.enable(.depth_test);

    zgl.Program.use(init_compute);
    zgl.bindBufferBase(.shader_storage_buffer, 0, particles_now);
    zgl.bindBufferBase(.shader_storage_buffer, 1, particles_init);
    zgl.bindBufferBase(.shader_storage_buffer, 2, particles_velocity);
    zgl.binding.dispatchCompute(particles_count, 1, 1);
    zgl.binding.memoryBarrier(zgl.binding.SHADER_STORAGE_BARRIER_BIT);

    // ===== MAIN LOOP =====

    const start = glfw.getTime();
    while (glfw.windowShouldClose(init.window) == false) {
        const now = glfw.getTime();
        const delta = now - start;

        zgl.Program.use(update_compute);
        update_compute.uniform1f(particle_compute_delta_time, @floatCast(delta));

        zgl.Program.use(particle_program);
        particle_program.uniformMatrix4(particle_view, false, &.{view_matrix.fields});
        particle_program.uniformMatrix4(particle_projection, false, &.{perspective_zlm.fields});

        zgl.clear(.{ .color = true, .depth = true });

        zgl.Program.use(update_compute);
        zgl.bindBufferBase(.shader_storage_buffer, 0, particles_now);
        zgl.bindBufferBase(.shader_storage_buffer, 1, particles_init);
        zgl.bindBufferBase(.shader_storage_buffer, 2, particles_velocity);
        zgl.binding.dispatchCompute(particles_count, 1, 1);
        zgl.binding.memoryBarrier(zgl.binding.SHADER_STORAGE_BARRIER_BIT);

        zgl.cullFace(.back);

        zgl.Program.use(particle_program);
        zgl.VertexArray.bind(particle_mesh.vao);
        zgl.drawElementsInstanced(.triangles, 6, .unsigned_int, 0, particle.initial_array.len);

        glfw.pollEvents();
        glfw.swapBuffers(init.window);
    }
}
