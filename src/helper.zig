const std = @import("std");
const zgl = @import("zgl");
const init = @import("init.zig");

pub const Mesh = @import("mesh.zig").Mesh;
pub const InstancedMesh = @import("mesh.zig").InstancedMesh;

pub const Vertex = struct {
    position: [3]f32,
    texcoord: [2]f32,
};
pub const Particle = struct {
    position: [4]f32,
    speed: [4]f32 = [_]f32{0.0} ** 4.0,
};
pub fn setupAndFillParticle(
    mesh: *InstancedMesh,
    vertices: []const Vertex,
    indices: []const u32,
    particles: []const Particle,
) void {
    mesh.importMesh(Vertex, vertices, indices);
    mesh.importInstances(Particle, particles);
    setupParticleMesh(mesh);
}
pub fn setupVertexMesh(mesh: *Mesh) void {
    zgl.VertexArray.bind(mesh.vao);
    zgl.Buffer.bind(mesh.vbo, .array_buffer);
    zgl.enableVertexAttribArray(0);
    zgl.vertexAttribPointer(0, 3, .float, false, @sizeOf(Vertex), @offsetOf(Vertex, "position"));
    zgl.enableVertexAttribArray(1);
    zgl.vertexAttribPointer(1, 2, .float, false, @sizeOf(Vertex), @offsetOf(Vertex, "texcoord"));
    zgl.Buffer.bind(.invalid, .array_buffer);
    zgl.Buffer.bind(mesh.ebo, .element_array_buffer);
}
pub fn setupParticleMesh(mesh: *InstancedMesh) void {
    zgl.VertexArray.bind(mesh.vao);
    zgl.Buffer.bind(mesh.vbo, .array_buffer);
    zgl.enableVertexAttribArray(0);
    zgl.vertexAttribPointer(0, 3, .float, false, @sizeOf(Vertex), @offsetOf(Vertex, "position"));
    zgl.enableVertexAttribArray(1);
    zgl.vertexAttribPointer(1, 2, .float, false, @sizeOf(Vertex), @offsetOf(Vertex, "texcoord"));
    zgl.Buffer.bind(mesh.instance, .array_buffer);
    zgl.enableVertexAttribArray(2);
    zgl.vertexAttribPointer(2, 4, .float, false, @sizeOf(Particle), @offsetOf(Particle, "position"));
    zgl.enableVertexAttribArray(3);
    zgl.vertexAttribPointer(3, 4, .float, false, @sizeOf(Particle), @offsetOf(Particle, "speed"));
    zgl.vertexAttribDivisor(2, 1);
    zgl.Buffer.bind(.invalid, .array_buffer);
    zgl.Buffer.bind(mesh.ebo, .element_array_buffer);
}

pub fn loadShader(shaderType: zgl.ShaderType, source: []const u8) !zgl.Shader {
    const shader = zgl.Shader.create(shaderType);
    zgl.Shader.source(shader, 1, &.{source});
    zgl.Shader.compile(shader);
    if (zgl.Shader.get(shader, .compile_status) == 0) {
        const log = try zgl.Shader.getCompileLog(shader, init.allocator);
        defer init.allocator.free(log);
        std.debug.print("Shader compilation failed: {s}\n", .{log});
        return error.ShaderCompilationFailed;
    }
    return shader;
}
pub fn loadShaders(
    vertexSource: []const u8,
    fragmentSource: []const u8,
) !zgl.Program {
    const program = zgl.Program.create();
    const vertex = try loadShader(.vertex, vertexSource);
    defer zgl.Shader.delete(vertex);
    const fragment = try loadShader(.fragment, fragmentSource);
    defer zgl.Shader.delete(fragment);
    zgl.Program.attach(program, vertex);
    zgl.Program.attach(program, fragment);
    zgl.Program.link(program);
    if (zgl.Program.get(program, .link_status) == 0) {
        const log = try zgl.Program.getCompileLog(program, init.allocator);
        defer init.allocator.free(log);
        std.debug.print("Program linking failed: {s}\n", .{log});
        return error.ProgramLinkingFailed;
    }
    return program;
}
pub fn loadCompute(computeSource: []const u8) !zgl.Program {
    const program = zgl.Program.create();
    const compute = try loadShader(.compute, computeSource);
    defer zgl.Shader.delete(compute);
    zgl.Program.attach(program, compute);
    zgl.Program.link(program);
    if (zgl.Program.get(program, .link_status) == 0) {
        const log = try zgl.Program.getCompileLog(program, init.allocator);
        defer init.allocator.free(log);
        std.debug.print("Program linking failed: {s}\n", .{log});
        return error.ProgramLinkingFailed;
    }
    return program;
}
