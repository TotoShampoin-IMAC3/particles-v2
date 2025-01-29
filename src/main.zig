const std = @import("std");
const glfw = @import("glfw");
const zgl = @import("zgl");
const zlm = @import("zlm");
const zimgui = @import("Zig-ImGui");

const alloc = @import("managers/allocator.zig");
const init = @import("init.zig");
const imgui = @import("imgui.zig");
const particle = @import("particle.zig");
const framebuffer = @import("managers/framebuffer.zig");

const Frame = framebuffer.Frame;

const INIT_WIDTH = 256;
const INIT_HEIGHT = 256;

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
        .createLookAt(zlm.Vec3.unitZ.scale(-5), zlm.Vec3.zero, zlm.Vec3.unitY);
    var perspective_zlm = zlm.Mat4
        .createPerspective(
        std.math.rad_per_deg * 45,
        @as(f32, @floatFromInt(frame.width)) / @as(f32, @floatFromInt(frame.height)),
        0.1,
        100.0,
    );

    view_matrix = view_matrix;
    perspective_zlm = perspective_zlm;

    zgl.enable(.depth_test);

    particle.runInit();

    // ===== EVENTS =====

    imgui.start(init.window);

    // ===== MAIN LOOP =====

    // const style = zimgui.GetStyle().?;

    var frame_size: [2]i32 = .{
        @intCast(frame.width),
        @intCast(frame.height),
    };
    var framerate: i32 = 30;
    var interval: f32 = 1.0 / 30.0;
    var vsync = true;
    glfw.swapInterval(@intFromBool(vsync));

    var particle_count = @as(i32, @intCast(particle.count));

    const start = glfw.getTime();
    var last = start;
    var last_frame = start;
    while (glfw.windowShouldClose(init.window) == false) {
        const now = glfw.getTime();
        // const elapsed = now - start;
        const delta = now - last;

        if (vsync) {
            particle.runUpdate(@floatCast(delta));
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

        if (zimgui.Begin("Info")) {
            zimgui.Text("%.3f ms/frame (%.1f FPS)", 1000.0 / delta, 1.0 / delta);
            zimgui.Text("now: %.3f s", now);
            zimgui.Text("last: %.3f s", last);
            zimgui.Text("last_frame: %.3f s", last_frame);
            zimgui.Text("delta: %.3f s", now - last);
            zimgui.Text("frame_delta: %.3f s", now - last_frame);
            zimgui.Text("interval: %.3f s", interval);

            zimgui.End();
        }

        if (zimgui.Begin("Particle System")) {
            if (zimgui.Checkbox("VSync", &vsync)) {
                glfw.swapInterval(@intFromBool(vsync));
                if (!vsync) {
                    interval = 1.0 / @as(f32, @floatFromInt(framerate));
                    last_frame = now;
                }
            }
            if (!vsync and zimgui.InputInt("Framerate", &framerate)) {
                if (framerate < 1) {
                    framerate = 1;
                }
                interval = 1.0 / @as(f32, @floatFromInt(framerate));
            }
            if (zimgui.InputInt2("Frame Size", &frame_size)) {
                try frame.resize(@intCast(frame_size[0]), @intCast(frame_size[1]));
                const ratio: f32 = cast(f32, frame_size[0]) / cast(f32, frame_size[1]);
                perspective_zlm = zlm.Mat4
                    .createPerspective(std.math.rad_per_deg * 45, ratio, 0.1, 100.0);
            }
            if (zimgui.InputInt("Particles count", &particle_count)) {
                particle.setCount(@intCast(particle_count));
                particle.runInit();
            }
            if (zimgui.Button("Reset particles")) {
                particle.runInit();
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

        zimgui.SetNextWindowSize(zimgui.Vec2.init(
            @floatFromInt(frame.width + 16),
            @floatFromInt(frame.height + 16 + 19),
        ));
        if (zimgui.BeginExt("Frame", null, .{
            .NoResize = true,
        })) {
            zimgui.Image(
                @enumFromInt(@intFromEnum(frame.texture)),
                zimgui.Vec2.init(
                    @floatFromInt(frame.width),
                    @floatFromInt(frame.height),
                ),
            );
            zimgui.End();
        }

        imgui.endDrawing();

        glfw.pollEvents();
        glfw.swapBuffers(init.window);

        last = now;
    }
}
