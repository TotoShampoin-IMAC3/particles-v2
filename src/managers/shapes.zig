const std = @import("std");
const zgl = @import("zgl");

const mesh = @import("mesh.zig");
const alloc = @import("allocator.zig");
const vertex = @import("vertex.zig");

pub const cube_vertices = [_]vertex.Vertex{
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
pub const cube_indices = [36]u32{
    0,  2,  1,  2,  3,  1,
    4,  6,  5,  6,  7,  5,
    8,  10, 9,  10, 11, 9,
    12, 14, 13, 14, 15, 13,
    16, 18, 17, 18, 19, 17,
    20, 22, 21, 22, 23, 21,
};

pub const quad_vertices = [_]vertex.Vertex{
    .{ .position = .{ -0.5, 0.5, 0.0 }, .texcoord = .{ 0.0, 1.0 } },
    .{ .position = .{ 0.5, 0.5, 0.0 }, .texcoord = .{ 1.0, 1.0 } },
    .{ .position = .{ -0.5, -0.5, 0.0 }, .texcoord = .{ 0.0, 0.0 } },
    .{ .position = .{ 0.5, -0.5, 0.0 }, .texcoord = .{ 1.0, 0.0 } },
};
pub const quad_indices = [_]u32{ 0, 2, 1, 2, 3, 1 };
