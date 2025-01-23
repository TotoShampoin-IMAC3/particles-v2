const std = @import("std");
const zgl = @import("zgl");

const init = @import("init.zig");
const helper = @import("helper.zig");

const cube_vertices = [_]helper.Vertex{
    .{ .position = .{ 1, 1, 1 }, .texcoord = .{ 0, 1 } },
    .{ .position = .{ 1, 1, -1 }, .texcoord = .{ 1, 1 } },
    .{ .position = .{ 1, -1, 1 }, .texcoord = .{ 0, 0 } },
    .{ .position = .{ 1, -1, -1 }, .texcoord = .{ 1, 0 } },
    .{ .position = .{ -1, 1, -1 }, .texcoord = .{ 0, 1 } },
    .{ .position = .{ -1, 1, 1 }, .texcoord = .{ 1, 1 } },
    .{ .position = .{ -1, -1, -1 }, .texcoord = .{ 0, 0 } },
    .{ .position = .{ -1, -1, 1 }, .texcoord = .{ 1, 0 } },
    .{ .position = .{ -1, 1, -1 }, .texcoord = .{ 0, 1 } },
    .{ .position = .{ 1, 1, -1 }, .texcoord = .{ 1, 1 } },
    .{ .position = .{ -1, 1, 1 }, .texcoord = .{ 0, 0 } },
    .{ .position = .{ 1, 1, 1 }, .texcoord = .{ 1, 0 } },
    .{ .position = .{ -1, -1, 1 }, .texcoord = .{ 0, 1 } },
    .{ .position = .{ 1, -1, 1 }, .texcoord = .{ 1, 1 } },
    .{ .position = .{ -1, -1, -1 }, .texcoord = .{ 0, 0 } },
    .{ .position = .{ 1, -1, -1 }, .texcoord = .{ 1, 0 } },
    .{ .position = .{ -1, 1, 1 }, .texcoord = .{ 0, 1 } },
    .{ .position = .{ 1, 1, 1 }, .texcoord = .{ 1, 1 } },
    .{ .position = .{ -1, -1, 1 }, .texcoord = .{ 0, 0 } },
    .{ .position = .{ 1, -1, 1 }, .texcoord = .{ 1, 0 } },
    .{ .position = .{ 1, 1, -1 }, .texcoord = .{ 0, 1 } },
    .{ .position = .{ -1, 1, -1 }, .texcoord = .{ 1, 1 } },
    .{ .position = .{ 1, -1, -1 }, .texcoord = .{ 0, 0 } },
    .{ .position = .{ -1, -1, -1 }, .texcoord = .{ 1, 0 } },
};
const indices = [36]u32{
    0,  2,  1,  2,  3,  1,
    4,  6,  5,  6,  7,  5,
    8,  10, 9,  10, 11, 9,
    12, 14, 13, 14, 15, 13,
    16, 18, 17, 18, 19, 17,
    20, 22, 21, 22, 23, 21,
};

pub fn setupAndFillCube(mesh: *helper.Mesh) void {
    mesh.importMesh(helper.Vertex, cube_vertices[0..], indices[0..]);
    helper.setupVertexMesh(mesh);
}
