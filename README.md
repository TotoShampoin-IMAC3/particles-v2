# Toto's Particles

OpenGL Particle system in Zig

## Particle Schema

- position: `vec4` (for alignment)
- color: `vec4`
- size: `float`
- angle: `float`
- lifetime: `float`
- (padding): `[5]float`

Separate particle buffers, for extra flexibility

- initials
- particles
- velocities

## Particle System

All in compute shaders

- `init.glsl`
- `update.glsl`

## TODO

- [x] Render quads
- [x] Render as particles
- [ ] Settle on a particle schema
  - [ ] Implement
- [ ] Load particle shader at runtime
  - [ ] Process shader files, to store everything in a single file
- [ ] GUI
  - [ ] frame size and framerate
  - [ ] particle count
  - [ ] particle parameters
    - [ ] Detect uniforms and make them editable
  - [ ] initial particles
- [ ] Image sequence saving
  - [ ] Save as gif
