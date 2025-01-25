const std = @import("std");
const glfw = @import("glfw");
const zgl = @import("zgl");

const shader = @import("shader.zig");
const mesh = @import("mesh.zig");
const vertex = @import("vertex.zig");
const particle = @import("particle.zig");

pub var gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;
pub var allocator: std.mem.Allocator = undefined;
pub var window: *glfw.Window = undefined;

pub var mesh_program: zgl.Program = undefined;
pub var particle_program: zgl.Program = undefined;

// pub var init_compute: zgl.Program = undefined;
// pub var update_compute: zgl.Program = undefined;

pub var particle_mesh: mesh.InstancedMesh = undefined;

pub var particles_init_array: zgl.Buffer = undefined;
pub var particles_velocity_array: zgl.Buffer = undefined;

pub fn init() !void {
    gpa = std.heap.GeneralPurposeAllocator(.{}){};
    allocator = gpa.allocator();

    try glfw.init();

    window = try glfw.createWindow(800, 600, "Hello, World!", null, null);
    glfw.makeContextCurrent(window);
    try loadGl();
    try initShaders();
    try initMesh();
}
pub fn deinit() void {
    deinitMesh();
    deinitShaders();
    glfw.destroyWindow(window);
    glfw.terminate();
    if (gpa.deinit() == .leak)
        std.debug.print("Memory leak detected!\n", .{});
}

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
    mesh_program = try shader.loadShaders(
        @embedFile("shaders/mesh.vert"),
        @embedFile("shaders/mesh.frag"),
    );

    particle_program = try shader.loadShaders(
        @embedFile("shaders/particle.vert"),
        @embedFile("shaders/particle.frag"),
    );

    // init_compute = try shader.loadCompute(
    //     @embedFile("shaders/init.comp"),
    // );

    // update_compute = try shader.loadCompute(
    //     @embedFile("shaders/update.comp"),
    // );
}
pub fn deinitShaders() void {
    zgl.Program.delete(mesh_program);
    zgl.Program.delete(particle_program);
    // zgl.Program.delete(init_compute);
    // zgl.Program.delete(update_compute);
}

pub fn initMesh() !void {
    particle_mesh = mesh.InstancedMesh.create();
    particle.setupAndFill(&particle_mesh, particle.initial_array[0..]);
    particles_init_array = zgl.Buffer.create();
    particles_velocity_array = zgl.Buffer.create();
    zgl.Buffer.bind(particles_init_array, .shader_storage_buffer);
    zgl.Buffer.data(particles_init_array, particle.Particle, particle.initial_array[0..], .dynamic_draw);
    zgl.Buffer.bind(particles_velocity_array, .shader_storage_buffer);
    zgl.namedBufferUninitialized(particles_velocity_array, particle.Particle, particle.initial_array.len, .dynamic_draw);
}
pub fn deinitMesh() void {
    particle_mesh.delete();
}
