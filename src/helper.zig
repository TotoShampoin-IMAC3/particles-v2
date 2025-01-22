const std = @import("std");
const zgl = @import("zgl");
const init = @import("init.zig");

pub const Vertex = struct {
    position: [3]f32,
    texcoord: [2]f32,
};
pub const Particle = struct {
    position: [3]f32,
};

pub const InstancedMesh = struct {
    vao: zgl.VertexArray,
    vbo: zgl.Buffer,
    ebo: zgl.Buffer,
    instance: zgl.Buffer,
    count: usize,
    instance_count: usize,

    pub fn create() InstancedMesh {
        var self: InstancedMesh = undefined;
        self.vao = zgl.VertexArray.create();
        self.vbo = zgl.Buffer.create();
        self.ebo = zgl.Buffer.create();
        self.instance = zgl.Buffer.create();
        self.count = 0;
        self.instance_count = 0;
        return self;
    }
    pub fn delete(self: *InstancedMesh) void {
        zgl.VertexArray.delete(self.vao);
        zgl.Buffer.delete(self.vbo);
        zgl.Buffer.delete(self.ebo);
        zgl.Buffer.delete(self.instance);
    }
};
pub fn setupAndFillParticle(
    mesh: *InstancedMesh,
    vertices: []const Vertex,
    indices: []const u32,
    particles: []const Particle,
) void {
    importMesh(mesh, vertices, indices);
    importParticles(mesh, particles);
    setupParticles(mesh);
}
pub fn setupParticles(mesh: *InstancedMesh) void {
    zgl.VertexArray.bind(mesh.vao);
    zgl.Buffer.bind(mesh.vbo, .array_buffer);
    zgl.enableVertexAttribArray(0);
    zgl.vertexAttribPointer(0, 3, .float, false, @sizeOf(Vertex), @offsetOf(Vertex, "position"));
    zgl.enableVertexAttribArray(1);
    zgl.vertexAttribPointer(1, 2, .float, false, @sizeOf(Vertex), @offsetOf(Vertex, "texcoord"));
    zgl.Buffer.bind(mesh.instance, .array_buffer);
    zgl.enableVertexAttribArray(2);
    zgl.vertexAttribPointer(2, 3, .float, false, @sizeOf(Particle), @offsetOf(Particle, "position"));
    zgl.vertexAttribDivisor(2, 1);
    zgl.Buffer.bind(.invalid, .array_buffer);
    zgl.Buffer.bind(mesh.ebo, .element_array_buffer);
}
pub fn importParticles(mesh: *InstancedMesh, data: []const Particle) void {
    mesh.instance_count = data.len;
    zgl.Buffer.bind(mesh.instance, .array_buffer);
    zgl.Buffer.data(mesh.instance, Particle, data[0..], .static_draw);
    zgl.Buffer.bind(.invalid, .array_buffer);
}
pub fn importMesh(mesh: *InstancedMesh, vertices: []const Vertex, indices: []const u32) void {
    mesh.count = indices.len;
    zgl.VertexArray.bind(mesh.vao);
    zgl.Buffer.bind(mesh.vbo, .array_buffer);
    zgl.Buffer.data(mesh.vbo, Vertex, vertices, .static_draw);
    zgl.Buffer.bind(.invalid, .array_buffer);
    zgl.Buffer.bind(mesh.ebo, .element_array_buffer);
    zgl.Buffer.data(mesh.ebo, u32, indices, .static_draw);
    zgl.Buffer.bind(.invalid, .element_array_buffer);
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
    {
        const vertex = try loadShader(.vertex, vertexSource);
        defer zgl.Shader.delete(vertex);
        const fragment = try loadShader(.fragment, fragmentSource);
        defer zgl.Shader.delete(fragment);

        zgl.Program.attach(program, vertex);
        zgl.Program.attach(program, fragment);
        zgl.Program.link(program);
    }
    if (zgl.Program.get(program, .link_status) == 0) {
        const log = try zgl.Program.getCompileLog(program, init.allocator);
        defer init.allocator.free(log);
        std.debug.print("Program linking failed: {s}\n", .{log});
        return error.ProgramLinkingFailed;
    }
    return program;
}
