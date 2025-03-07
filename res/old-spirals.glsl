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

// viewport: 540x540
// part: 0 <= .. <= 45

void apply(inout Particle particle, inout Particle velocity, uint idx)
{
    float a = u_time * 2 * 720.0 / 60.0;
    if (idx == 45)
    {
        particle.position = vec4(0.0, 0.0, 1.0, 1.0);
        particle.size = 512.0;
        particle.angle = a * PI / 180.0;
        return;
    }

    float r, b, start_b;
    if (idx >= 0 && idx <= 14)
    {
        r = 250;
        start_b = 0;
    }
    else if (idx >= 15 && idx <= 26)
    {
        r = 200;
        start_b = 15;
    }
    else if (idx >= 27 && idx <= 35)
    {
        r = 150;
        start_b = 27;
    }
    else if (idx >= 36 && idx <= 41)
    {
        r = 100;
        start_b = 36;
    }
    else if (idx >= 42 && idx <= 44)
    {
        r = 50;
        start_b = 42;
    }
    b = (idx - start_b) * int(360 / (r / 100) / 6);

    float ang = (b + r / 100.0 * a) * PI / 180.0;

    particle.angle = (a + r + b) * PI / 180.0;
    particle.size = 512.0 / ((r * 4.0 / 100.0) + 4.0);
    particle.position = vec4(cos(ang) * r, sin(ang) * r, 1.0 - idx / 50.0, 1.0);
}

void init(inout Particle particle, inout Particle velocity, uint idx)
{
    particle.position = vec4(vec3(0.0), 1.0);
    particle.color = vec4(1.0, 1.0, 1.0, 1.0);
    particle.size = 0.33333;
    particle.angle = 0.0;
    particle.life = 1.0;

    velocity.position = vec4(0.0, 0.0, 0.0, 0.0);
    velocity.color = vec4(0.0, 0.0, 0.0, 0.0);
    velocity.size = 0.0;
    velocity.angle = 0.0;
    velocity.life = 0.0;

    apply(particle, velocity, idx);
}

void update(inout Particle particle, inout Particle velocity, uint idx)
{
    apply(particle, velocity, idx);
}
