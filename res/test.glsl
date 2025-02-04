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
// - float u_delta_time
// - float PI
// - float UINT_MAX_AS_FLOAT

// available functions:
// - uint hash(uint seed)
// - uvec4 hashToHash4(uint seed)
// - vec4 hashNormalized(uint seed)

uniform uint seed;
uniform vec3 u_gravity;
uniform vec4 u_color;
uniform float u_angle;

void init(inout Particle particle, inout Particle velocity, uint idx)
{
    particle.position = vec4(hashNormalized(hash(seed) + idx).xyz * 2 - 1, 1.0);
    particle.color = u_color;
    particle.size = 0.25;
    particle.angle = u_angle;
    particle.life = 1.0;

    velocity.position = vec4(0.0, 0.0, 0.0, 0.0);
    velocity.color = vec4(0.0, 0.0, 0.0, 0.0);
    velocity.size = 0.0;
    velocity.angle = 0.0;
    velocity.life = 0.0;
}

void update(inout Particle particle, inout Particle velocity, uint idx)
{
    particle.color = u_color;
    particle.angle = u_angle * PI / 180.0;
    velocity.position.xyz += u_gravity * u_delta_time;

    if (particle.position.x > 1)
        particle.position.x -= 2;
    if (particle.position.y > 1)
        particle.position.y -= 2;
    if (particle.position.z > 1)
        particle.position.z -= 2;
    if (particle.position.x < -1)
        particle.position.x += 2;
    if (particle.position.y < -1)
        particle.position.y += 2;
    if (particle.position.z < -1)
        particle.position.z += 2;
}
