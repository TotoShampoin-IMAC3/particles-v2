const std = @import("std");
const zgl = @import("zgl");

pub const Mesh = struct {
    vao: zgl.VertexArray,
    vbo: zgl.Buffer,
    ebo: zgl.Buffer,
    count: usize,

    pub fn create() Mesh {
        var self: Mesh = undefined;
        self.vao = zgl.VertexArray.create();
        self.vbo = zgl.Buffer.create();
        self.ebo = zgl.Buffer.create();
        self.count = 0;
        return self;
    }
    pub fn delete(self: *Mesh) void {
        zgl.VertexArray.delete(self.vao);
        zgl.Buffer.delete(self.vbo);
        zgl.Buffer.delete(self.ebo);
    }
    pub fn importMesh(
        mesh: *Mesh,
        Vertex: type,
        vertices: []const Vertex,
        indices: []const u32,
    ) void {
        zgl.VertexArray.bind(mesh.vao);
        zgl.Buffer.bind(mesh.vbo, .array_buffer);
        zgl.Buffer.data(mesh.vbo, Vertex, vertices, .static_draw);
        zgl.Buffer.bind(.invalid, .array_buffer);
        zgl.Buffer.bind(mesh.ebo, .element_array_buffer);
        zgl.Buffer.data(mesh.ebo, u32, indices, .static_draw);
        zgl.Buffer.bind(.invalid, .element_array_buffer);
        mesh.count = indices.len;
    }

    pub fn draw(self: Mesh) void {
        zgl.VertexArray.bind(self.vao);
        zgl.drawElements(.triangles, self.count, .unsigned_int, 0);
    }
    pub fn drawInstanced(self: Mesh, count: usize) void {
        zgl.VertexArray.bind(self.vao);
        zgl.drawElementsInstanced(.triangles, self.count, .unsigned_int, 0, count);
    }
};
