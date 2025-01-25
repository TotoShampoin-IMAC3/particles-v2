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

const init_compute_source = @embedFile("shaders/init.comp");
const update_compute_source = @embedFile("shaders/update.comp");

pub var render_program: zgl.Program = undefined;

pub var init_program: ?zgl.Program = null;
pub var update_program: ?zgl.Program = null;
pub var uniforms: ?[]_shader.Uniform = null;

pub var uniform_delta_time: ?u32 = null;

pub var mesh: _mesh.Mesh = undefined;

pub var count: usize = 2;
pub var init_buffer: zgl.Buffer = undefined;
pub var now_buffer: zgl.Buffer = undefined;
pub var velocity_buffer: zgl.Buffer = undefined;

pub fn init() !void {
    render_program = try _shader.loadShaders(
        @embedFile("shaders/particle.vert"),
        @embedFile("shaders/particle.frag"),
    );

    mesh = _mesh.Mesh.create();
    init_buffer = zgl.Buffer.create();
    now_buffer = zgl.Buffer.create();
    velocity_buffer = zgl.Buffer.create();

    zgl.Buffer.bind(init_buffer, .shader_storage_buffer);
    zgl.namedBufferUninitialized(init_buffer, Particle, count, .dynamic_draw);
    zgl.Buffer.bind(now_buffer, .shader_storage_buffer);
    zgl.namedBufferUninitialized(now_buffer, Particle, count, .dynamic_draw);
    zgl.Buffer.bind(velocity_buffer, .shader_storage_buffer);
    zgl.namedBufferUninitialized(velocity_buffer, Particle, count, .dynamic_draw);

    mesh.importMesh(_vertex.Vertex, _shapes.quad_vertices[0..], _shapes.quad_indices[0..]);

    _particle.setupMesh(&mesh, now_buffer);
}
pub fn deinit() void {
    zgl.Program.delete(render_program);
    _mesh.Mesh.delete(&mesh);
    zgl.Buffer.delete(init_buffer);
    zgl.Buffer.delete(velocity_buffer);
}

pub fn loadProgram(path: []const u8) !void {
    const file = try std.fs.cwd().readFileAlloc(_alloc.allocator, path, 65536);
    defer _alloc.allocator.free(file);

    unloadProgram();
    init_program = try _shader.loadComputeMultiSources(2, .{ init_compute_source, file });
    update_program = try _shader.loadComputeMultiSources(2, .{ update_compute_source, file });
    uniforms = try _shader.getUniformsFromSource(file);
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
        _shader.Uniform.deleteAll(uniforms.?);
        uniforms = null;
    }
}

pub fn runProgram(program: zgl.Program) void {
    zgl.Program.use(program);

    zgl.bindBufferBase(.shader_storage_buffer, 0, now_buffer);
    zgl.bindBufferBase(.shader_storage_buffer, 1, init_buffer);
    zgl.bindBufferBase(.shader_storage_buffer, 2, velocity_buffer);
    zgl.binding.dispatchCompute(@intCast(count), 1, 1);
    zgl.binding.memoryBarrier(zgl.binding.SHADER_STORAGE_BARRIER_BIT);
}

pub fn drawParticles() void {
    zgl.Program.use(render_program);
    mesh.drawInstanced(count);
}
