const std = @import("std");
const zgl = @import("zgl");
const zglfw = @import("zglfw");
const zlm = @import("zlm");

const init = @import("init.zig");
const helper = @import("helper.zig");
const shapes = @import("shapes.zig");

const data = [_]helper.Vertex{
    .{ .position = .{ -0.5, 0.5, 0.0 }, .texcoord = .{ 0.0, 1.0 } },
    .{ .position = .{ 0.5, 0.5, 0.0 }, .texcoord = .{ 1.0, 1.0 } },
    .{ .position = .{ -0.5, -0.5, 0.0 }, .texcoord = .{ 0.0, 0.0 } },
    .{ .position = .{ 0.5, -0.5, 0.0 }, .texcoord = .{ 1.0, 0.0 } },
};
const indices = [_]u32{ 0, 2, 1, 2, 3, 1 };
const instances = [_]helper.Particle{
    .{ .position = .{ 0.0, 0.0, 0.0, 1.0 }, .speed = [_]f32{0.0} ** 4 },
    .{ .position = .{ 1.0, 1.0, 1.0, 1.0 }, .speed = [_]f32{0.0} ** 4 },
    .{ .position = .{ -1.0, -1.0, 2.0, 1.0 }, .speed = [_]f32{0.0} ** 4 },
    .{ .position = .{ -1.0, 1.0, 3.0, 1.0 }, .speed = [_]f32{0.0} ** 4 },
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

    var cube_mesh = helper.Mesh.create();
    defer cube_mesh.delete();
    shapes.setupAndFillCube(&cube_mesh);

    var particle_mesh = helper.InstancedMesh.create();
    defer particle_mesh.delete();
    helper.setupAndFillParticle(&particle_mesh, data[0..], indices[0..], instances[0..]);

    const mesh_program = try helper.loadShaders(
        @embedFile("shaders/mesh.vert"),
        @embedFile("shaders/mesh.frag"),
    );
    defer zgl.Program.delete(mesh_program);

    const particle_program = try helper.loadShaders(
        @embedFile("shaders/particle.vert"),
        @embedFile("shaders/particle.frag"),
    );
    defer zgl.Program.delete(particle_program);

    const view_matrix = zlm.Mat4.createLookAt(zlm.Vec3.unitZ.scale(-5), zlm.Vec3.zero, zlm.Vec3.unitY);
    const perspective_zlm = zlm.Mat4.createPerspective(
        std.math.rad_per_deg * 45,
        800.0 / 600.0,
        0.1,
        100.0,
    );

    const particle_compute = try helper.loadCompute(@embedFile("shaders/particle.comp"));
    defer zgl.Program.delete(particle_compute);

    zgl.Program.use(mesh_program);
    const mesh_model = mesh_program.uniformLocation("u_model");
    const mesh_view = mesh_program.uniformLocation("u_view");
    const mesh_projection = mesh_program.uniformLocation("u_projection");

    zgl.Program.use(particle_program);
    const particle_view = particle_program.uniformLocation("u_view");
    const particle_projection = particle_program.uniformLocation("u_projection");

    zgl.Program.use(particle_compute);
    const particle_compute_delta_time = particle_compute.uniformLocation("u_delta_time");

    zgl.enable(.depth_test);

    const start = zglfw.getTime();
    while (zglfw.windowShouldClose(window) == false) {
        const now = zglfw.getTime();
        const delta = now - start;

        const cube_model = zlm.Mat4.mul(
            zlm.Mat4.createAngleAxis(zlm.Vec3.one, @floatCast(now)),
            zlm.Mat4.createTranslation(zlm.vec3(3, 0, 5)),
        );

        zgl.Program.use(mesh_program);
        mesh_program.uniformMatrix4(mesh_model, false, &.{cube_model.fields});
        mesh_program.uniformMatrix4(mesh_view, false, &.{view_matrix.fields});
        mesh_program.uniformMatrix4(mesh_projection, false, &.{perspective_zlm.fields});
        zgl.Program.use(particle_program);
        particle_program.uniformMatrix4(particle_view, false, &.{view_matrix.fields});
        particle_program.uniformMatrix4(particle_projection, false, &.{perspective_zlm.fields});
        zgl.Program.use(particle_compute);
        particle_compute.uniform1f(particle_compute_delta_time, @floatCast(delta));

        zgl.clear(.{
            .color = true,
            .depth = true,
        });

        zgl.Program.use(particle_compute);
        zgl.bindBufferBase(.shader_storage_buffer, 0, particle_mesh.instance);
        zgl.binding.dispatchCompute(@intCast(particle_mesh.instance_count), 1, 1);
        zgl.binding.memoryBarrier(zgl.binding.SHADER_STORAGE_BARRIER_BIT);

        zgl.enable(.cull_face);
        zgl.cullFace(.front);

        zgl.Program.use(mesh_program);
        zgl.VertexArray.bind(cube_mesh.vao);
        zgl.drawElements(.triangles, cube_mesh.count, .unsigned_int, 0);

        zgl.cullFace(.back);

        zgl.Program.use(particle_program);
        zgl.VertexArray.bind(particle_mesh.vao);
        zgl.drawElementsInstanced(.triangles, 6, .unsigned_int, 0, instances.len);

        zglfw.pollEvents();
        zglfw.swapBuffers(window);
    }
}
