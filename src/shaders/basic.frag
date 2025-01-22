#version 330 core

in vec2 v_texcoord;

out vec4 FragColor;

void main()
{
    FragColor = vec4(v_texcoord, 0.0, 1.0);
}
