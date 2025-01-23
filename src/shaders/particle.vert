#version 330 core

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec2 a_texcoord;

layout(location = 2) in vec4 a_instance_position;
layout(location = 3) in vec4 a_instance_speed;
layout(location = 4) in float a_instance_size;

out vec2 v_texcoord;

uniform mat4 u_view;
uniform mat4 u_projection;

void main()
{
    vec3 position = a_instance_position.xyz;
    vec3 right = vec3(u_view[0][0], u_view[1][0], u_view[2][0]) * a_instance_size;
    vec3 up = vec3(u_view[0][1], u_view[1][1], u_view[2][1]) * a_instance_size;

    v_texcoord = a_texcoord;
    gl_Position = u_projection * u_view * vec4(position + a_position.x * right + a_position.y * up, 1.0);
}
