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
// - float u_delta_time

Particle init(uint idx)
{
    Particle particle;
    particle.position = vec4(0.0, 0.0, 0.0, 1.0);
    particle.color = vec4(1.0, .5, .0, 1.0);
    particle.size = 0.25;
    particle.angle = 0.0;
    particle.life = 1.0;

    return particle;
}

void update(inout Particle particle, inout Particle velocity, uint idx)
{
    velocity.position = vec4(0, 0, 0.01, 1);
}
