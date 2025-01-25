const std = @import("std");

pub var gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;
pub var allocator: std.mem.Allocator = undefined;

pub fn init() !void {
    gpa = std.heap.GeneralPurposeAllocator(.{}){};
    allocator = gpa.allocator();
}

pub fn deinit() void {
    if (gpa.deinit() == .leak)
        std.debug.print("Memory leak detected!\n", .{});
}
