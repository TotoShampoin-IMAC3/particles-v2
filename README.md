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
- [x] Apply rotation transformation
- [x] GUI
  - [x] frame size and framerate
  - [x] particle count
  - [x] particle parameters
    - [x] Detect uniforms and make them editable
    - [ ] Give properties to uniforms
  - [x] Camera settings
    - [x] Projection type, and parameters
    - [x] Camera position and orientation (?)
  - [x] Change particle appearance
    - [x] Plain squares
    - [x] Circles
    - [x] Images
      - [x] Load image
- [ ] Image sequence saving
  - [x] Save one frame as png/jpg
  - [ ] Save as gif

## TODO: Images

- [x] Load image
- [x] Save image
- [ ] Save image sequence
- [ ] Call ffmpeg to convert image sequence to video

## TODO: Uniforms

- [ ] Design the syntax
- [ ] Parse the uniform syntax
- [ ] Code IMGUI for the matching syntax
