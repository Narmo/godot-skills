---
name: godot-animation
description: "Animation systems for Godot 4.x: AnimationPlayer vs AnimationTree, state machines, blend spaces (1D/2D/directional), animation libraries, root motion, collapsible tracks, and tween_await(). Use when building character animations, cutscenes, or visual effects in Godot."
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
    - animation
    - animationplayer
    - animationtree
    - blend-space
    - root-motion
  created: 2026-06-20
---

# Animation Systems for Godot 4.x

Comprehensive patterns for character animation, state machines, and visual effects in Godot 4.x.

## AnimationPlayer vs AnimationTree

### AnimationPlayer — Simple Animations

Use AnimationPlayer for linear sequences, cutscenes, and simple property animations.

```gdscript
@onready var anim_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
    # Signal-based animation completion
    anim_player.animation_finished.connect(_on_animation_finished)


func play_attack() -> void:
    anim_player.play("attack")


func play_transition(target: StringName, fade_time: float = 0.2) -> void:
    anim_player.play(target, fade_time)  # second argument is the crossfade time


func _on_animation_finished(anim_name: StringName) -> void:
    if anim_name == &"attack":
        print("Attack animation complete")
```

### AnimationTree — State Machine Animations

Use AnimationTree for complex character animations with branching states (idle, walk, run,
jump). It updates itself every frame; you only set parameters and request states.

```gdscript
@onready var anim_tree: AnimationTree = $AnimationTree
# The playback object of the root AnimationNodeStateMachine
@onready var playback: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/playback")


func _ready() -> void:
    playback.start("Idle")


func set_animation(state_name: StringName) -> void:
    var state_machine := anim_tree.tree_root as AnimationNodeStateMachine
    if state_machine and state_machine.has_node(state_name):
        playback.travel(state_name)  # follows the transitions to get there
```

### When to Use Which

| Use Case | Tool |
|----------|------|
| Cutscenes, UI animations | AnimationPlayer |
| Character movement states | AnimationTree + StateMachine |
| Simple one-shot effects | AnimationPlayer |
| Blending between movements | AnimationTree + BlendSpace1D/2D |
| Complex combat combos | AnimationTree + AnimationNodeBlendTree |

## State Machines in AnimationTree

### Building a Character State Machine

```gdscript
# In the AnimationTree, create an AnimationNodeStateMachine:
# States: Idle, Walk, Run, Jump, Fall, Attack
# Transitions: Idle <-> Walk, Idle <-> Run, Walk -> Run, etc.
extends CharacterBody2D

@export var run_threshold: float = 150.0

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = anim_tree.get("parameters/playback")


func _physics_process(_delta: float) -> void:
    var speed := velocity.length()
    var new_state := &"Idle"

    if not is_on_floor():
        new_state = &"Jump" if velocity.y < 0.0 else &"Fall"  # -Y is up in 2D
    elif speed > 0.1:
        new_state = &"Run" if speed > run_threshold else &"Walk"

    if playback.get_current_node() != new_state:
        playback.travel(new_state)
```

### Transition Conditions

Set transition conditions in the AnimationTree editor:
- **Advance condition**: a named boolean (`parameters/conditions/<name>`) that allows the transition
- **Advance expression**: a GDScript expression evaluated on the tree's `advance_expression_base_node`
- **Switch mode**: immediate, sync, or at the end of the current animation

```gdscript
anim_tree.set("parameters/conditions/is_attacking", true)
```

## Blend Spaces

### 1D Blend Space

Use for animations ordered along a single axis (e.g., walk speed).

```gdscript
# AnimationTree setup: BlendSpace1D node named "Locomotion" with Walk -> Run -> Sprint
anim_tree.set("parameters/Locomotion/blend_position", current_speed)
```

### 2D Blend Space

Use for directional movement blending (8-directional characters, strafing).

```gdscript
# AnimationTree setup: BlendSpace2D node named "Move", animations placed at
# (0, -1) up, (1, 0) right, (0, 1) down, (-1, 0) left, and the diagonals
func _physics_process(_delta: float) -> void:
    if velocity.length() > 0.1:
        anim_tree.set("parameters/Move/blend_position", velocity.normalized())
```

## Animation Libraries and Blending Tracks

### Animation Libraries

Group related animations into libraries for organization. Animations in a named library are
played as `"library_name/animation_name"`; the default library has an empty name.

```gdscript
@onready var anim_player: AnimationPlayer = $AnimationPlayer


func play_animation(anim_name: StringName) -> void:
    anim_player.play(anim_name)  # e.g. "combat/slash"


# List available animations (with library prefixes)
func get_available_animations() -> PackedStringArray:
    return anim_player.get_animation_list()
```

### Blending

```gdscript
# AnimationPlayer plays one animation at a time; crossfade with custom_blend
anim_player.play("idle", 1.0)        # 1 s crossfade from the current animation
anim_player.play("walk", 0.5, 1.5)   # 0.5 s crossfade, 1.5x speed

# Mixing animations at the same time is the AnimationTree's job, e.g. a Blend2 node:
anim_tree.set("parameters/UpperBody/blend_amount", 1.0)
```

## Root Motion for Character Movement

### Using Root Motion in AnimationTree

Root motion moves the character by the root bone's animated offset instead of by script.
Set **AnimationTree > Root Motion > Track** to the root bone first.

```gdscript
class_name RootMotionCharacter
extends CharacterBody3D

@export var root_motion_enabled: bool = true
@export var speed: float = 4.0

@onready var anim_tree: AnimationTree = $AnimationTree


func _physics_process(delta: float) -> void:
    if root_motion_enabled:
        # This frame's root offset, in the model's local space
        var motion := anim_tree.get_root_motion_position()
        velocity = (global_basis * motion) / delta
    else:
        # Use scripted movement instead
        velocity = -global_basis.z * speed

    if not is_on_floor():
        velocity += get_gravity() * delta
    move_and_slide()
```

### When to Use Root Motion
- Attack animations with fixed reach distances
- Climbing, vaulting and other moves that must match the animation exactly
- Cutscene character movements

### When to Avoid Root Motion
- Multiplayer games (server authority conflicts)
- Characters that need precise, responsive position control (platformers)
- Games with custom physics responses

## Godot 4.7 Animation Features

### Collapsible Animation Editor Nodes

Godot 4.7 lets you collapse the tracks of a node in the Animation panel; a collapsed node shows
an aggregate row of its keys. No code change needed — it is an editor feature.

### Tween.tween_await() for Sequential Animations

`Tween.tween_await(signal)` pauses a tween until the signal is emitted, so one tween can wait
for an AnimationPlayer, a dialogue box, or any other event:

```gdscript
func play_combo() -> void:
    var tween := create_tween()
    tween.tween_property($Sprite, "offset:x", 10.0, 0.1)
    tween.tween_callback(anim_player.play.bind("attack"))
    tween.tween_await(anim_player.animation_finished)  # wait for the attack to end
    tween.tween_property($Sprite, "offset:x", 0.0, 0.1)
    await tween.finished
    print("Combo animation complete")
```

## Animation Performance Tips

- Use **AnimationTree** with state machines instead of multiple AnimationPlayers
- Keep animation libraries small and focused
- Enable **sync** on blend nodes so blended animations stay in step
- Use the `animation_finished` signal instead of polling for completion
- Pause off-screen characters' trees with `anim_tree.active = false`

## Quick Reference: Animation Methods

| Method | Use Case |
|--------|----------|
| `anim_player.play(name)` | Start an animation |
| `anim_player.play(name, blend_time)` | Crossfade to animation |
| `anim_tree.set("parameters/...", value)` | Set blend positions and conditions |
| `playback.travel(name)` | Switch to a state through transitions |
| `create_tween()` | Create animation tweens |
| `tween.tween_await(signal)` | Pause a tween until a signal fires (4.7) |
| `await tween.finished` | Wait for tween completion |
