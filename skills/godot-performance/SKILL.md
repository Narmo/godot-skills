---
name: godot-performance
description: "Performance optimization for Godot 4.x: profiling workflow (built-in profiler, CPU/GPU usage), memory management with ResourceCache and instance pooling, instancing optimization with packed scenes and LOD, render passes, draw calls, mobile-specific optimizations, Perfetto tracing, and nearest-neighbor viewport scaling. Use when debugging performance, optimizing games, or targeting low-end hardware."
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
    - performance
    - profiling
    - optimization
    - memory
    - mobile
  created: 2026-06-20
---

# Performance Optimization for Godot 4.x

Systematic approach to profiling, optimizing, and debugging performance in Godot 4.x.

## Profiling Workflow

### Built-in Profilers

The editor's bottom **Debugger** panel has the tools; they work on a running debug build
(started from the editor, or a debug export with remote debugging):

- **Profiler** — time per script function, physics and process callbacks
- **Visual Profiler** — CPU and GPU time per rendering step
- **Monitors** — FPS, memory, object counts, draw calls over time
- **Network Profiler** — RPC and synchronizer traffic

Measure a specific section in code:

```gdscript
var start_usec := Time.get_ticks_usec()
# ... expensive operation ...
print("Operation took: ", Time.get_ticks_usec() - start_usec, " us")
```

### CPU/GPU Usage Monitoring

```gdscript
# Print FPS to stdout: Project Settings > debug/settings/stdout/print_fps
func get_performance_stats() -> Dictionary:
    return {
        "fps": Performance.get_monitor(Performance.TIME_FPS),
        "process_time": Performance.get_monitor(Performance.TIME_PROCESS),
        "physics_time": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS),
        "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
        "objects": Performance.get_monitor(Performance.OBJECT_COUNT),
        "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
        "static_memory": Performance.get_monitor(Performance.MEMORY_STATIC),
        "video_memory": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
    }
```

### Profiling Checklist

1. **Profile on the target device** — use a debug export with remote debugging; the profilers need a debug build
2. **Check every view** — Profiler for scripts, Visual Profiler for rendering, Monitors for memory and draw calls
3. **Record a representative gameplay segment** — 30-60 seconds of typical play
4. **Identify hotspots** — look for functions consuming >5% of frame time
5. **Measure before and after each change**, and confirm the final frame times in a release build

## Memory Management

### Resource Cache Pattern

`load()` already returns the cached copy while something holds a reference; a cache keeps
frequently used resources alive between uses.

```gdscript
class_name ResourceCache
extends RefCounted

static var _cache: Dictionary[String, Resource] = {}


static func get_resource(path: String) -> Resource:
    if not _cache.has(path):
        var res := load(path)
        if res == null:
            push_warning("Failed to load resource: " + path)
            return null
        _cache[path] = res
    return _cache[path]


static func get_scene(path: String) -> PackedScene:
    return get_resource(path) as PackedScene
```

```gdscript
# Usage
var bullet_scene := ResourceCache.get_scene("res://scenes/entities/bullet.tscn")
var bullet := bullet_scene.instantiate()
```

### Instance Pooling Pattern

Reuse nodes instead of creating and freeing them. GDScript has no generics, so the pool works
with a `PackedScene` and plain `Node`s:

```gdscript
class_name NodePool
extends Node

@export var scene: PackedScene
@export var pool_size: int = 20

var _free: Array[Node] = []


func _ready() -> void:
    for i in pool_size:
        var node := scene.instantiate()
        _deactivate(node)
        add_child(node)
        _free.append(node)


func acquire() -> Node:
    var node: Node = _free.pop_back() if not _free.is_empty() else scene.instantiate()
    if node.get_parent() == null:
        add_child(node)
    node.process_mode = Node.PROCESS_MODE_INHERIT
    node.show()
    return node


func release(node: Node) -> void:
    _deactivate(node)
    _free.append(node)


func _deactivate(node: Node) -> void:
    node.process_mode = Node.PROCESS_MODE_DISABLED
    node.hide()
```

## Instancing Optimization

### Packed Scene Best Practices

```gdscript
# preload() for always-needed scenes (loaded with the script)
const BulletScene := preload("res://scenes/entities/bullet.tscn")

var current_level: Node


func spawn_bullet() -> void:
    add_child(BulletScene.instantiate())


# load() for conditional scenes (runtime)
func load_level(level_name: String) -> void:
    var scene := load("res://levels/%s.tscn" % level_name) as PackedScene
    if scene:
        current_level = scene.instantiate()
        add_child(current_level)
```

For big levels, load in the background with `ResourceLoader.load_threaded_request()` and poll
`ResourceLoader.load_threaded_get_status()`.

### Level of Detail (LOD)

Godot 4 generates mesh LODs on import and picks them automatically (`mesh_lod_threshold` on the
viewport). For hand-made LOD models, use visibility ranges instead of a script:

```gdscript
# Each LOD node shows only inside its distance band
$HighDetail.visibility_range_end = 10.0
$MediumDetail.visibility_range_begin = 10.0
$MediumDetail.visibility_range_end = 30.0
$LowDetail.visibility_range_begin = 30.0
```

### Instanced Rendering

Use `MultiMeshInstance2D/3D` for many similar objects.

```gdscript
# Draw 1000 identical trees with a single draw call
var multi_mesh := MultiMesh.new()
multi_mesh.transform_format = MultiMesh.TRANSFORM_3D  # set before instance_count
multi_mesh.mesh = preload("res://models/tree_mesh.tres")
multi_mesh.instance_count = 1000

for i in multi_mesh.instance_count:
    var position := Vector3(randf_range(-100.0, 100.0), 0.0, randf_range(-100.0, 100.0))
    multi_mesh.set_instance_transform(i, Transform3D(Basis(), position))

$MultiMeshInstance3D.multimesh = multi_mesh
```

## Render Passes and Draw Calls

### Minimizing Draw Calls

```gdscript
# BAD: hundreds of individual sprites for static ground cover
for i in 100:
    var sprite := Sprite2D.new()
    sprite.texture = grass_texture
    add_child(sprite)

# GOOD: TileMapLayer (tiles are batched in rendering quadrants)
# or a MultiMeshInstance2D for many identical moving objects
```

### Renderer Choice

- **Forward+**: highest quality and many lights — desktop 3D games
- **Mobile**: fewer passes — mobile and low-end devices
- **Compatibility**: OpenGL-based — oldest hardware and the web
- **LightmapGI**: bake static lighting to avoid real-time GI and shadows

Set the renderer in Project Settings > Rendering > Renderer (`rendering/renderer/rendering_method`).

## Mobile-Specific Optimizations

### Texture Compression

- Enable the formats you ship: `rendering/textures/vram_compression/import_etc2_astc` (mobile) and `import_s3tc_bptc` (desktop)
- In the Import dock, set large textures to **Compress > Mode: VRAM Compressed**
- Use **Lossless** only for small UI textures and pixel art

### Mobile Rendering Tips

- Use the **Mobile** renderer instead of Forward+ for Android/iOS
- Limit lights per object; bake static lighting with LightmapGI
- Use smaller shadow atlases and fewer shadow-casting lights
- Disable post-processing effects you don't need
- Set `texture_filter` to `TEXTURE_FILTER_NEAREST` for pixel art

### CPU Optimization for Mobile

- Avoid `get_node()` / `$Path` lookups in `_process` — cache them with `@onready`
- Avoid calling `instantiate()` every frame — use object pooling
- Use `NavigationServer2D/3D` queries for pathfinding instead of scene-tree searches
- Batch physics queries instead of issuing many individual raycasts
- Use `PhysicsServer2D/3D` directly for bulk operations

## Godot 4.7 Performance Features

### Perfetto Tracing for Android (Godot 4.7)

Godot 4.7 makes Perfetto the default tracing tool for Android editor and template builds, so
engine work shows up in Android's own system traces next to CPU scheduling, GPU and memory data.
Record a trace with the Perfetto UI (<https://ui.perfetto.dev/>) or `adb shell perfetto` while
the game runs on the device, then open it in the Perfetto UI.

### Nearest-Neighbor Viewport Scaling (Godot 4.7)

Render 3D at a lower resolution and upscale without filtering, for crisp retro 3D:

```gdscript
func use_retro_3d_scaling() -> void:
    var viewport := get_viewport()
    viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_NEAREST  # new in 4.7
    viewport.scaling_3d_scale = 0.5  # render at half resolution
```

The same settings exist as `rendering/scaling_3d/mode` and `rendering/scaling_3d/scale`. For
2D pixel art, use stretch mode `viewport`, `display/window/stretch/scale_mode = "integer"` and
the Nearest default texture filter instead.

## Performance Checklist

### Before Release

- [ ] Profile a debug build on the target device, then confirm frame times in the release build
- [ ] Check FPS stays above 30 (60 ideal) on target hardware
- [ ] Verify memory usage stays within device limits
- [ ] Test on the lowest-spec target device
- [ ] Check for frame-time spikes (C# garbage collection, loading on the main thread)
- [ ] Verify VRAM texture compression is enabled
- [ ] Reduce draw calls with instancing
- [ ] Use lightmaps for static scenes
- [ ] Implement object pooling for frequently spawned entities

### Runtime Monitoring

```gdscript
# Add to debug HUD
class_name PerfHUD
extends CanvasLayer

@onready var fps_label: Label = $FPSLabel
@onready var mem_label: Label = $MemLabel


func _process(_delta: float) -> void:
    fps_label.text = "FPS: %d" % Performance.get_monitor(Performance.TIME_FPS)
    mem_label.text = "Mem: %.1f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
```
