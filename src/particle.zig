const std = @import("std");
const zgl = @import("zgl");

const _alloc = @import("managers/allocator.zig");
const _mesh = @import("managers/mesh.zig");
const _shader = @import("managers/shader.zig");
const _particle = @import("managers/particle.zig");
const _vertex = @import("managers/vertex.zig");
const _shapes = @import("managers/shapes.zig");

pub const Particle = _particle.Particle;

pub const ParticleAppearance = enum {
    square,
    circle,
    texture,

    pub fn toString(self: ParticleAppearance) [:0]const u8 {
        return switch (self) {
            .square => "square",
            .circle => "circle",
            .texture => "texture",
        };
    }
    pub const all_values = [_]ParticleAppearance{ .square, .circle, .texture };
};

const render_vertex_source = @embedFile("shaders/particle.vert");
const render_fragment_source = @embedFile("shaders/particle.frag");

const header_compute_source = @embedFile("shaders/header.comp");
const init_compute_source = @embedFile("shaders/init.comp");
const update_compute_source = @embedFile("shaders/update.comp");

pub var render_program: zgl.Program = undefined;

pub var init_program: ?zgl.Program = null;
pub var update_program: ?zgl.Program = null;
pub var uniforms: ?[]_shader.UniformName = null;

pub var init_delta_time: ?u32 = null;
pub var init_time: ?u32 = null;
pub var init_particle_count: ?u32 = null;

pub var update_delta_time: ?u32 = null;
pub var update_time: ?u32 = null;
pub var update_particle_count: ?u32 = null;

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

    setCount(count);

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

pub fn setCount(new_count: usize) void {
    zgl.Buffer.bind(init_buffer, .shader_storage_buffer);
    zgl.namedBufferUninitialized(init_buffer, Particle, new_count, .dynamic_draw);
    zgl.Buffer.bind(now_buffer, .shader_storage_buffer);
    zgl.namedBufferUninitialized(now_buffer, Particle, new_count, .dynamic_draw);
    zgl.Buffer.bind(velocity_buffer, .shader_storage_buffer);
    zgl.namedBufferUninitialized(velocity_buffer, Particle, new_count, .dynamic_draw);
    zgl.Buffer.bind(init_velocity_buffer, .shader_storage_buffer);
    zgl.namedBufferUninitialized(init_velocity_buffer, Particle, new_count, .dynamic_draw);
    count = new_count;
}

pub fn loadProgram(path: []const u8, use_same_values: bool) !void {
    const file = try std.fs.cwd().readFileAlloc(_alloc.allocator, path, 65536);
    defer _alloc.allocator.free(file);

    var success = false;

    const new_init_program = try _shader.loadComputeMultiSources(3, .{
        header_compute_source,
        file,
        init_compute_source,
    });
    defer if (!success) zgl.Program.delete(new_init_program);
    const new_update_program = try _shader.loadComputeMultiSources(3, .{
        header_compute_source,
        file,
        update_compute_source,
    });
    defer if (!success) zgl.Program.delete(new_update_program);
    const new_uniforms = try _shader.getUniformsFromSource(file);

    for (new_uniforms, 0..) |*uniform, idx| {
        const name = uniform.name;
        const name_s = try std.mem
            .concatWithSentinel(_alloc.allocator, u8, &.{name}, 0);
        defer _alloc.allocator.free(name_s);
        uniform.locations = try _alloc.allocator.alloc(?u32, 2);
        uniform.locations[0] = new_init_program.uniformLocation(name_s);
        uniform.locations[1] = new_update_program.uniformLocation(name_s);
        if (use_same_values) {
            if (uniforms) |u| {
                uniform.value = u[idx].value;
            }
        }
    }
    defer if (!success) _shader.UniformName.deleteAll(new_uniforms);
    const new_init_delta_time = new_init_program.uniformLocation("u_delta_time");
    const new_init_time = new_init_program.uniformLocation("u_time");
    const new_init_particle_count = new_init_program.uniformLocation("u_particle_count");
    const new_update_delta_time = new_update_program.uniformLocation("u_delta_time");
    const new_update_time = new_update_program.uniformLocation("u_time");
    const new_update_particle_count = new_update_program.uniformLocation("u_particle_count");

    unloadProgram();
    init_program = new_init_program;
    update_program = new_update_program;
    uniforms = new_uniforms;
    init_delta_time = new_init_delta_time;
    init_time = new_init_time;
    init_particle_count = new_init_particle_count;
    update_delta_time = new_update_delta_time;
    update_time = new_update_time;
    update_particle_count = new_update_particle_count;
    for (uniforms.?) |uniform| {
        setUniform(uniform);
    }
    success = true;
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

pub const Data = struct {
    delta_time: f32 = 0.0,
    time: f32 = 0.0,
};

pub fn runInit(data: Data) void {
    if (init_program == null) return;
    zgl.Program.use(init_program.?);
    if (init_delta_time) |unif|
        init_program.?.uniform1f(unif, data.delta_time);
    if (init_time) |unif|
        init_program.?.uniform1f(unif, data.time);
    if (init_particle_count) |unif|
        init_program.?.uniform1i(unif, @intCast(count));
    runProgram();
}
pub fn runUpdate(data: Data) void {
    if (update_program == null) return;
    zgl.Program.use(update_program.?);
    if (update_delta_time) |unif|
        update_program.?.uniform1f(unif, data.delta_time);
    if (update_time) |unif|
        update_program.?.uniform1f(unif, data.time);
    if (update_particle_count) |unif|
        update_program.?.uniform1i(unif, @intCast(count));
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
        .uint => {
            if (uniform.locations[0]) |location|
                init_program.?.uniform1ui(location, uniform.value.uint);
            if (uniform.locations[1]) |location|
                update_program.?.uniform1ui(location, uniform.value.uint);
        },
        .bool => {
            if (uniform.locations[0]) |location|
                init_program.?.uniform1i(location, if (uniform.value.bool) 1 else 0);
            if (uniform.locations[1]) |location|
                update_program.?.uniform1i(location, if (uniform.value.bool) 1 else 0);
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
        .ivec2 => {
            if (uniform.locations[0]) |location|
                init_program.?.uniform2i(location, uniform.value.ivec2[0], uniform.value.ivec2[1]);
            if (uniform.locations[1]) |location|
                update_program.?.uniform2i(location, uniform.value.ivec2[0], uniform.value.ivec2[1]);
        },
        .ivec3 => {
            if (uniform.locations[0]) |location|
                init_program.?.uniform3i(location, uniform.value.ivec3[0], uniform.value.ivec3[1], uniform.value.ivec3[2]);
            if (uniform.locations[1]) |location|
                update_program.?.uniform3i(location, uniform.value.ivec3[0], uniform.value.ivec3[1], uniform.value.ivec3[2]);
        },
        .ivec4 => {
            if (uniform.locations[0]) |location|
                zgl.binding.uniform4i(@intCast(location), uniform.value.ivec4[0], uniform.value.ivec4[1], uniform.value.ivec4[2], uniform.value.ivec4[3]);
            if (uniform.locations[1]) |location|
                zgl.binding.uniform4i(@intCast(location), uniform.value.ivec4[0], uniform.value.ivec4[1], uniform.value.ivec4[2], uniform.value.ivec4[3]);
        },
        .mat2 => {
            if (uniform.locations[0]) |location|
                zgl.binding.uniformMatrix2fv(@intCast(location), 1, 0, &uniform.value.mat2[0][0]);
            if (uniform.locations[1]) |location|
                zgl.binding.uniformMatrix2fv(@intCast(location), 1, 0, &uniform.value.mat2[0][0]);
        },
        .mat3 => {
            if (uniform.locations[0]) |location|
                zgl.binding.uniformMatrix3fv(@intCast(location), 1, 0, &uniform.value.mat3[0][0]);
            if (uniform.locations[1]) |location|
                zgl.binding.uniformMatrix3fv(@intCast(location), 1, 0, &uniform.value.mat3[0][0]);
        },
        .mat4 => {
            if (uniform.locations[0]) |location|
                zgl.binding.uniformMatrix4fv(@intCast(location), 1, 0, &uniform.value.mat4[0][0]);
            if (uniform.locations[1]) |location|
                zgl.binding.uniformMatrix4fv(@intCast(location), 1, 0, &uniform.value.mat4[0][0]);
        },
    }
}
