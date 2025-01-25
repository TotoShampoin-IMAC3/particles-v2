const zgl = @import("zgl");
const mesh = @import("mesh.zig");

pub const Vertex = struct {
    position: [3]f32,
    texcoord: [2]f32,
};
pub fn setupVertexMesh(_mesh: *mesh.Mesh) void {
    zgl.VertexArray.bind(_mesh.vao);
    zgl.Buffer.bind(_mesh.vbo, .array_buffer);
    zgl.enableVertexAttribArray(0);
    zgl.vertexAttribPointer(0, 3, .float, false, @sizeOf(Vertex), @offsetOf(Vertex, "position"));
    zgl.enableVertexAttribArray(1);
    zgl.vertexAttribPointer(1, 2, .float, false, @sizeOf(Vertex), @offsetOf(Vertex, "texcoord"));
    zgl.Buffer.bind(.invalid, .array_buffer);
    zgl.Buffer.bind(_mesh.ebo, .element_array_buffer);
}
