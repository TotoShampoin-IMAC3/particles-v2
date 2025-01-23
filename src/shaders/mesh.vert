#version 330 core

layout(location = 0) in vec3 a_position;
layout(location = 1) in vec2 a_texcoord;

out vec2 v_texcoord;

uniform mat4 u_model;
uniform mat4 u_view;
uniform mat4 u_projection;

void main()
{
    mat4 model_view = u_view * u_model;
    mat4 model_view_projection = u_projection * model_view;

    v_texcoord = a_texcoord;
    gl_Position = model_view_projection * vec4(a_position, 1.0);
}
