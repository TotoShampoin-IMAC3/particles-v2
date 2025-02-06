const std = @import("std");
const zgl = @import("zgl");
const alloc = @import("allocator.zig");
const _uniform = @import("uniform.zig");

pub fn loadShader(shaderType: zgl.ShaderType, source: []const u8) !zgl.Shader {
    const shader = zgl.Shader.create(shaderType);
    zgl.Shader.source(shader, 1, &.{source});
    zgl.Shader.compile(shader);
    if (zgl.Shader.get(shader, .compile_status) == 0) {
        const log = try zgl.Shader.getCompileLog(shader, alloc.allocator);
        defer alloc.allocator.free(log);
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
    zgl.Shader.source(shader, N, sources[0..N]);
    zgl.Shader.compile(shader);
    if (zgl.Shader.get(shader, .compile_status) == 0) {
        const log = try zgl.Shader.getCompileLog(shader, alloc.allocator);
        defer alloc.allocator.free(log);
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
        const log = try zgl.Program.getCompileLog(program, alloc.allocator);
        defer alloc.allocator.free(log);
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
        const log = try zgl.Program.getCompileLog(program, alloc.allocator);
        defer alloc.allocator.free(log);
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
        const log = try zgl.Program.getCompileLog(program, alloc.allocator);
        defer alloc.allocator.free(log);
        std.debug.print("Program linking failed: {s}\n", .{log});
        return error.ProgramLinkingFailed;
    }
    return program;
}

/// Extracts uniform names from a GLSL source.
pub fn getUniformsFromSource(source: []const u8) ![]_uniform.UniformName {
    var success = false;
    var lines = std.mem.splitSequence(u8, source, "\n");
    var uniforms = std.ArrayList(_uniform.UniformName).init(alloc.allocator);
    defer if (!success) uniforms.deinit();
    while (lines.next()) |line| {
        if (try _uniform.UniformName.fromLine(line)) |uniform| {
            try uniforms.append(uniform);
        }
    }
    success = true;
    return try uniforms.toOwnedSlice();
}
