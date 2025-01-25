const zgl = @import("zgl");

const mesh = @import("mesh.zig");
const vertex = @import("vertex.zig");
const shapes = @import("shapes.zig");

const InstancedMesh = mesh.InstancedMesh;
const Vertex = vertex.Vertex;

pub const Particle = struct {
    position: [4]f32,
    color: [4]f32 = [_]f32{0.0} ** 4,
    size: f32 = 1.0,
    angle: f32 = 0.0,
    life: f32 = 1.0,
    _padding: [1]f32 = [_]f32{0.0} ** 1,
};

pub const initial_array = [_]Particle{
    .{ .position = .{ 0.0, 0.0, 0.0, 1.0 } },
    .{ .position = .{ 1.0, 1.0, 1.0, 1.0 } },
    .{ .position = .{ -1.0, -1.0, 2.0, 1.0 } },
    .{ .position = .{ -1.0, 1.0, 3.0, 1.0 } },
};

pub fn setupAndFill(
    _mesh: *InstancedMesh,
    particles: []const Particle,
) void {
    _mesh.importMesh(vertex.Vertex, shapes.quad_vertices[0..], shapes.quad_indices[0..]);
    _mesh.importInstances(Particle, particles);
    setupMesh(_mesh);
}

pub fn setupMesh(_mesh: *InstancedMesh) void {
    zgl.VertexArray.bind(_mesh.vao);

    zgl.Buffer.bind(_mesh.vbo, .array_buffer);
    zgl.enableVertexAttribArray(0);
    zgl.vertexAttribPointer(0, 3, .float, false, @sizeOf(Vertex), @offsetOf(Vertex, "position"));
    zgl.enableVertexAttribArray(1);
    zgl.vertexAttribPointer(1, 2, .float, false, @sizeOf(Vertex), @offsetOf(Vertex, "texcoord"));

    zgl.Buffer.bind(_mesh.instance, .array_buffer);
    zgl.enableVertexAttribArray(2);
    zgl.vertexAttribPointer(2, 4, .float, false, @sizeOf(Particle), @offsetOf(Particle, "position"));
    zgl.enableVertexAttribArray(3);
    zgl.vertexAttribPointer(3, 4, .float, false, @sizeOf(Particle), @offsetOf(Particle, "color"));
    zgl.enableVertexAttribArray(4);
    zgl.vertexAttribPointer(4, 1, .float, false, @sizeOf(Particle), @offsetOf(Particle, "size"));
    zgl.enableVertexAttribArray(5);
    zgl.vertexAttribPointer(5, 1, .float, false, @sizeOf(Particle), @offsetOf(Particle, "angle"));
    zgl.enableVertexAttribArray(6);
    zgl.vertexAttribPointer(6, 1, .float, false, @sizeOf(Particle), @offsetOf(Particle, "life"));

    zgl.vertexAttribDivisor(2, 1);
    zgl.Buffer.bind(.invalid, .array_buffer);
    zgl.Buffer.bind(_mesh.ebo, .element_array_buffer);
}
