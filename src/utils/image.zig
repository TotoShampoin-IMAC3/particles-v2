const std = @import("std");
const zstbi = @import("zstbi");
const zgl = @import("zgl");
const nfd = @import("nfd");
const alloc = @import("../managers/allocator.zig");

pub fn init() void {
    zstbi.init(alloc.allocator);
    zstbi.setFlipVerticallyOnLoad(true);
}
pub fn deinit() void {
    zstbi.deinit();
}

pub fn loadTexture(path: [:0]const u8) !zgl.Texture {
    var image = try zstbi.Image.loadFromFile(path, 0);
    defer image.deinit();

    var success = false;
    const texture = zgl.Texture.create(.@"2d");
    defer if (!success) zgl.Texture.delete(texture);

    if (image.is_hdr) {
        return error.UnsupportedImageFormat;
    }

    const format: zgl.PixelFormat = switch (image.num_components) {
        1 => .red,
        2 => .rg,
        3 => .rgb,
        4 => .rgba,
        else => return error.UnsupportedImageFormat,
    };
    const internal_format: zgl.TextureInternalFormat = switch (image.num_components) {
        1 => .r8,
        2 => .rg8,
        3 => .rgb8,
        4 => .rgba8,
        else => return error.UnsupportedImageFormat,
    };
    const _type: zgl.PixelType = switch (image.bytes_per_component) {
        1 => .unsigned_byte,
        2 => .unsigned_short,
        4 => .unsigned_int,
        else => return error.UnsupportedImageFormat,
    };

    zgl.Texture.bind(texture, .@"2d");
    zgl.textureImage2D(.@"2d", 0, internal_format, image.width, image.height, format, _type, image.data.ptr);
    zgl.Texture.parameter(texture, .wrap_r, .clamp_to_edge);
    zgl.Texture.parameter(texture, .wrap_s, .clamp_to_edge);
    zgl.Texture.parameter(texture, .wrap_t, .clamp_to_edge);
    zgl.Texture.parameter(texture, .min_filter, .linear);
    zgl.Texture.parameter(texture, .mag_filter, .linear);
    zgl.Texture.generateMipmap(texture);

    success = true;
    return texture;
}

pub fn fetchTexture() !zgl.Texture {
    const file = try nfd.openFileDialog("png,jpg,jpeg,tga,bmp,psd,gif,pic,pnm", null);
    if (file) |f| {
        defer nfd.freePath(f);
        return loadTexture(f);
    }
    return error.NoFileSelected;
}

pub fn replaceTexture(texture: *zgl.Texture) !void {
    const new_texture = try fetchTexture();
    zgl.Texture.delete(texture.*);
    texture.* = new_texture;
}

pub const TextureData = struct {
    width: usize,
    height: usize,
    pixel_format: zgl.PixelFormat,
    pixel_type: zgl.PixelType,
    jpeg_quality: u32 = 90,
};
pub fn saveTexture(texture: zgl.Texture, path: [:0]const u8, data: TextureData) !void {
    zgl.bindTexture(texture, .@"2d");

    const channels = switch (data.pixel_format) {
        .red => @as(u32, 1),
        .rg => @as(u32, 2),
        .rgb => @as(u32, 3),
        .rgba => @as(u32, 4),
        else => return error.UnsupportedImageFormat,
    };
    const bytes_per_component = switch (data.pixel_type) {
        .unsigned_byte => @as(u32, 1),
        .unsigned_short => @as(u32, 2),
        .unsigned_int => @as(u32, 4),
        else => return error.UnsupportedImageFormat,
    };

    var image = try zstbi.Image.createEmpty(
        @intCast(data.width),
        @intCast(data.height),
        channels,
        .{
            .bytes_per_component = bytes_per_component,
        },
    );
    defer image.deinit();
    zgl.getTexImage(.@"2d", 0, data.pixel_format, data.pixel_type, image.data.ptr);

    const is_png = std.mem.endsWith(u8, path, "png");
    const is_jpg = std.mem.endsWith(u8, path, "jpg") or std.mem.endsWith(u8, path, "jpeg");
    try zstbi.Image.writeToFile(
        image,
        path,
        if (is_png) .png else if (is_jpg) .{
            .jpg = .{ .quality = data.jpeg_quality },
        } else return error.UnsupportedImageFormat,
    );
}
pub fn exportTexture(texture: zgl.Texture, data: TextureData) !void {
    const file = try nfd.saveFileDialog("png", null);
    if (file) |f| {
        defer nfd.freePath(f);
        try saveTexture(texture, f, data);
    }
}
