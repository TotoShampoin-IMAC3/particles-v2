const std = @import("std");
const glfw = @import("glfw");
const zgl = @import("zgl");
const zlm = @import("zlm");
const zimgui = @import("Zig-ImGui");

const alloc = @import("managers/allocator.zig");
const shader = @import("managers/shader.zig");
const init = @import("init.zig");
const imgui = @import("imgui.zig");
const particle = @import("particle.zig");
const framebuffer = @import("managers/framebuffer.zig");

const Frame = framebuffer.Frame;

const INIT_WIDTH = 256;
const INIT_HEIGHT = 256;
const FOV = 90.0;
const NEAR = 0.01;
const FAR = 100.0;
const POV = 2.0;

fn cast(t: type, value: anytype) t {
    return switch (@typeInfo(t)) {
        .Bool => switch (@typeInfo(@TypeOf(value))) {
            .Bool => value,
            .Int => value != 0,
            .Float => value != 0,
            else => @compileError("Unsupported"),
        },
        .Int => switch (@typeInfo(@TypeOf(value))) {
            .Bool => @as(t, @intFromBool(value)),
            .Int => @as(t, @intCast(value)),
            .Float => @as(t, @intFromFloat(value)),
            else => @compileError("Unsupported"),
        },
        .Float => switch (@typeInfo(@TypeOf(value))) {
            .Bool => if (value) 1.0 else 0.0,
            .Int => @as(t, @floatFromInt(value)),
            .Float => @as(t, @floatCast(value)),
            else => @compileError("Unsupported"),
        },
        else => @compileError("Unsupported"),
    };
}
fn enumCast(t: type, value: anytype) t {
    return @enumFromInt(@intFromEnum(value));
}

pub fn main() !void {
    try init.init();
    defer init.deinit();

    try particle.loadProgram("res/test.glsl");
    defer particle.unloadProgram();

    const particle_program = particle.render_program;

    const particle_view = particle_program.uniformLocation("u_view");
    const particle_projection = particle_program.uniformLocation("u_projection");

    var frame = try Frame.create(INIT_WIDTH, INIT_HEIGHT);
    defer frame.delete();

    // ===== CAMERA =====

    var view_matrix = zlm.Mat4
        .createLookAt(zlm.Vec3.unitZ.scale(-POV), zlm.Vec3.zero, zlm.Vec3.unitY);
    var perspective_zlm = zlm.Mat4
        .createPerspective(
        std.math.rad_per_deg * FOV,
        cast(f32, frame.width) / cast(f32, frame.height),
        NEAR,
        FAR,
    );

    view_matrix = view_matrix;
    perspective_zlm = perspective_zlm;

    zgl.enable(.depth_test);

    particle.runInit();

    // ===== EVENTS =====

    imgui.start(init.window);

    zimgui.GetIO().ConfigFlags.DockingEnable = true;

    // ===== MAIN LOOP =====

    var frame_size: [2]i32 = .{
        cast(i32, frame.width),
        cast(i32, frame.height),
    };
    var framerate: i32 = 30;
    var interval: f32 = 1.0 / 30.0;
    var vsync = true;
    glfw.swapInterval(cast(c_int, vsync));

    var particle_count = cast(i32, particle.count);

    var first = true;

    const start = glfw.getTime();
    var last = start;
    var last_frame = start;
    while (glfw.windowShouldClose(init.window) == false) {
        const now = glfw.getTime();
        // const elapsed = now - start;
        const delta = now - last;

        if (vsync) {
            particle.runUpdate(cast(f32, delta));
        } else {
            if (now - last_frame > interval) {
                particle.runUpdate(interval);
                last_frame = now;
            }
        }

        zgl.Program.use(particle_program);
        particle_program.uniformMatrix4(particle_view, false, &.{view_matrix.fields});
        particle_program.uniformMatrix4(particle_projection, false, &.{perspective_zlm.fields});

        Frame.bind(frame);
        Frame.setViewport(frame);
        zgl.enable(.depth_test);
        zgl.clearColor(0.0, 0.0, 0.0, 1.0);
        zgl.clear(.{ .color = true, .depth = true });
        particle.drawParticles();

        Frame.bind(null);

        zgl.clear(.{ .color = true });

        imgui.beginDrawing();

        var width: i32 = 0;
        var height: i32 = 0;
        glfw.getWindowSize(init.window, &width, &height);

        {
            _ = zimgui.DockSpaceOverViewport();
            if (first) {}

            if (zimgui.Begin("Info")) {
                zimgui.Text("%.3f ms/frame (%.1f FPS)", 1000.0 / delta, 1.0 / delta);
                zimgui.Text("now: %.3f s", now);
                zimgui.Text("last: %.3f s", last);
                zimgui.Text("last_frame: %.3f s", last_frame);
                zimgui.Text("delta: %.3f s", now - last);
                zimgui.Text("frame_delta: %.3f s", now - last_frame);
                zimgui.Text("interval: %.3f s", interval);
            }
            zimgui.End();

            if (zimgui.Begin("Parameters")) {
                zimgui.SeparatorText("Frame");
                if (zimgui.InputInt2("Frame Size", &frame_size)) {
                    try frame.resize(cast(usize, frame_size[0]), cast(usize, frame_size[1]));
                    const ratio: f32 = cast(f32, frame_size[0]) / cast(f32, frame_size[1]);
                    perspective_zlm = zlm.Mat4
                        .createPerspective(std.math.rad_per_deg * FOV, ratio, NEAR, FAR);
                }
                if (zimgui.InputInt("Framerate", &framerate)) {
                    if (framerate < 1) {
                        framerate = 1;
                    }
                    interval = 1.0 / cast(f32, framerate);
                }
                if (zimgui.Checkbox("VSync", &vsync)) {
                    glfw.swapInterval(cast(c_int, vsync));
                    if (!vsync) {
                        interval = 1.0 / cast(f32, framerate);
                        last_frame = now;
                    }
                }
                zimgui.SeparatorText("Particles");
                if (zimgui.Button("Reset particles")) {
                    particle.runInit();
                }
                if (zimgui.InputInt("Particles count", &particle_count)) {
                    particle.setCount(cast(usize, particle_count));
                    particle.runInit();
                }
                if (particle.uniforms) |uniforms| {
                    zimgui.SeparatorText("Uniforms");
                    for (uniforms) |*uniform| {
                        try handleUniformWithImgui(uniform);
                    }
                }
            }
            zimgui.End();

            if (zimgui.Begin("Preview")) {
                const size = zimgui.GetWindowSize();
                zimgui.SetCursorPos(.{
                    .x = (size.x - cast(f32, frame.width)) / 2.0,
                    .y = (size.y - cast(f32, frame.height)) / 2.0,
                });
                zimgui.Image(
                    enumCast(zimgui.TextureID, frame.texture),
                    zimgui.Vec2.init(
                        cast(f32, frame.width),
                        cast(f32, frame.height),
                    ),
                );
            }
            zimgui.End();
        }

        imgui.endDrawing();

        glfw.pollEvents();
        glfw.swapBuffers(init.window);

        last = now;
        if (first) first = false;
    }
}

pub fn handleUniformWithImgui(uniform: *shader.UniformName) !void {
    const name = uniform.name;
    const name_s = try std.mem
        .concatWithSentinel(alloc.allocator, u8, &.{name}, 0);
    defer alloc.allocator.free(name_s);
    const edit = switch (uniform.type) {
        .int => zimgui.InputInt(name_s, &uniform.value.int),
        .uint => zimgui.InputInt(name_s, @ptrCast(&uniform.value.uint)),
        .float => zimgui.InputFloat(name_s, &uniform.value.float),
        .vec2 => zimgui.InputFloat2(name_s, &uniform.value.vec2),
        .vec3 => zimgui.InputFloat3(name_s, &uniform.value.vec3),
        .vec4 => zimgui.InputFloat4(name_s, &uniform.value.vec4),
        .ivec2 => zimgui.InputInt2(name_s, &uniform.value.ivec2),
        .ivec3 => zimgui.InputInt3(name_s, &uniform.value.ivec3),
        .ivec4 => zimgui.InputInt4(name_s, &uniform.value.ivec4),
        .mat2 => bl: {
            const name_0 = std.mem
                .concatWithSentinel(alloc.allocator, u8, &.{ name, "0" }, 0) catch break :bl false;
            defer alloc.allocator.free(name_0);
            const name_1 = std.mem
                .concatWithSentinel(alloc.allocator, u8, &.{ name, "1" }, 0) catch break :bl false;
            defer alloc.allocator.free(name_1);
            var ret = false;
            ret = zimgui.InputFloat2(name_0, &uniform.value.mat2[0]) or ret;
            ret = zimgui.InputFloat2(name_1, &uniform.value.mat2[1]) or ret;
            break :bl ret;
        },
        .mat3 => bl: {
            const name_0 = std.mem
                .concatWithSentinel(alloc.allocator, u8, &.{ name, "0" }, 0) catch break :bl false;
            defer alloc.allocator.free(name_0);
            const name_1 = std.mem
                .concatWithSentinel(alloc.allocator, u8, &.{ name, "1" }, 0) catch break :bl false;
            defer alloc.allocator.free(name_1);
            const name_2 = std.mem
                .concatWithSentinel(alloc.allocator, u8, &.{ name, "2" }, 0) catch break :bl false;
            defer alloc.allocator.free(name_2);
            var ret = false;
            ret = zimgui.InputFloat3(name_0, &uniform.value.mat3[0]) or ret;
            ret = zimgui.InputFloat3(name_1, &uniform.value.mat3[1]) or ret;
            ret = zimgui.InputFloat3(name_2, &uniform.value.mat3[2]) or ret;
            break :bl ret;
        },
        .mat4 => bl: {
            const name_0 = std.mem
                .concatWithSentinel(alloc.allocator, u8, &.{ name, "0" }, 0) catch break :bl false;
            defer alloc.allocator.free(name_0);
            const name_1 = std.mem
                .concatWithSentinel(alloc.allocator, u8, &.{ name, "1" }, 0) catch break :bl false;
            defer alloc.allocator.free(name_1);
            const name_2 = std.mem
                .concatWithSentinel(alloc.allocator, u8, &.{ name, "2" }, 0) catch break :bl false;
            defer alloc.allocator.free(name_2);
            const name_3 = std.mem
                .concatWithSentinel(alloc.allocator, u8, &.{ name, "3" }, 0) catch break :bl false;
            defer alloc.allocator.free(name_3);
            var ret = false;
            ret = zimgui.InputFloat4(name_0, &uniform.value.mat4[0]) or ret;
            ret = zimgui.InputFloat4(name_1, &uniform.value.mat4[1]) or ret;
            ret = zimgui.InputFloat4(name_2, &uniform.value.mat4[2]) or ret;
            ret = zimgui.InputFloat4(name_3, &uniform.value.mat4[3]) or ret;
            break :bl ret;
        },
        else => unreachable,
    };
    if (edit) {
        particle.setUniform(uniform.*);
    }
}
