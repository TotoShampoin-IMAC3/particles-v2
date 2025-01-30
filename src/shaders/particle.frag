#version 330 core

in vec2 v_texcoord;
in vec4 v_color;

out vec4 f_color;

void main()
{
    float dist = length(v_texcoord - 0.5);

    float alpha = smoothstep(0.52, 0.48, dist);

    if (alpha < 0.5)
        discard;
    f_color = vec4(v_color.rgb, v_color.a * alpha);
}
