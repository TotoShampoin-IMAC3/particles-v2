const std = @import("std");
const glfw = @import("glfw");
const zgl = @import("zgl");
const helper = @import("helper.zig");

pub var allocator: std.mem.Allocator = undefined;

pub var mesh_program: zgl.Program = undefined;
pub var particle_program: zgl.Program = undefined;
pub var particle_compute: zgl.Program = undefined;

pub fn getProcAddressWrapper(
    comptime _: type,
    symbolName: [:0]const u8,
) ?*const anyopaque {
    return glfw.getProcAddress(symbolName);
}

pub fn loadGl() !void {
    try zgl.loadExtensions(void, getProcAddressWrapper);
}

pub fn initShaders() !void {
    mesh_program = try helper.loadShaders(
        @embedFile("shaders/mesh.vert"),
        @embedFile("shaders/mesh.frag"),
    );

    particle_program = try helper.loadShaders(
        @embedFile("shaders/particle.vert"),
        @embedFile("shaders/particle.frag"),
    );

    particle_compute = try helper.loadCompute(
        @embedFile("shaders/particle.comp"),
    );
}
pub fn deinitShaders() void {
    zgl.Program.delete(mesh_program);
    zgl.Program.delete(particle_program);
    zgl.Program.delete(particle_compute);
}
