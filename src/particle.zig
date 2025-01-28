const std = @import("std");
const zgl = @import("zgl");

const _alloc = @import("managers/allocator.zig");
const _mesh = @import("managers/mesh.zig");
const _shader = @import("managers/shader.zig");
const _particle = @import("managers/particle.zig");
const _vertex = @import("managers/vertex.zig");
const _shapes = @import("managers/shapes.zig");

pub const Particle = _particle.Particle;

const render_vertex_source = @embedFile("shaders/particle.vert");
const render_fragment_source = @embedFile("shaders/particle.frag");

const header_compute_source = @embedFile("shaders/header.comp");
const init_compute_source = @embedFile("shaders/init.comp");
const update_compute_source = @embedFile("shaders/update.comp");

pub var render_program: zgl.Program = undefined;

pub var init_program: ?zgl.Program = null;
pub var update_program: ?zgl.Program = null;
pub var uniforms: ?[]_shader.UniformName = null;

pub var uniform_delta_time: ?u32 = null;

pub var mesh: _mesh.Mesh = undefined;

pub var count: usize = 2;
pub var init_buffer: zgl.Buffer = undefined;
pub var now_buffer: zgl.Buffer = undefined;
pub var velocity_buffer: zgl.Buffer = undefined;
pub var init_velocity_buffer: zgl.Buffer = undefined;

pub fn init() !void {
    render_program = try _shader.loadShaders(
        @embedFile("shaders/particle.vert"),
        @embedFile("shaders/particle.frag"),
    );

    mesh = _mesh.Mesh.create();
    init_buffer = zgl.Buffer.create();
    now_buffer = zgl.Buffer.create();
    velocity_buffer = zgl.Buffer.create();
    init_velocity_buffer = zgl.Buffer.create();

    zgl.Buffer.bind(init_buffer, .shader_storage_buffer);
    zgl.namedBufferUninitialized(init_buffer, Particle, count, .dynamic_draw);
    zgl.Buffer.bind(now_buffer, .shader_storage_buffer);
    zgl.namedBufferUninitialized(now_buffer, Particle, count, .dynamic_draw);
    zgl.Buffer.bind(velocity_buffer, .shader_storage_buffer);
    zgl.namedBufferUninitialized(velocity_buffer, Particle, count, .dynamic_draw);
    zgl.Buffer.bind(init_velocity_buffer, .shader_storage_buffer);
    zgl.namedBufferUninitialized(init_velocity_buffer, Particle, count, .dynamic_draw);

    mesh.importMesh(_vertex.Vertex, _shapes.quad_vertices[0..], _shapes.quad_indices[0..]);

    _particle.setupMesh(&mesh, now_buffer);
}
pub fn deinit() void {
    zgl.Program.delete(render_program);
    _mesh.Mesh.delete(&mesh);
    zgl.Buffer.delete(init_buffer);
    zgl.Buffer.delete(now_buffer);
    zgl.Buffer.delete(velocity_buffer);
    zgl.Buffer.delete(init_velocity_buffer);
}

pub fn loadProgram(path: []const u8) !void {
    const file = try std.fs.cwd().readFileAlloc(_alloc.allocator, path, 65536);
    defer _alloc.allocator.free(file);

    unloadProgram();
    init_program = try _shader.loadComputeMultiSources(3, .{
        header_compute_source,
        file,
        init_compute_source,
    });
    update_program = try _shader.loadComputeMultiSources(3, .{
        header_compute_source,
        file,
        update_compute_source,
    });
    uniforms = try _shader.getUniformsFromSource(file);
    for (uniforms.?) |*uniform| {
        const name = uniform.name;
        const name_s = try std.mem
            .concatWithSentinel(_alloc.allocator, u8, &.{name}, 0);
        defer _alloc.allocator.free(name_s);
        uniform.locations = try _alloc.allocator.alloc(?u32, 2);
        uniform.locations[0] = init_program.?.uniformLocation(name_s);
        uniform.locations[1] = update_program.?.uniformLocation(name_s);
    }
    uniform_delta_time = update_program.?.uniformLocation("u_delta_time");
}
pub fn unloadProgram() void {
    if (init_program) |program| {
        zgl.Program.delete(program);
        init_program = null;
    }
    if (update_program) |program| {
        zgl.Program.delete(program);
        update_program = null;
    }
    if (uniforms != null) {
        _shader.UniformName.deleteAll(uniforms.?);
        uniforms = null;
    }
}

pub fn runProgram() void {
    zgl.bindBufferBase(.shader_storage_buffer, 0, now_buffer);
    zgl.bindBufferBase(.shader_storage_buffer, 1, init_buffer);
    zgl.bindBufferBase(.shader_storage_buffer, 2, velocity_buffer);
    zgl.bindBufferBase(.shader_storage_buffer, 3, init_velocity_buffer);
    zgl.binding.dispatchCompute(@intCast(count), 1, 1);
    zgl.binding.memoryBarrier(zgl.binding.SHADER_STORAGE_BARRIER_BIT);
}

pub fn runInit() void {
    if (init_program == null) return;
    zgl.Program.use(init_program.?);
    runProgram();
}
pub fn runUpdate(delta: f32) void {
    if (update_program == null) return;
    zgl.Program.use(update_program.?);
    update_program.?.uniform1f(uniform_delta_time.?, delta);
    runProgram();
}

pub fn drawParticles() void {
    zgl.Program.use(render_program);
    mesh.drawInstanced(count);
}

pub fn setUniform(uniform: _shader.UniformName) void {
    if (init_program == null or update_program == null) return;
    switch (uniform.type) {
        .int => {
            if (uniform.locations[0]) |location|
                init_program.?.uniform1i(location, uniform.value.int);
            if (uniform.locations[1]) |location|
                update_program.?.uniform1i(location, uniform.value.int);
        },
        .float => {
            if (uniform.locations[0]) |location|
                init_program.?.uniform1f(location, uniform.value.float);
            if (uniform.locations[1]) |location|
                update_program.?.uniform1f(location, uniform.value.float);
        },
        .vec2 => {
            if (uniform.locations[0]) |location|
                init_program.?.uniform2f(location, uniform.value.vec2[0], uniform.value.vec2[1]);
            if (uniform.locations[1]) |location|
                update_program.?.uniform2f(location, uniform.value.vec2[0], uniform.value.vec2[1]);
        },
        .vec3 => {
            if (uniform.locations[0]) |location|
                init_program.?.uniform3f(location, uniform.value.vec3[0], uniform.value.vec3[1], uniform.value.vec3[2]);
            if (uniform.locations[1]) |location|
                update_program.?.uniform3f(location, uniform.value.vec3[0], uniform.value.vec3[1], uniform.value.vec3[2]);
        },
        .vec4 => {
            if (uniform.locations[0]) |location|
                init_program.?.uniform4f(location, uniform.value.vec4[0], uniform.value.vec4[1], uniform.value.vec4[2], uniform.value.vec4[3]);
            if (uniform.locations[1]) |location|
                update_program.?.uniform4f(location, uniform.value.vec4[0], uniform.value.vec4[1], uniform.value.vec4[2], uniform.value.vec4[3]);
        },
    }
}
