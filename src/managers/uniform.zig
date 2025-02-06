const std = @import("std");
const zimgui = @import("Zig-ImGui");
const alloc = @import("allocator.zig");
const cast = @import("../utils/cast.zig");

pub const UniformType = enum {
    int,
    uint,
    bool,
    float,
    vec2,
    vec3,
    vec4,
    ivec2,
    ivec3,
    ivec4,
    mat2,
    mat3,
    mat4,
};
pub const UniformUnion = union(UniformType) {
    int: i32,
    uint: u32,
    bool: bool,
    float: f32,
    vec2: [2]f32,
    vec3: [3]f32,
    vec4: [4]f32,
    ivec2: [2]i32,
    ivec3: [3]i32,
    ivec4: [4]i32,
    mat2: [2][2]f32,
    mat3: [3][3]f32,
    mat4: [4][4]f32,
};
pub const UniformName = struct {
    name: []const u8,
    type: UniformType,
    value: UniformUnion = undefined,
    locations: []?u32 = undefined,
    ui: UniformUI = undefined,

    pub fn fromLine(line: []const u8) !?UniformName {
        const trim0 = std.mem.trim(u8, line, "\r");
        // const trim = std.mem.trim(u8, trim0, ";");
        var line_t = std.mem.tokenizeSequence(u8, trim0, ";");
        const code = if (line_t.next()) |l| l else return null;
        var tokens = std.mem.tokenizeSequence(u8, code, " ");
        const first = tokens.next() orelse return null;
        if (!std.mem.eql(u8, first, "uniform")) return null;

        const second = tokens.next() orelse return null;
        const @"type": UniformType = t: {
            if (std.mem.eql(u8, second, "int")) break :t UniformType.int;
            if (std.mem.eql(u8, second, "uint")) break :t UniformType.uint;
            if (std.mem.eql(u8, second, "bool")) break :t UniformType.bool;
            if (std.mem.eql(u8, second, "float")) break :t UniformType.float;
            if (std.mem.eql(u8, second, "vec2")) break :t UniformType.vec2;
            if (std.mem.eql(u8, second, "vec3")) break :t UniformType.vec3;
            if (std.mem.eql(u8, second, "vec4")) break :t UniformType.vec4;
            if (std.mem.eql(u8, second, "ivec2")) break :t UniformType.ivec2;
            if (std.mem.eql(u8, second, "ivec3")) break :t UniformType.ivec3;
            if (std.mem.eql(u8, second, "ivec4")) break :t UniformType.ivec4;
            if (std.mem.eql(u8, second, "mat2")) break :t UniformType.mat2;
            if (std.mem.eql(u8, second, "mat3")) break :t UniformType.mat3;
            if (std.mem.eql(u8, second, "mat4")) break :t UniformType.mat4;
            break :t null;
        } orelse return null;

        const third0 = tokens.next() orelse return null;
        const third = std.mem.trim(u8, third0, ";");
        const name = try alloc.allocator.alloc(u8, third.len);
        std.mem.copyForwards(u8, name, third);

        const fourth = if (line_t.next()) |l| std.mem.trim(u8, l, " ") else "";

        const zero: UniformUnion = switch (@"type") {
            .int => .{ .int = 0 },
            .uint => .{ .uint = 0 },
            .bool => .{ .bool = false },
            .float => .{ .float = 0.0 },
            .vec2 => .{ .vec2 = .{ 0.0, 0.0 } },
            .vec3 => .{ .vec3 = .{ 0.0, 0.0, 0.0 } },
            .vec4 => .{ .vec4 = .{ 0.0, 0.0, 0.0, 0.0 } },
            .ivec2 => .{ .ivec2 = .{ 0, 0 } },
            .ivec3 => .{ .ivec3 = .{ 0, 0, 0 } },
            .ivec4 => .{ .ivec4 = .{ 0, 0, 0, 0 } },
            .mat2 => .{ .mat2 = .{ .{ 0.0, 0.0 }, .{ 0.0, 0.0 } } },
            .mat3 => .{ .mat3 = .{ .{ 0.0, 0.0, 0.0 }, .{ 0.0, 0.0, 0.0 }, .{ 0.0, 0.0, 0.0 } } },
            .mat4 => .{ .mat4 = .{ .{ 0.0, 0.0, 0.0, 0.0 }, .{ 0.0, 0.0, 0.0, 0.0 }, .{ 0.0, 0.0, 0.0, 0.0 }, .{ 0.0, 0.0, 0.0, 0.0 } } },
            // else => unreachable,
        };

        const ui = try UniformUI.fromLine(fourth, zero);

        return UniformName{
            .name = name,
            .type = @"type",
            .value = ui.default,
            .ui = ui,
        };
    }
    pub fn delete(self: *UniformName) void {
        alloc.allocator.free(self.name);
    }

    pub fn deleteAll(uniforms: []UniformName) void {
        for (uniforms) |*uniform| {
            uniform.delete();
            alloc.allocator.free(uniform.locations);
            uniform.locations = undefined;
        }
        alloc.allocator.free(uniforms);
    }
};

pub const UniformUIType = enum {
    normal,
    slider,
    color,
    angle,
};
pub const UniformUIUnion = union(UniformUIType) {
    normal: void,
    slider: struct {
        min: f32,
        max: f32,
    },
    color: void,
    angle: void,
};
pub const UniformUI = struct {
    type: UniformUIType,
    data: UniformUIUnion,
    default: UniformUnion,
    reset_on_change: bool = false,

    pub fn fromLine(line: []const u8, zero: UniformUnion) !UniformUI {
        var value = UniformUI{
            .type = .normal,
            .data = .normal,
            .default = zero,
            .reset_on_change = false,
        };

        std.debug.print("{s}\n", .{line});

        if (!std.mem.startsWith(u8, line, "//@ui")) return value;
        var parameters = std.mem.tokenizeSequence(u8, std.mem.trim(u8, line[5..], " "), ",");

        while (parameters.next()) |parameter0| {
            const parameter = std.mem.trim(u8, parameter0, " ");
            var tokens = std.mem.tokenizeSequence(u8, parameter, " ");
            while (tokens.next()) |token| {
                if (std.mem.eql(u8, token, "default")) {
                    const len: u32 = switch (zero) {
                        .int, .uint, .bool, .float => 1,
                        .vec2, .ivec2 => 2,
                        .vec3, .ivec3 => 3,
                        .vec4, .ivec4 => 4,
                        .mat2 => 4,
                        .mat3 => 9,
                        .mat4 => 16,
                    };
                    for (0..len) |idx| {
                        if (tokens.next()) |value_string| {
                            switch (zero) {
                                .int => value.default.int = try std.fmt.parseInt(i32, value_string, 10),
                                .uint => value.default.uint = try std.fmt.parseUnsigned(u32, value_string, 10),
                                .bool => value.default.bool = if (std.mem.eql(u8, value_string, "true")) true else false,
                                .float => value.default.float = try std.fmt.parseFloat(f32, value_string),
                                .vec2 => value.default.vec2[idx] = try std.fmt.parseFloat(f32, value_string),
                                .vec3 => value.default.vec3[idx] = try std.fmt.parseFloat(f32, value_string),
                                .vec4 => value.default.vec4[idx] = try std.fmt.parseFloat(f32, value_string),
                                .ivec2 => value.default.ivec2[idx] = try std.fmt.parseInt(i32, value_string, 10),
                                .ivec3 => value.default.ivec3[idx] = try std.fmt.parseInt(i32, value_string, 10),
                                .ivec4 => value.default.ivec4[idx] = try std.fmt.parseInt(i32, value_string, 10),
                                .mat2 => value.default.mat2[idx / 2][idx % 2] = try std.fmt.parseFloat(f32, value_string),
                                .mat3 => value.default.mat3[idx / 3][idx % 3] = try std.fmt.parseFloat(f32, value_string),
                                .mat4 => value.default.mat4[idx / 4][idx % 4] = try std.fmt.parseFloat(f32, value_string),
                                // else => unreachable,
                            }
                        }
                    }
                } else if (std.mem.eql(u8, token, "slider")) {
                    const min = tokens.next() orelse "0";
                    const max = tokens.next() orelse "1";
                    value.type = .slider;
                    value.data = .{ .slider = .{
                        .min = try std.fmt.parseFloat(f32, min),
                        .max = try std.fmt.parseFloat(f32, max),
                    } };
                } else if (std.mem.eql(u8, token, "color")) {
                    value.type = .color;
                } else if (std.mem.eql(u8, token, "angle")) {
                    value.type = .angle;
                } else if (std.mem.eql(u8, token, "reset")) {
                    value.reset_on_change = true;
                }
            }
        }

        value = value;

        return value;
    }

    pub const ImguiFunctions = struct {
        Checkbox: *const fn (label: ?[*:0]const u8, v: *bool, data: UniformUIUnion) bool,
        InputInt: *const fn (label: ?[*:0]const u8, v: *i32, data: UniformUIUnion) bool,
        InputInt2: *const fn (label: ?[*:0]const u8, v: *[2]i32, data: UniformUIUnion) bool,
        InputInt3: *const fn (label: ?[*:0]const u8, v: *[3]i32, data: UniformUIUnion) bool,
        InputInt4: *const fn (label: ?[*:0]const u8, v: *[4]i32, data: UniformUIUnion) bool,
        InputFloat: *const fn (label: ?[*:0]const u8, v: *f32, data: UniformUIUnion) bool,
        InputFloat2: *const fn (label: ?[*:0]const u8, v: *[2]f32, data: UniformUIUnion) bool,
        InputFloat3: *const fn (label: ?[*:0]const u8, v: *[3]f32, data: UniformUIUnion) bool,
        InputFloat4: *const fn (label: ?[*:0]const u8, v: *[4]f32, data: UniformUIUnion) bool,
    };

    pub fn imguiFunctions(self: UniformUI) ImguiFunctions {
        const inputs = struct {
            pub fn inputInt(label: ?[*:0]const u8, v: *i32, _: UniformUIUnion) bool {
                return zimgui.InputInt(label, v);
            }
            pub fn inputInt2(label: ?[*:0]const u8, v: *[2]i32, _: UniformUIUnion) bool {
                return zimgui.InputInt2(label, v);
            }
            pub fn inputInt3(label: ?[*:0]const u8, v: *[3]i32, _: UniformUIUnion) bool {
                return zimgui.InputInt3(label, v);
            }
            pub fn inputInt4(label: ?[*:0]const u8, v: *[4]i32, _: UniformUIUnion) bool {
                return zimgui.InputInt4(label, v);
            }
            pub fn inputFloat(label: ?[*:0]const u8, v: *f32, _: UniformUIUnion) bool {
                return zimgui.InputFloat(label, v);
            }
            pub fn inputFloat2(label: ?[*:0]const u8, v: *[2]f32, _: UniformUIUnion) bool {
                return zimgui.InputFloat2(label, v);
            }
            pub fn inputFloat3(label: ?[*:0]const u8, v: *[3]f32, _: UniformUIUnion) bool {
                return zimgui.InputFloat3(label, v);
            }
            pub fn inputFloat4(label: ?[*:0]const u8, v: *[4]f32, _: UniformUIUnion) bool {
                return zimgui.InputFloat4(label, v);
            }
        };
        const sliders = struct {
            pub fn sliderInt(label: ?[*:0]const u8, v: *i32, data: UniformUIUnion) bool {
                return zimgui.SliderInt(label, v, cast.cast(i32, data.slider.min), cast.cast(i32, data.slider.max));
            }
            pub fn sliderInt2(label: ?[*:0]const u8, v: *[2]i32, data: UniformUIUnion) bool {
                return zimgui.SliderInt2(label, v, cast.cast(i32, data.slider.min), cast.cast(i32, data.slider.max));
            }
            pub fn sliderInt3(label: ?[*:0]const u8, v: *[3]i32, data: UniformUIUnion) bool {
                return zimgui.SliderInt3(label, v, cast.cast(i32, data.slider.min), cast.cast(i32, data.slider.max));
            }
            pub fn sliderInt4(label: ?[*:0]const u8, v: *[4]i32, data: UniformUIUnion) bool {
                return zimgui.SliderInt4(label, v, cast.cast(i32, data.slider.min), cast.cast(i32, data.slider.max));
            }
            pub fn sliderFloat(label: ?[*:0]const u8, v: *f32, data: UniformUIUnion) bool {
                return zimgui.SliderFloat(label, v, data.slider.min, data.slider.max);
            }
            pub fn sliderFloat2(label: ?[*:0]const u8, v: *[2]f32, data: UniformUIUnion) bool {
                return zimgui.SliderFloat2(label, v, data.slider.min, data.slider.max);
            }
            pub fn sliderFloat3(label: ?[*:0]const u8, v: *[3]f32, data: UniformUIUnion) bool {
                return zimgui.SliderFloat3(label, v, data.slider.min, data.slider.max);
            }
            pub fn sliderFloat4(label: ?[*:0]const u8, v: *[4]f32, data: UniformUIUnion) bool {
                return zimgui.SliderFloat4(label, v, data.slider.min, data.slider.max);
            }
        };
        const other = struct {
            pub fn checkbox(label: ?[*:0]const u8, v: *bool, _: UniformUIUnion) bool {
                return zimgui.Checkbox(label, v);
            }
            pub fn colorEdit3(label: ?[*:0]const u8, v: *[3]f32, _: UniformUIUnion) bool {
                return zimgui.ColorEdit3(label, v);
            }
            pub fn colorEdit4(label: ?[*:0]const u8, v: *[4]f32, _: UniformUIUnion) bool {
                return zimgui.ColorEdit4(label, v);
            }
            pub fn sliderAngle(label: ?[*:0]const u8, v: *f32, _: UniformUIUnion) bool {
                return zimgui.SliderAngle(label, v);
            }
        };
        const none = struct {
            pub fn checkbox(_: ?[*:0]const u8, _: *bool, _: UniformUIUnion) bool {
                unreachable;
            }
            pub fn inputInt(_: ?[*:0]const u8, _: *i32, _: UniformUIUnion) bool {
                unreachable;
            }
            pub fn inputInt2(_: ?[*:0]const u8, _: *[2]i32, _: UniformUIUnion) bool {
                unreachable;
            }
            pub fn inputInt3(_: ?[*:0]const u8, _: *[3]i32, _: UniformUIUnion) bool {
                unreachable;
            }
            pub fn inputInt4(_: ?[*:0]const u8, _: *[4]i32, _: UniformUIUnion) bool {
                unreachable;
            }
            pub fn inputFloat(_: ?[*:0]const u8, _: *f32, _: UniformUIUnion) bool {
                unreachable;
            }
            pub fn inputFloat2(_: ?[*:0]const u8, _: *[2]f32, _: UniformUIUnion) bool {
                unreachable;
            }
            pub fn inputFloat3(_: ?[*:0]const u8, _: *[3]f32, _: UniformUIUnion) bool {
                unreachable;
            }
            pub fn inputFloat4(_: ?[*:0]const u8, _: *[4]f32, _: UniformUIUnion) bool {
                unreachable;
            }
        };

        return switch (self.type) {
            .normal => .{
                .Checkbox = other.checkbox,
                .InputInt = inputs.inputInt,
                .InputInt2 = inputs.inputInt2,
                .InputInt3 = inputs.inputInt3,
                .InputInt4 = inputs.inputInt4,
                .InputFloat = inputs.inputFloat,
                .InputFloat2 = inputs.inputFloat2,
                .InputFloat3 = inputs.inputFloat3,
                .InputFloat4 = inputs.inputFloat4,
            },
            .slider => .{
                .Checkbox = none.checkbox,
                .InputInt = sliders.sliderInt,
                .InputInt2 = sliders.sliderInt2,
                .InputInt3 = sliders.sliderInt3,
                .InputInt4 = sliders.sliderInt4,
                .InputFloat = sliders.sliderFloat,
                .InputFloat2 = sliders.sliderFloat2,
                .InputFloat3 = sliders.sliderFloat3,
                .InputFloat4 = sliders.sliderFloat4,
            },
            .color => .{
                .Checkbox = none.checkbox,
                .InputInt = none.inputInt,
                .InputInt2 = none.inputInt2,
                .InputInt3 = none.inputInt3,
                .InputInt4 = none.inputInt4,
                .InputFloat = none.inputFloat,
                .InputFloat2 = none.inputFloat2,
                .InputFloat3 = other.colorEdit3,
                .InputFloat4 = other.colorEdit4,
            },
            .angle => .{
                .Checkbox = none.checkbox,
                .InputInt = none.inputInt,
                .InputInt2 = none.inputInt2,
                .InputInt3 = none.inputInt3,
                .InputInt4 = none.inputInt4,
                .InputFloat = other.sliderAngle,
                .InputFloat2 = none.inputFloat2,
                .InputFloat3 = none.inputFloat3,
                .InputFloat4 = none.inputFloat4,
            },
        };
    }
};
