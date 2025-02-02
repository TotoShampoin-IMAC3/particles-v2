# Toto's Particles

OpenGL Particle system in Zig

## Particle Schema

- position: `vec4` (for alignment)
- color: `vec4`
- size: `float`
- angle: `float`
- lifetime: `float`
- (padding): `[1]float`

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
- [x] Settle on a particle schema
  - [x] Implement
- [x] Load particle shader at runtime
  - [x] Process shader files, to store everything in a single file
  - [x] Open file dialog to reload shader
- [ ] Apply rotation transformation
- [x] GUI
  - [x] frame size and framerate
  - [x] particle count
  - [x] particle parameters
    - [x] Detect uniforms and make them editable
  - [ ] Camera settings
    - [ ] Projection type, and parameters
    - [ ] Camera position and orientation (?)
  - [ ] Change particle appearance
    - [ ] Plain squares
    - [ ] Circles
    - [ ] Images
      - [ ] Load image
- [ ] Image sequence saving
  - [ ] Save as gif
