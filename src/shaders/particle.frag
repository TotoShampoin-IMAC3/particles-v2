#version 330 core

in vec2 v_texcoord;

out vec4 f_color;

void main()
{
    float dist = length(v_texcoord - 0.5);

    float alpha = smoothstep(0.55, 0.45, dist);

    if (alpha < 0.5)
        discard;
    f_color = vec4(alpha);
}
