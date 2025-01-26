const std = @import("std");
const glfw = @import("glfw");
const zgl = @import("zgl");
const zlm = @import("zlm");
const zimgui = @import("Zig-ImGui");

const init = @import("init.zig");
const imgui = @import("imgui.zig");
const alloc = @import("managers/allocator.zig");
const shader = @import("managers/shader.zig");
const shapes = @import("managers/shapes.zig");
const _particle = @import("managers/particle.zig");

const particle = @import("particle.zig");

pub fn main() !void {
    try init.init();
    defer init.deinit();

    try particle.loadProgram("res/test.glsl");
    defer particle.unloadProgram();

    var vsync = true;

    glfw.swapInterval(@intFromBool(vsync));

    const particle_program = particle.render_program;

    const particle_view = particle_program.uniformLocation("u_view");
    const particle_projection = particle_program.uniformLocation("u_projection");

    // ===== CAMERA =====

    var view_matrix = zlm.Mat4
        .createLookAt(zlm.Vec3.unitZ.scale(-5), zlm.Vec3.zero, zlm.Vec3.unitY);
    var perspective_zlm = zlm.Mat4
        .createPerspective(std.math.rad_per_deg * 45, 800.0 / 600.0, 0.1, 100.0);

    view_matrix = view_matrix;
    perspective_zlm = perspective_zlm;

    zgl.enable(.depth_test);

    particle.runProgram(particle.init_program.?);

    // ===== EVENTS =====

    // const Events = struct {
    //     perspective_zlm: *zlm.Mat4,
    //     pub fn windowSize(window: *glfw.Window, width: c_int, height: c_int) callconv(.C) void {
    //         const data: *@This() = @alignCast(@ptrCast(glfw.getWindowUserPointer(window)));
    //         const f_width: f32 = @floatFromInt(width);
    //         const f_height: f32 = @floatFromInt(height);
    //         data.perspective_zlm.* = zlm.Mat4
    //             .createPerspective(std.math.rad_per_deg * 45, f_width / f_height, 0.1, 100.0);
    //         zgl.viewport(0, 0, @intCast(width), @intCast(height));
    //     }
    // };
    // var events = Events{ .perspective_zlm = &perspective_zlm };
    // glfw.setWindowUserPointer(init.window, &events);
    // _ = glfw.setWindowSizeCallback(init.window, Events.windowSize);

    imgui.start(init.window);

    // ===== MAIN LOOP =====

    const start = glfw.getTime();
    var last = start;
    while (glfw.windowShouldClose(init.window) == false) {
        const now = glfw.getTime();
        // const elapsed = now - start;
        const delta = now - last;

        zgl.Program.use(particle.update_program.?);
        particle.update_program.?.uniform1f(particle.uniform_delta_time.?, @floatCast(delta));

        zgl.Program.use(particle_program);
        particle_program.uniformMatrix4(particle_view, false, &.{view_matrix.fields});
        particle_program.uniformMatrix4(particle_projection, false, &.{perspective_zlm.fields});

        particle.runProgram(particle.update_program.?);

        zgl.clear(.{ .color = true, .depth = true });

        particle.drawParticles();

        imgui.beginDrawing();

        zimgui.SetNextWindowPosExt(zimgui.Vec2.init(0, 0), .{}, zimgui.Vec2.init(0, 0));
        if (zimgui.BeginExt("Particle System", null, .{ .NoResize = true })) {
            zimgui.Text("%.3f ms/frame (%.1f FPS)", 1000.0 / delta, 1.0 / delta);
            if (zimgui.Checkbox("VSync", &vsync)) {
                glfw.swapInterval(@intFromBool(vsync));
            }
            if (zimgui.Button("Reset particles")) {
                particle.runProgram(particle.init_program.?);
            }
            if (particle.uniforms) |uniforms|
                for (uniforms) |*uniform| {
                    const name = uniform.name;
                    const name_s = try std.mem
                        .concatWithSentinel(alloc.allocator, u8, &.{name}, 0);
                    defer alloc.allocator.free(name_s);
                    const edit = switch (uniform.type) {
                        .int => zimgui.InputInt(name_s, &uniform.value.int),
                        .float => zimgui.InputFloat(name_s, &uniform.value.float),
                        .vec2 => zimgui.InputFloat2(name_s, &uniform.value.vec2),
                        .vec3 => zimgui.InputFloat3(name_s, &uniform.value.vec3),
                        .vec4 => zimgui.InputFloat4(name_s, &uniform.value.vec4),
                    };
                    if (edit) {
                        particle.setUniform(uniform.*);
                    }
                };
            zimgui.End();
        }

        imgui.endDrawing();

        glfw.pollEvents();
        glfw.swapBuffers(init.window);

        last = now;
    }
}
