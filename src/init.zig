const std = @import("std");
const zglfw = @import("zglfw");
const zgl = @import("zgl");

pub var allocator: std.mem.Allocator = undefined;

pub fn getProcAddressWrapper(
    comptime _: type,
    symbolName: [:0]const u8,
) ?*const anyopaque {
    return zglfw.getProcAddress(symbolName);
}

pub fn loadGl() !void {
    try zgl.loadExtensions(void, getProcAddressWrapper);
}
