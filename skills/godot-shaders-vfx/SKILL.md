---
name: godot-shaders-vfx
description: "Visual effects patterns for Godot 4.x: Godot shading language basics, canvas_item/spatial/particles shaders, particle systems (GPUParticles2D/3D), shader materials, and post-processing. Use when implementing custom rendering effects, particles, or visual polish in Godot."
license: MIT
compatibility:
  - godot-4.0
  - godot-4.1
  - godot-4.2
  - godot-4.3
  - godot-4.4
  - godot-4.5
  - godot-4.6
  - godot-4.7
metadata:
  author: vl4dt
  version: 0.1.0
  tags:
    - godot
    - shaders
    - vfx
    - particles
    - post-processing
    - gsl
  created: 2026-06-21
---

# Shaders and Visual Effects in Godot

Patterns for custom rendering and particle effects.

## Shader Types

Godot shaders start with `shader_type`:

| Type | Used By | Use Case |
|------|---------|----------|
| `canvas_item` | Sprite2D, TileMapLayer, Control, ColorRect | 2D sprite effects, UI shaders, 2D screen effects |
| `spatial` | MeshInstance3D and other 3D geometry | 3D material effects, vertex displacement |
| `particles` | GPUParticles2D/3D process material | Custom particle behavior |
| `sky` | Sky resource of a WorldEnvironment | Procedural skies |
| `fog` | FogVolume | Volumetric fog shapes |

Vertex displacement is not a separate type: it's the `vertex()` function of a `canvas_item`
or `spatial` shader.

## Canvas Item Shader (2D)

Basic 2D shader structure:

```gdshader
// Pixelate effect for retro aesthetics
shader_type canvas_item;

uniform float pixel_size : hint_range(1.0, 32.0) = 4.0;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;

void fragment() {
    // Snap UV to a grid of pixel_size texels
    vec2 cell = TEXTURE_PIXEL_SIZE * pixel_size;
    vec2 uv = floor(UV / cell) * cell + cell * 0.5;
    vec4 color = texture(TEXTURE, uv);

    // Apply brightness
    color.rgb *= brightness;

    COLOR = color;
}
```

### Applying Shaders in Code

```gdscript
# Apply shader material to a sprite
var shader_mat := ShaderMaterial.new()
shader_mat.shader = preload("res://shaders/pixelate.gdshader")
$Sprite2D.material = shader_mat

# Set uniform at runtime
shader_mat.set_shader_parameter("pixel_size", 8.0)
shader_mat.set_shader_parameter("brightness", 1.5)
```

### Color Tint Shader

```gdshader
// Selective color tint — useful for damage flash, selection highlight
shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 original = texture(TEXTURE, UV);
    COLOR = vec4(mix(original.rgb, tint_color.rgb, tint_amount), original.a);
}
```

## Spatial Shader (3D)

Basic 3D shader with lighting:

```gdshader
// Animated water surface (apply to a subdivided PlaneMesh)
shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform float wave_speed : hint_range(0.1, 5.0) = 1.0;
uniform float wave_height : hint_range(0.01, 0.5) = 0.1;
uniform vec4 water_color : source_color = vec4(0.0, 0.5, 0.8, 0.7);

void vertex() {
    // Animate vertices with sine waves
    float wave = sin(VERTEX.x * 2.0 + TIME * wave_speed) * wave_height;
    wave += sin(VERTEX.z * 1.6 + TIME * wave_speed * 1.3) * wave_height * 0.5;
    VERTEX.y += wave;
}

void fragment() {
    // Fresnel-like effect — edges more reflective
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
    ALBEDO = mix(water_color.rgb, vec3(1.0), fresnel * 0.5);
    ALPHA = water_color.a;
    SPECULAR = 0.8;
    ROUGHNESS = 0.2;
}
```

## Particle Systems

### GPUParticles2D

```gdscript
# Code-driven particle setup
var particles := GPUParticles2D.new()
particles.one_shot = true
particles.lifetime = 1.5
particles.amount = 50
particles.emitting = false

# Behavior: ParticleProcessMaterial
var process := ParticleProcessMaterial.new()
process.direction = Vector3(0, -1, 0)
process.spread = 180.0                      # 180 = all directions
process.initial_velocity_min = 50.0
process.initial_velocity_max = 150.0
process.gravity = Vector3(0, 200, 0)        # +Y is down in 2D
process.color = Color(1.0, 0.5, 0.0)
particles.process_material = process

# Look: the texture each particle draws
particles.texture = preload("res://assets/particle.png")

add_child(particles)
```

Fade particles out with a `color_ramp` (a `GradientTexture1D`) on the process material.

### Triggering Particles

```gdscript
func emit_explosion(at: Vector2) -> void:
    var particles := load("res://vfx/explosion.tscn").instantiate() as GPUParticles2D
    get_parent().add_child(particles)
    particles.global_position = at
    particles.one_shot = true
    particles.restart()  # starts emitting

    # Auto-destroy after particles finish (GPUParticles2D.finished, Godot 4.1+)
    particles.finished.connect(particles.queue_free)
```

### GPUParticles3D

```gdscript
# 3D particle burst (fire, smoke, magic)
var particles_3d := GPUParticles3D.new()
particles_3d.one_shot = true
particles_3d.lifetime = 2.0
particles_3d.amount = 100

var process := ParticleProcessMaterial.new()
process.direction = Vector3.UP   # emission direction lives on the process material
process.spread = 25.0            # cone half-angle in degrees
particles_3d.process_material = process
particles_3d.draw_pass_1 = QuadMesh.new()  # what each particle looks like

add_child(particles_3d)
```

## Post-Processing

Apply screen-space effects through the `Environment` of a `WorldEnvironment` node:

```gdscript
var env: Environment = $WorldEnvironment.environment

# Glow/bloom
env.glow_enabled = true
env.glow_intensity = 0.8
env.glow_bloom = 0.1
env.glow_hdr_threshold = 1.0

# Tone mapping
env.tonemap_mode = Environment.TONE_MAPPER_ACES

# Fog
env.fog_enabled = true
env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
env.fog_light_color = Color(0.6, 0.7, 0.8)
env.fog_density = 0.02

# SSAO (3D ambient occlusion, Forward+ only)
env.ssao_enabled = true
env.ssao_radius = 1.0
```

### Screen Shader

For custom full-screen post-processing, put a full-rect `ColorRect` in a `CanvasLayer` above
the game and give it a `canvas_item` shader that reads the screen:

```gdshader
// Vignette + chromatic aberration post-process
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_amount : hint_range(0.0, 1.0) = 0.5;
uniform float chroma_amount : hint_range(0.0, 0.01) = 0.003;

void fragment() {
    // Chromatic aberration — shift RGB channels radially
    vec2 center = SCREEN_UV - 0.5;
    float dist = length(center);
    vec2 dir = normalize(center + 1e-5) * chroma_amount * dist;

    float r = texture(screen_texture, SCREEN_UV + dir).r;
    float g = texture(screen_texture, SCREEN_UV).g;
    float b = texture(screen_texture, SCREEN_UV - dir).b;

    // Vignette
    float vignette = 1.0 - clamp(dist * vignette_amount * 2.0, 0.0, 1.0);

    COLOR = vec4(vec3(r, g, b) * vignette, 1.0);
}
```

## Shader Performance Tips

### Minimize Fragment Operations

```gdshader
shader_type canvas_item;

// Bad — work that is the same for every pixel, done per pixel
// COLOR.rgb = pow(texture(TEXTURE, UV).rgb, vec3(3.0)) * sin(TIME * 10.0);

// Good — compute shared values once (in a uniform or the vertex stage)
uniform float precomputed_value;

void fragment() {
    COLOR.rgb = texture(TEXTURE, UV).rgb * precomputed_value;
}
```

### Use Hints for Uniforms

Hints give uniforms editor widgets, ranges and sensible defaults:

```gdshader
shader_type canvas_item;

uniform float speed : hint_range(0.1, 10.0) = 1.0;
uniform vec4 color : source_color = vec4(1.0);
uniform sampler2D tex : hint_default_black;  // black texture when none is assigned
```

### Shader Material Reuse

```gdscript
# Share one ShaderMaterial across multiple nodes for performance
var shared_material := ShaderMaterial.new()
shared_material.shader = preload("res://shaders/wave.gdshader")

$Sprite2D_A.material = shared_material
$Sprite2D_B.material = shared_material  # Same material instance
```

Per-node values on a shared material: declare them `instance uniform` and set them with
`set_instance_shader_parameter()` (available on 3D geometry and on CanvasItem nodes in 4.7).
