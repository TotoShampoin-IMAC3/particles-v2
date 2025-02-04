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
    var vsync = true;
    glfw.swapInterval(cast.cast(c_int, vsync));

    var particle_count = cast.cast(i32, particle.count);
    var particle_appearance = particle.ParticleAppearance.square;

    // ===== CAMERA =====

    const u_view = particle_program.uniformLocation("u_view");
    const u_projection = particle_program.uniformLocation("u_projection");
    const u_appearance = particle_program.uniformLocation("u_appearance");

    var camera_position = zlm.Vec3.unitZ.scale(-POV);
    var camera_target = zlm.Vec3.zero;
    const camera_up = zlm.Vec3.unitY;

    var view_matrix = zlm.Mat4
        .createLookAt(camera_position, camera_target, camera_up);
    var projection_params = ProjectionParameters{
        .perspective = .{
            .fov = FOV,
            .aspect = 1.0,
            .near = NEAR,
            .far = FAR,
        },
        .frame_aspect = cast.cast(f32, frame.width) / cast.cast(f32, frame.height),
    };
    var perspective_zlm = generateProjection(projection_params);

    zgl.enable(.depth_test);

    particle.runInit();

    // ===== EVENTS =====

    imgui.start(init.window);
    defer imgui.stop();

    zimgui.GetIO().ConfigFlags.DockingEnable = true;

    // ===== MAIN LOOP =====

    const start = glfw.getTime();
    var last = start;
    var last_frame = start;
    while (glfw.windowShouldClose(init.window) == false) {
        const now = glfw.getTime();
        // const elapsed = now - start;
        const delta = now - last;

        if (vsync) {
            particle.runUpdate(.{
                .delta_time = cast.cast(f32, delta),
                .time = cast.cast(f32, now - start),
            });
        } else {
            if (now - last_frame > interval) {
                particle.runUpdate(.{
                    .delta_time = interval,
                    .time = cast.cast(f32, now - start),
                });
                last_frame = now;
            }
        }

        zgl.Program.use(particle_program);
        particle_program.uniformMatrix4(u_view, false, &.{view_matrix.fields});
        particle_program.uniformMatrix4(u_projection, false, &.{perspective_zlm.fields});
        particle_program.uniform1i(u_appearance, cast.cast(i32, particle_appearance));

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
                const f64_framerate = cast.cast(f64, framerate);
                zimgui.Text("%.3f ms/frame (%.1f FPS)", 1000.0 / delta, 1.0 / delta);
                zimgui.Text("time: %.3f s", now);
                zimgui.Text("frame: %.3f s", @floor((now - start) * f64_framerate) / f64_framerate);
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
                    proj_edit = zimgui.SliderFloat("FOV", &projection_params.perspective.fov, 0, 180) or proj_edit;
                    proj_edit = zimgui.SliderFloat("Aspect", &projection_params.perspective.aspect, 0.1, 10) or proj_edit;
                    proj_edit = zimgui.SliderFloat("Near", &projection_params.perspective.near, 0.001, 10) or proj_edit;
                    proj_edit = zimgui.SliderFloat("Far", &projection_params.perspective.far, 0.001, 10) or proj_edit;
                } else {
                    proj_edit = zimgui.SliderFloat("Size", &projection_params.orthographic.size, 0.001, 10) or proj_edit;
                    proj_edit = zimgui.SliderFloat("Aspect", &projection_params.orthographic.aspect, 0.1, 10) or proj_edit;
                    proj_edit = zimgui.SliderFloat("Depth", &projection_params.orthographic.depth, 0.001, 10) or proj_edit;
                }
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
                        particle.runInit();
                    }
                }
                zimgui.SameLine();
                if (zimgui.Button("Reload")) {
                    file_states.reloadShader() catch {};
                    particle.runInit();
                }
                if (zimgui.InputInt("Count", &particle_count)) {
                    particle.setCount(cast.cast(usize, particle_count));
                    particle.runInit();
                }
                if (zimgui.BeginCombo("Appearance", particle_appearance.toString().ptr)) {
                    for (particle.ParticleAppearance.all_values) |value| {
                        if (zimgui.Selectable_Bool(value.toString().ptr)) {
                            particle_appearance = value;
                        }
                    }
                    zimgui.EndCombo();
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
    perspective: struct {
        fov: f32 = FOV,
        aspect: f32 = 1.0,
        near: f32 = NEAR,
        far: f32 = FAR,
    } = .{},
    orthographic: struct {
        size: f32 = 2.0,
        aspect: f32 = 1.0,
        depth: f32 = 2.0,
    } = .{},
    is_perspective: bool = true,
    frame_aspect: f32 = 1.0,
};
fn generateProjection(params: ProjectionParameters) zlm.Mat4 {
    return switch (params.is_perspective) {
        true => zlm.Mat4
            .createPerspective(
            std.math.rad_per_deg * params.perspective.fov,
            params.perspective.aspect * params.frame_aspect,
            params.perspective.near,
            params.perspective.far,
        ),
        false => zlm.Mat4
            .createOrthogonal(
            -params.orthographic.size * params.frame_aspect * params.orthographic.aspect / 2,
            params.orthographic.size * params.frame_aspect * params.orthographic.aspect / 2,
            -params.orthographic.size / 2,
            params.orthographic.size / 2,
            0,
            params.orthographic.depth,
        ),
    };
}
