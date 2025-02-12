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

## Uniform syntax

```glsl
uniform type name; //@ui property arg1 arg2, property, property arg1 arg2 arg3, ...
```

### Properties

- default
  - the default value
  - as many args as the type requires
- slider
  - use slider instead of input
  - min value then max value
- color
  - use color picker
- angle
  - use angle picker

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
    - [x] Give properties to uniforms
  - [x] Camera settings
    - [x] Projection type, and parameters
    - [x] Camera position and orientation (?)
  - [x] Change particle appearance
    - [x] Plain squares
    - [x] Circles
    - [x] Images
      - [x] Load image
- [x] Image sequence saving
  - [x] Save one frame as png
  - [ ] Save as gif

## TODO: Images

- [x] Load image
- [x] Save image
- [x] Save image sequence
- [ ] Call ffmpeg to convert image sequence to video

## TODO: Uniforms

- [x] Design the syntax
- [x] Parse the uniform syntax
- [x] Code IMGUI for the matching syntax
