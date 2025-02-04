#version 330 core

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec2 a_texcoord;

layout(location = 2) in vec4 a_instance_position;
layout(location = 3) in vec4 a_instance_color;
layout(location = 4) in float a_instance_size;
layout(location = 5) in float a_instance_angle;
layout(location = 6) in float a_instance_life;

out vec2 v_texcoord;
out vec4 v_color;

uniform mat4 u_view;
uniform mat4 u_projection;

mat3 rotation(float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return mat3(vec3(c, -s, 0), vec3(s, c, 0), vec3(0, 0, 1));
}

void main()
{
    vec3 position = a_instance_position.xyz;
    vec3 right = rotation(a_instance_angle) * vec3(u_view[0][0], u_view[1][0], u_view[2][0]) * a_instance_size;
    vec3 up = rotation(a_instance_angle) * vec3(u_view[0][1], u_view[1][1], u_view[2][1]) * a_instance_size;

    v_texcoord = a_texcoord;
    v_color = a_instance_color;
    gl_Position = u_projection * u_view * vec4(position + a_position.x * right + a_position.y * up, 1.0);
}
