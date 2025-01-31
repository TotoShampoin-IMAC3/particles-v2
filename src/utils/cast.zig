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
pub fn enumCast(t: type, value: anytype) t {
    return @enumFromInt(@intFromEnum(value));
}
