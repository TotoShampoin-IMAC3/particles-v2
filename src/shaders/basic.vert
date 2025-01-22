#version 330 core

layout(location = 0) in vec3 position;
layout(location = 1) in vec2 texcoord;
layout(location = 2) in vec3 instance_position;

out vec2 v_texcoord;

void main()
{
    v_texcoord = texcoord;
    gl_Position = vec4(position + instance_position, 1.0);
}
