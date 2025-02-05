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

uniform float spread;
uniform float depth;
uniform float radius;
uniform float speed;

void apply(inout Particle particle, inout Particle velocity, uint idx)
{
    int idx2 = u_particle_count - int(idx) - 1;
    particle.position.xy = vec2(                             //
        cos(speed * u_time + float(idx2) * spread) * radius, //
        sin(speed * u_time + float(idx2) * spread) * radius  //
    );
    particle.position.z = float(idx2) * depth;
    particle.angle = speed * u_time + float(idx2) * spread;
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
