// struct Particle
// {
//     vec4 position;
//     vec4 color;
//     float size;
//     float angle;
//     float life;
// };

// available variables:
// - Particle particles[]
// - Particle particles_init[]
// - Particle particles_velocity[]
// - Particle particles_init_velocity[]
// - int u_particle_count
// - float u_delta_time
// - float u_time
// - float PI
// - float UINT_MAX_AS_FLOAT

// available functions:
// - uint hash(uint seed)
// - uvec4 hashToHash4(uint seed)
// - vec4 hashNormalized(uint seed)

uniform vec2 u_scale;          //@ui default 1 1, slider 0 10
uniform float u_depth;         //@ui default 1, slider 0 10
uniform float u_size;          //@ui default 0.05, slider 0 1
uniform float u_speed;         //@ui default 1, slider 0 10
uniform float u_fog;           //@ui default 0.5, slider 0 10
uniform float u_fog_thickness; //@ui default 0.1, slider 0 5

void init(inout Particle particle, inout Particle velocity, uint idx)
{
    vec3 pos = hashNormalized(idx).xyz * 2.0 - 1.0;
    pos.xy *= u_scale;
    pos.z *= u_depth;

    particle.position = vec4(pos, 1.0);
    particle.color = vec4(1.0, 1.0, 1.0, 1.0);
    particle.size = u_size;
    particle.angle = 0.0;
    particle.life = 1.0;

    velocity.position = vec4(0.0, 0.0, -u_speed, 0.0);
    velocity.color = vec4(0.0, 0.0, 0.0, 0.0);
    velocity.size = 0.0;
    velocity.angle = 0.0;
    velocity.life = 0.0;
}

void update(inout Particle particle, inout Particle velocity, uint idx)
{
    particle.size = u_size;
    velocity.position = vec4(0.0, 0.0, -u_speed, 0.0);
    if (particle.position.z < -u_depth)
    {
        particle.position.z = u_depth;
    }
    // particle.color.a = 1.0 - (particle.position.z / u_depth);
    float fog = smoothstep(u_fog - u_fog_thickness, u_fog + u_fog_thickness, particle.position.z);
    particle.color.a = 1.0 - fog;
}
