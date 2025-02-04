pub fn cast(t: type, value: anytype) t {
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
            .Pointer => @as(t, @intFromPtr(value)),
            .Enum => @as(t, @intCast(@intFromEnum(value))),
            else => @compileError("Unsupported"),
        },
        .Float => switch (@typeInfo(@TypeOf(value))) {
            .Bool => if (value) 1.0 else 0.0,
            .Int => @as(t, @floatFromInt(value)),
            .Float => @as(t, @floatCast(value)),
            else => @compileError("Unsupported"),
        },
        .Pointer => switch (@typeInfo(@TypeOf(value))) {
            .Pointer => @as(t, value),
            .Int => @as(t, @ptrFromInt(value)),
            else => @compileError("Unsupported"),
        },
        .Enum => switch (@typeInfo(@TypeOf(value))) {
            .Int => @as(t, @enumFromInt(value)),
            .Enum => enumCast(t, value),
            else => @compileError("Unsupported"),
        },
        else => @compileError("Unsupported"),
    };
}
pub fn enumCast(t: type, value: anytype) t {
    return @enumFromInt(@intFromEnum(value));
}
