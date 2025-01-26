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

uniform vec3 u_gravity;

void init(inout Particle particle, inout Particle velocity, uint idx)
{
    particle.position = vec4(0.0, 0.0, 0.0, 1.0);
    particle.color = vec4(1.0, .5, .0, 1.0);
    particle.size = 0.25;
    particle.angle = 0.0;
    particle.life = 1.0;

    velocity.position = vec4(0.0, 0.0, 0.0, 0.0);
    velocity.color = vec4(0.0, 0.0, 0.0, 0.0);
    velocity.size = 0.0;
    velocity.angle = 0.0;
    velocity.life = 0.0;
}

void update(inout Particle particle, inout Particle velocity, uint idx)
{
    velocity.position.xyz += u_gravity * u_delta_time;
}
