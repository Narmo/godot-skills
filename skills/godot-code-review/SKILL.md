---
name: godot-code-review
description: "Reviews Godot projects for common pitfalls, performance issues, memory leaks, and anti-patterns. Provides a performance checklist, code style guidelines, and memory management review. Use when reviewing Godot GDScript or C# code."
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
    - code-review
    - performance
    - anti-patterns
  created: 2026-06-20
---

# Godot Code Review

Systematic review patterns for Godot game development projects.

## Common Pitfalls & Anti-Patterns

### _process() Abuse

```gdscript
# BAD: Using _process for everything
func _process(delta):
    # Movement that could be in _physics_process
    position += velocity * delta
    # Animation updates
    update_animation()

# GOOD: Use the right callback
func _physics_process(delta):
    # Physics-related movement
    position += velocity * delta

func _process(delta):
    # Non-physics updates (UI, animations)
    update_animation()
```

### Hardcoded Paths

```gdscript
# BAD
var sprite = get_node("Character/Sprite2D")

# GOOD
@onready var sprite = $Sprite2D as Sprite2D
```

### Signal Leaks

```gdscript
# Connections to a node's own methods are removed automatically when the node is freed:
func _ready():
    EventBus.some_signal.connect(on_some_signal)

# Lambdas are not tied to the node the same way — keep a reference and disconnect them:
var _callback := func(): handle_event()

func _enter_tree():
    EventBus.some_signal.connect(_callback)

func _exit_tree():
    EventBus.some_signal.disconnect(_callback)

# One-off reactions don't need cleanup at all:
func wait_for_start():
    EventBus.game_started.connect(on_game_started, CONNECT_ONE_SHOT)
```

## Performance Review Checklist

### Callback Selection

| Use Case | Correct Callback | Why |
|----------|-----------------|-----|
| Physics movement | `_physics_process` | Fixed timestep, syncs with physics server |
| Non-physics updates | `_process` | Frame-rate dependent, for UI/rendering |
| One-time setup | `_ready` | Called once when node enters tree |
| Every time it enters the tree | `_enter_tree` | Before `_ready`, and again after each re-add |
| Cleanup | `_exit_tree` | Called when node is removed from tree |
| Gameplay input | `_unhandled_input` | Runs after the UI had a chance to consume the event |

### Memory Management

- [ ] Lambda connections to long-lived emitters (autoloads) are disconnected in `_exit_tree()`
- [ ] No circular references between nodes
- [ ] Large resources (textures, audio) unloaded when no longer needed
- [ ] Scene instances properly freed after use
- [ ] Autoload nodes don't hold unnecessary references

### Code Style Guidelines

#### GDScript Style

- Indent with tabs (the style guide default) and never mix tabs and spaces in one file
- Follow [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- Use `@export` for inspector-exposed variables
- Use `@onready` for node paths
- Type annotations on function parameters and return values
- Use `const` for compile-time constants

#### C# Style

- Use PascalCase for classes, methods and public members, `_camelCase` for private fields
- Use Godot's `[Export]` attributes for inspector properties
- Implement `_ExitTree()` for cleanup of event subscriptions
- Prefer structs for small value types to avoid GC pressure

### Memory Management Patterns

```gdscript
# Proper node lifecycle
func spawn_enemy():
    var enemy = enemy_scene.instantiate()
    add_child(enemy)
    # Enemy manages its own cleanup via queue_free() on death

func load_level(level_path: String):
    # Unload previous level
    if current_level:
        current_level.queue_free()
        current_level = null

    # Load new level
    var scene = load(level_path)
    current_level = scene.instantiate()
    add_child(current_level)
```

## Godot 4.7 Code Review Notes

- HDR output is opt-in (`display/window/hdr/request_hdr_output`) — check it is on only when you target HDR displays
- Emissive meshes faking light panels can become `AreaLight3D` nodes
- Verify **VirtualJoystick** is used instead of custom implementations on mobile
- Tween chains that wait on signals between steps can use `Tween.tween_await()`

## Quick Review Commands

```bash
# Find all _process calls that might be physics-related
grep -rn "_process" --include="*.gd" scripts/

# Find hardcoded get_node calls (should use @onready)
grep -rn "get_node(" --include="*.gd" scripts/

# Find potential signal leaks (connect without disconnect pattern)
grep -rn "\.connect(" --include="*.gd" scripts/

# Find queue_free usage to verify cleanup
grep -rn "queue_free" --include="*.gd" scripts/
```
