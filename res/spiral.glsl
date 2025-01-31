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
// - float u_time

// available functions:
// - uint hash(uint seed)
// - uvec4 hashToHash4(uint seed)
// - vec4 hashNormalized(uint seed)

uniform float spread;
uniform float depth;
uniform float radius;
uniform float speed;

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
}

void update(inout Particle particle, inout Particle velocity, uint idx)
{
    particle.position.xy = vec2(                            //
        cos(speed * u_time + float(idx) * spread) * radius, //
        sin(speed * u_time + float(idx) * spread) * radius  //
    );
    particle.position.z = float(idx) * depth;
}
