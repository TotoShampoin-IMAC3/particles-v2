const std = @import("std");
const zgl = @import("zgl");
const alloc = @import("allocator.zig");

pub const Frame = struct {
    width: usize,
    height: usize,
    framebuffer: zgl.Framebuffer,
    renderbuffer: zgl.Renderbuffer,
    texture: zgl.Texture,

    pub fn create(width: usize, height: usize) !Frame {
        const framebuffer = zgl.Framebuffer.create();
        const renderbuffer = zgl.Renderbuffer.create();
        const texture = zgl.Texture.create(.@"2d");

        var res = Frame{
            .width = width,
            .height = height,
            .framebuffer = framebuffer,
            .renderbuffer = renderbuffer,
            .texture = texture,
        };

        try res.resize(width, height);

        return res;
    }
    pub fn delete(self: Frame) void {
        zgl.Framebuffer.delete(self.framebuffer);
        zgl.Renderbuffer.delete(self.renderbuffer);
        zgl.Texture.delete(self.texture);
    }

    pub fn resize(self: *Frame, width: usize, height: usize) !void {
        self.width = width;
        self.height = height;

        zgl.Texture.bind(self.texture, .@"2d");
        zgl.textureImage2D(.@"2d", 0, .rgba, width, height, .rgba, .float, null);
        zgl.Texture.parameter(self.texture, .min_filter, .linear);
        zgl.Texture.parameter(self.texture, .mag_filter, .linear);
        zgl.Texture.parameter(self.texture, .wrap_s, .clamp_to_edge);
        zgl.Texture.parameter(self.texture, .wrap_t, .clamp_to_edge);
        zgl.Framebuffer.texture2D(
            self.framebuffer,
            .buffer,
            .color0,
            .@"2d",
            self.texture,
            0,
        );

        zgl.Renderbuffer.storage(
            self.renderbuffer,
            .buffer,
            .depth24_stencil8,
            width,
            height,
        );
        zgl.Framebuffer.renderbuffer(
            self.framebuffer,
            .buffer,
            .depth_stencil,
            .buffer,
            self.renderbuffer,
        );
        zgl.Renderbuffer.bind(.invalid, .buffer);

        if (zgl.Framebuffer.checkStatus(.buffer) != .complete) {
            return error.IncompleteFramebuffer;
        }
        zgl.Framebuffer.bind(.invalid, .buffer);
    }
    pub fn bind(frame: ?Frame) void {
        if (frame) |self| {
            zgl.Framebuffer.bind(self.framebuffer, .buffer);
        } else {
            zgl.Framebuffer.bind(.invalid, .buffer);
        }
    }
    pub fn setViewport(frame: Frame) void {
        zgl.viewport(0, 0, @intCast(frame.width), @intCast(frame.height));
    }
};
