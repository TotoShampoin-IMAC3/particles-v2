const std = @import("std");
const glfw = @import("glfw");
const zgl = @import("zgl");
const zlm = @import("zlm");
const zimgui = @import("Zig-ImGui");
const nfd = @import("nfd");

const alloc = @import("managers/allocator.zig");
const shader = @import("managers/shader.zig");
const init = @import("init.zig");
const imgui = @import("imgui.zig");
const particle = @import("particle.zig");
const file_states = @import("file_states.zig");
const framebuffer = @import("managers/framebuffer.zig");
const cast = @import("utils/cast.zig");
const image = @import("utils/image.zig");

const Frame = framebuffer.Frame;

const INIT_WIDTH = 512;
const INIT_HEIGHT = 512;
const FOV = 90.0;
const NEAR = 0.01;
const FAR = 100.0;
const POV = 2.0;

pub fn main() !void {
    // ===== INITIALIZATION =====

    try init.init();
    defer init.deinit();

    try particle.loadProgram("res/test.glsl", false);
    defer particle.unloadProgram();

    try file_states.init();
    defer file_states.deinit();

    image.init();
    defer image.deinit();

    file_states.on_new_shader_loaded = changeShader;

    const particle_program = particle.render_program;

    var frame = try Frame.create(INIT_WIDTH, INIT_HEIGHT);
    defer frame.delete();

    var frame_size: [2]i32 = .{
        cast.cast(i32, frame.width),
        cast.cast(i32, frame.height),
    };
    var framerate: i32 = 30;
    var interval: f32 = 1.0 / 30.0;
    var vsync = false;
    glfw.swapInterval(cast.cast(c_int, vsync));

    var export_frame_count: i32 = 1;
    var export_time_start: f32 = 0.0;

    var particle_count = cast.cast(i32, particle.count);
    var particle_appearance = particle.ParticleAppearance.square;
    var particle_texture = try image.loadTexture("res/particle.png");
    var particle_transparency_threshold: f32 = 0.5;

    particle_texture = particle_texture;

    // ===== CAMERA =====

    const u_view = particle_program.uniformLocation("u_view");
    const u_projection = particle_program.uniformLocation("u_projection");
    const u_appearance = particle_program.uniformLocation("u_appearance");
    const u_texture = particle_program.uniformLocation("u_texture");
    const u_threshold = particle_program.uniformLocation("u_threshold");

    var camera_position = zlm.Vec3.unitZ.scale(-POV);
    var camera_target = zlm.Vec3.zero;
    const camera_up = zlm.Vec3.unitY;

    var view_matrix = zlm.Mat4
        .createLookAt(camera_position, camera_target, camera_up);
    var projection_params = ProjectionParameters{
        .perspective_fov = FOV,
        .orthographic_size = POV,
        .frame_aspect = cast.cast(f32, frame.width) / cast.cast(f32, frame.height),
        .user_aspect = 1.0,
        .near = NEAR,
        .far = FAR,
    };
    var perspective_zlm = generateProjection(projection_params);

    zgl.enable(.depth_test);
    zgl.enable(.blend);
    zgl.blendFunc(.src_alpha, .one_minus_src_alpha);

    particle.runInit(.{
        .delta_time = interval,
        .time = 0.0,
    });

    // ===== EVENTS =====

    imgui.start(init.window);
    defer imgui.stop();

    zimgui.GetIO().ConfigFlags.DockingEnable = true;

    // ===== MAIN LOOP =====

    var start = glfw.getTime();
    var last = start;
    var last_frame = start;
    while (glfw.windowShouldClose(init.window) == false) {
        const now = glfw.getTime();
        const elapsed = now - start;
        const delta = now - last;
        const f64_framerate = cast.cast(f64, framerate);
        const frame_time = @floor((now - start) * f64_framerate) / f64_framerate;

        if (vsync) {
            particle.runUpdate(.{
                .delta_time = cast.cast(f32, delta),
                .time = cast.cast(f32, elapsed),
            });
        } else {
            if (now - last_frame > interval) {
                particle.runUpdate(.{
                    .delta_time = interval,
                    .time = cast.cast(f32, frame_time),
                });
                last_frame = now;
            }
        }

        zgl.Program.use(particle_program);
        particle_program.uniformMatrix4(u_view, false, &.{view_matrix.fields});
        particle_program.uniformMatrix4(u_projection, false, &.{perspective_zlm.fields});
        particle_program.uniform1i(u_appearance, cast.cast(i32, particle_appearance));
        particle_program.uniform1i(u_texture, 0);
        zgl.activeTexture(.texture_0);
        zgl.bindTexture(particle_texture, .@"2d");
        particle_program.uniform1f(u_threshold, particle_transparency_threshold);

        Frame.bind(frame);
        Frame.setViewport(frame);
        zgl.enable(.depth_test);
        zgl.clearColor(0.0, 0.0, 0.0, 0.0);
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

            if (zimgui.Begin("Info")) {
                zimgui.Text("%.3f ms/frame (%.1f FPS)", 1000.0 / delta, 1.0 / delta);
                zimgui.Text("time: %.3f s", elapsed);
                zimgui.Text("frame: %.3f s", frame_time);
            }
            zimgui.End();

            if (zimgui.Begin("Export")) {
                zimgui.Text("Size: %dx%d", frame.width, frame.height);
                zimgui.Text("Framerate: %d", framerate);
                _ = zimgui.InputInt("Frame count", &export_frame_count);
                _ = zimgui.InputFloat("Time start", &export_time_start);
                if (zimgui.Button("Export sequence")) {
                    const dir = try nfd.saveFileDialog(null, null);
                    if (dir) |d| exportation: {
                        defer nfd.freePath(d);

                        zimgui.End();
                        imgui.endDrawing();

                        std.fs.cwd().access(d, .{}) catch
                            std.fs.cwd().makeDir(d) catch {
                            try std.io.getStdErr().writer().print("Failed to create directory {s}\n", .{d});
                            break :exportation;
                        };

                        particle.runInit(.{
                            .delta_time = interval,
                            .time = 0.0,
                        });

                        for (0..@intCast(export_frame_count)) |idx| {
                            const time = export_time_start + cast.cast(f32, idx) / cast.cast(f32, framerate);
                            std.debug.print("Exporting frame {d} at time {d}\n", .{ idx, time });
                            particle.runUpdate(.{
                                .delta_time = interval,
                                .time = time,
                            });

                            Frame.bind(frame);
                            Frame.setViewport(frame);
                            zgl.clear(.{ .color = true, .depth = true });
                            particle.drawParticles();
                            Frame.bind(null);

                            zgl.clear(.{ .color = true });
                            imgui.beginDrawing();
                            if (zimgui.Begin("Exporting...")) {
                                zimgui.Text("Frame %d", idx);
                                zimgui.Text("Time %f", time);
                                zimgui.Image(
                                    cast.enumCast(zimgui.TextureID, frame.texture),
                                    zimgui.Vec2.init(
                                        cast.cast(f32, frame.width),
                                        cast.cast(f32, frame.height),
                                    ),
                                );
                            }
                            zimgui.End();
                            imgui.endDrawing();

                            glfw.pollEvents();
                            glfw.swapBuffers(init.window);

                            const filename = try std.fmt.allocPrintZ(alloc.allocator, "{s}/frame_{d:0>3}.png", .{ d, idx });
                            defer alloc.allocator.free(filename);

                            image.saveTexture(frame.texture, filename, .{
                                .width = frame.width,
                                .height = frame.height,
                                .pixel_format = .rgba,
                                .pixel_type = .unsigned_byte,
                            }) catch |err| {
                                try std.io.getStdErr().writer().print("Failed to save {s}\nError: {!}\n", .{ filename, err });
                                break;
                            };
                        }
                        continue;
                    }
                }
                if (zimgui.Button("Export frame")) {
                    image.exportTexture(frame.texture, .{
                        .width = frame.width,
                        .height = frame.height,
                        .pixel_format = .rgba,
                        .pixel_type = .unsigned_byte,
                    }) catch |err| {
                        try std.io.getStdErr().writer().print("Failed to export\nError: {!}\n", .{err});
                    };
                }
            }
            zimgui.End();

            if (zimgui.Begin("Parameters")) {
                zimgui.SeparatorText("Frame");
                if (zimgui.InputInt2("Frame Size", &frame_size)) {
                    try frame.resize(cast.cast(usize, frame_size[0]), cast.cast(usize, frame_size[1]));
                    projection_params.frame_aspect =
                        cast.cast(f32, frame_size[0]) / cast.cast(f32, frame_size[1]);
                    perspective_zlm = generateProjection(projection_params);
                }
                if (zimgui.InputInt("Framerate", &framerate)) {
                    if (framerate < 1) {
                        framerate = 1;
                    }
                    interval = 1.0 / cast.cast(f32, framerate);
                }
                if (zimgui.Checkbox("VSync", &vsync)) {
                    glfw.swapInterval(cast.cast(c_int, vsync));
                    if (!vsync) {
                        interval = 1.0 / cast.cast(f32, framerate);
                        last_frame = now;
                    }
                }
                zimgui.Separator();
                zimgui.SeparatorText("Camera");
                var view_edit = false;
                view_edit = zimgui.SliderFloat3("Position", @ptrCast(&camera_position), -3, 3) or view_edit;
                view_edit = zimgui.SliderFloat3("Target", @ptrCast(&camera_target), -1, 1) or view_edit;
                if (view_edit) {
                    view_matrix = zlm.Mat4
                        .createLookAt(camera_position, camera_target, camera_up);
                }
                var proj_edit = false;
                proj_edit = zimgui.Checkbox("Perspective", &projection_params.is_perspective) or proj_edit;
                if (projection_params.is_perspective) {
                    proj_edit = zimgui.SliderFloat("FOV", &projection_params.perspective_fov, 0, 180) or proj_edit;
                } else {
                    proj_edit = zimgui.SliderFloat("Size", &projection_params.orthographic_size, 0.001, 10) or proj_edit;
                }
                proj_edit = zimgui.SliderFloat("Aspect", &projection_params.user_aspect, 0.1, 10) or proj_edit;
                proj_edit = zimgui.SliderFloat("Near", &projection_params.near, 0.001, 10) or proj_edit;
                proj_edit = zimgui.SliderFloat("Far", &projection_params.far, 0.001, 10) or proj_edit;
                if (proj_edit) {
                    perspective_zlm = generateProjection(projection_params);
                }

                zimgui.Separator();
                zimgui.SeparatorText("Particles");
                if (zimgui.Button("Load shader")) {
                    const file = try nfd.openFileDialog("glsl", null);
                    if (file) |f| {
                        defer nfd.freePath(f);
                        file_states.loadShader(f) catch {};
                        start = glfw.getTime();
                        particle.runInit(.{
                            .delta_time = interval,
                            .time = 0.0,
                        });
                    }
                }
                zimgui.SameLine();
                if (zimgui.Button("Reload")) {
                    file_states.reloadShader() catch {};
                    start = glfw.getTime();
                    particle.runInit(.{
                        .delta_time = interval,
                        .time = 0.0,
                    });
                }
                if (zimgui.InputInt("Count", &particle_count)) {
                    particle.setCount(cast.cast(usize, particle_count));
                    start = glfw.getTime();
                    particle.runInit(.{
                        .delta_time = interval,
                        .time = 0.0,
                    });
                }
                if (zimgui.BeginCombo("Appearance", particle_appearance.toString().ptr)) {
                    for (particle.ParticleAppearance.all_values) |value| {
                        if (zimgui.Selectable_Bool(value.toString().ptr)) {
                            particle_appearance = value;
                        }
                    }
                    zimgui.EndCombo();
                }
                if (zimgui.SliderFloat("Transparency threshold", &particle_transparency_threshold, 0.0, 1.0)) {}
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
                    .x = (size.x - cast.cast(f32, frame.width)) / 2.0,
                    .y = (size.y - cast.cast(f32, frame.height)) / 2.0,
                });
                zimgui.Image(
                    cast.enumCast(zimgui.TextureID, frame.texture),
                    zimgui.Vec2.init(
                        cast.cast(f32, frame.width),
                        cast.cast(f32, frame.height),
                    ),
                );
            }
            zimgui.End();
        }

        imgui.endDrawing();

        glfw.pollEvents();
        glfw.swapBuffers(init.window);

        last = now;
    }
}

fn changeShader(path: [:0]const u8, reload: bool) anyerror!void {
    try particle.loadProgram(path, reload);
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

const ProjectionParameters = struct {
    is_perspective: bool = true,
    perspective_fov: f32 = FOV,
    orthographic_size: f32 = 2.0,
    frame_aspect: f32 = 1.0,
    user_aspect: f32 = 1.0,
    near: f32 = NEAR,
    far: f32 = FAR,
};
fn generateProjection(params: ProjectionParameters) zlm.Mat4 {
    const fov = std.math.rad_per_deg * params.perspective_fov;
    const aspect = params.user_aspect * params.frame_aspect;
    const size_x = params.orthographic_size * aspect / 2;
    const size_y = params.orthographic_size / 2;
    const near = params.near;
    const far = params.far;
    return switch (params.is_perspective) {
        true => zlm.Mat4
            .createPerspective(fov, aspect, near, far),
        false => zlm.Mat4
            .createOrthogonal(-size_x, size_x, -size_y, size_y, near, far),
    };
}
