#version 330 core

const int APPEARANCE_SQUARE = 0;
const int APPEARANCE_CIRCLE = 1;
const int APPEARANCE_TEXTURE = 2;

in vec2 v_texcoord;
in vec4 v_color;

out vec4 f_color;

uniform int u_appearance;
uniform sampler2D u_texture;
uniform float u_threshold;

void main()
{
    float dist = length(v_texcoord - 0.5);

    if (u_appearance == APPEARANCE_CIRCLE)
    {
        float alpha = dist;
        if (alpha >= u_threshold)
            discard;
        f_color = v_color;
    }
    else if (u_appearance == APPEARANCE_SQUARE)
    {
        f_color = v_color;
    }
    else if (u_appearance == APPEARANCE_TEXTURE)
    {
        f_color = texture(u_texture, v_texcoord) * v_color;
        if (f_color.a < u_threshold)
            discard;
    }
    else
    {
        bool below_x = v_texcoord.x < 0.5;
        bool below_y = v_texcoord.y < 0.5;
        f_color.rgb = mix(vec3(0.0), vec3(1.0, 0.0, 1.0), float(below_x != below_y));
        f_color.a = 1.0;
    }
}
