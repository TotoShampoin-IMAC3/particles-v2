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
        mesh.count = indices.len;
        zgl.VertexArray.bind(mesh.vao);
        zgl.Buffer.bind(mesh.vbo, .array_buffer);
        zgl.Buffer.data(mesh.vbo, Vertex, vertices, .static_draw);
        zgl.Buffer.bind(.invalid, .array_buffer);
        zgl.Buffer.bind(mesh.ebo, .element_array_buffer);
        zgl.Buffer.data(mesh.ebo, u32, indices, .static_draw);
        zgl.Buffer.bind(.invalid, .element_array_buffer);
    }
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
    pub fn importMesh(
        mesh: *InstancedMesh,
        Vertex: type,
        vertices: []const Vertex,
        indices: []const u32,
    ) void {
        mesh.count = indices.len;
        zgl.VertexArray.bind(mesh.vao);
        zgl.Buffer.bind(mesh.vbo, .array_buffer);
        zgl.Buffer.data(mesh.vbo, Vertex, vertices, .static_draw);
        zgl.Buffer.bind(.invalid, .array_buffer);
        zgl.Buffer.bind(mesh.ebo, .element_array_buffer);
        zgl.Buffer.data(mesh.ebo, u32, indices, .static_draw);
        zgl.Buffer.bind(.invalid, .element_array_buffer);
    }
    pub fn importInstances(
        mesh: *InstancedMesh,
        Instance: type,
        instances: []const Instance,
    ) void {
        mesh.instance_count = instances.len;
        zgl.Buffer.bind(mesh.instance, .array_buffer);
        zgl.Buffer.data(mesh.instance, Instance, instances, .static_draw);
        zgl.Buffer.bind(.invalid, .array_buffer);
    }
};
