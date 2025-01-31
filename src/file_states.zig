const std = @import("std");
const nfd = @import("nfd");
const alloc = @import("managers/allocator.zig");

const save_file = "save.json";
const imgui_ini_file = "imgui.ini";
const default_shader_file = "res/default.glsl";

const default_save_file = @embedFile("defaults/save.json");
const default_imgui_ini_file = @embedFile("defaults/imgui.ini");

pub var dir_path: ?[:0]u8 = null;
pub var save_path: ?[:0]u8 = null;
pub var imgui_ini_path: ?[:0]u8 = null;

pub var current_shader_path: ?[:0]u8 = null;
pub var current_shader_dir_path: ?[]u8 = null;

pub var on_new_shader_loaded: ?*const fn (shader_path: [:0]const u8, reload: bool) anyerror!void = null;

pub fn init() !void {
    if (dir_path == null) {
        return;
    }
    const dir = try std.fs.selfExeDirPathAlloc(alloc.allocator);
    defer alloc.allocator.free(dir);
    dir_path = try std.mem.joinZ(alloc.allocator, "/", &.{dir});
    save_path = try std.mem.joinZ(alloc.allocator, "/", &.{ dir, save_file });
    imgui_ini_path = try std.mem.joinZ(alloc.allocator, "/", &.{ dir, imgui_ini_file });

    if (!fileExists(save_path.?)) {
        try std.fs.cwd().writeFile(.{
            .sub_path = save_path.?,
            .data = default_save_file,
        });
    }
    if (!fileExists(imgui_ini_path.?)) {
        try std.fs.cwd().writeFile(.{
            .sub_path = imgui_ini_path.?,
            .data = default_imgui_ini_file,
        });
    }
}
pub fn deinit() void {
    if (dir_path) |path| alloc.allocator.free(path);
    if (save_path) |path| alloc.allocator.free(path);
    if (imgui_ini_path) |path| alloc.allocator.free(path);
    if (current_shader_path) |path| alloc.allocator.free(path);
    // alloc.allocator.free(current_shader_dir_path);
}

pub fn fileExists(path: []const u8) bool {
    std.fs.cwd().access(path, .{}) catch return false;
    return true;
}

pub fn loadShader(path: []const u8) !void {
    if (current_shader_path) |csp| {
        alloc.allocator.free(csp);
    }
    if (current_shader_dir_path) |csdp| {
        alloc.allocator.free(csdp);
    }
    current_shader_path = try alloc.allocator.allocSentinel(u8, path.len, 0);
    std.mem.copyForwards(u8, current_shader_path.?, path);
    current_shader_dir_path =
        current_shader_path.?[0..(std.mem.lastIndexOf(u8, path, "/") orelse 0)];
    if (on_new_shader_loaded) |event| {
        try event(current_shader_path.?, false);
    }
}
pub fn reloadShader() !void {
    if (current_shader_path) |path|
        if (on_new_shader_loaded) |event|
            try event(path, true);
}
