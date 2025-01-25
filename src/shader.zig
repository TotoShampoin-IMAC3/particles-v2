const std = @import("std");
const zgl = @import("zgl");
const init = @import("init.zig");

pub fn loadShader(shaderType: zgl.ShaderType, source: []const u8) !zgl.Shader {
    const shader = zgl.Shader.create(shaderType);
    zgl.Shader.source(shader, 1, &.{source});
    zgl.Shader.compile(shader);
    if (zgl.Shader.get(shader, .compile_status) == 0) {
        const log = try zgl.Shader.getCompileLog(shader, init.allocator);
        defer init.allocator.free(log);
        std.debug.print("Shader compilation failed: {s}\n", .{log});
        return error.ShaderCompilationFailed;
    }
    return shader;
}
pub fn loadShaderMultiSources(
    shaderType: zgl.ShaderType,
    comptime N: comptime_int,
    sources: [N][]const u8,
) !zgl.Shader {
    const shader = zgl.Shader.create(shaderType);
    zgl.Shader.source(shader, 2, sources[0..]);
    zgl.Shader.compile(shader);
    if (zgl.Shader.get(shader, .compile_status) == 0) {
        const log = try zgl.Shader.getCompileLog(shader, init.allocator);
        defer init.allocator.free(log);
        std.debug.print("Shader compilation failed: {s}\n", .{log});
        return error.ShaderCompilationFailed;
    }
    return shader;
}

pub fn loadShaders(
    vertexSource: []const u8,
    fragmentSource: []const u8,
) !zgl.Program {
    const program = zgl.Program.create();
    const _vertex = try loadShader(.vertex, vertexSource);
    defer zgl.Shader.delete(_vertex);
    const _fragment = try loadShader(.fragment, fragmentSource);
    defer zgl.Shader.delete(_fragment);
    zgl.Program.attach(program, _vertex);
    zgl.Program.attach(program, _fragment);
    zgl.Program.link(program);
    if (zgl.Program.get(program, .link_status) == 0) {
        const log = try zgl.Program.getCompileLog(program, init.allocator);
        defer init.allocator.free(log);
        std.debug.print("Program linking failed: {s}\n", .{log});
        return error.ProgramLinkingFailed;
    }
    return program;
}
pub fn loadCompute(computeSource: []const u8) !zgl.Program {
    const program = zgl.Program.create();
    const compute = try loadShader(.compute, computeSource);
    defer zgl.Shader.delete(compute);
    zgl.Program.attach(program, compute);
    zgl.Program.link(program);
    if (zgl.Program.get(program, .link_status) == 0) {
        const log = try zgl.Program.getCompileLog(program, init.allocator);
        defer init.allocator.free(log);
        std.debug.print("Program linking failed: {s}\n", .{log});
        return error.ProgramLinkingFailed;
    }
    return program;
}

pub fn loadComputeMultiSources(
    comptime N: comptime_int,
    computeSources: [N][]const u8,
) !zgl.Program {
    const program = zgl.Program.create();
    const compute = try loadShaderMultiSources(.compute, N, computeSources);
    defer zgl.Shader.delete(compute);
    zgl.Program.attach(program, compute);
    zgl.Program.link(program);
    if (zgl.Program.get(program, .link_status) == 0) {
        const log = try zgl.Program.getCompileLog(program, init.allocator);
        defer init.allocator.free(log);
        std.debug.print("Program linking failed: {s}\n", .{log});
        return error.ProgramLinkingFailed;
    }
    return program;
}

pub const UniformType = enum { int, uint, float, vec2, vec3, vec4 };
pub const Uniform = struct {
    name: []const u8,
    type: UniformType,

    pub fn fromLine(line: []const u8) !?Uniform {
        const trim0 = std.mem.trim(u8, line, "\r");
        const trim = std.mem.trim(u8, trim0, ";");
        var tokens = std.mem.tokenizeSequence(u8, trim, " ");
        const first = tokens.next() orelse return null;
        if (!std.mem.eql(u8, first, "uniform")) return null;

        const second = tokens.next() orelse return null;
        const @"type": UniformType = t: {
            if (std.mem.eql(u8, second, "int")) break :t UniformType.int;
            if (std.mem.eql(u8, second, "uint")) break :t UniformType.uint;
            if (std.mem.eql(u8, second, "float")) break :t UniformType.float;
            if (std.mem.eql(u8, second, "vec2")) break :t UniformType.vec2;
            if (std.mem.eql(u8, second, "vec3")) break :t UniformType.vec3;
            if (std.mem.eql(u8, second, "vec4")) break :t UniformType.vec4;
            break :t null;
        } orelse return null;

        const third = tokens.next() orelse return null;
        const name = try init.allocator.alloc(u8, third.len);
        std.mem.copyForwards(u8, name, third);

        return Uniform{ .name = name, .type = @"type" };
    }
    pub fn delete(self: *Uniform) void {
        init.allocator.free(self.name);
    }

    pub fn deleteAll(uniforms: []Uniform) void {
        for (uniforms) |*uniform| {
            uniform.delete();
        }
        init.allocator.free(uniforms);
    }
};

/// Extracts uniform names from a GLSL source.
pub fn getUniformsFromSource(source: []const u8) ![]Uniform {
    var lines = std.mem.splitSequence(u8, source, "\n");
    var uniforms = std.ArrayList(Uniform).init(init.allocator);
    while (lines.next()) |line| {
        if (try Uniform.fromLine(line)) |uniform| {
            try uniforms.append(uniform);
        }
    }
    return try uniforms.toOwnedSlice();
}
