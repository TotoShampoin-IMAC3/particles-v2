const alloc = @import("../managers/allocator.zig");
const zstbi = @import("zstbi");
const zgl = @import("zgl");
const nfd = @import("nfd");

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
