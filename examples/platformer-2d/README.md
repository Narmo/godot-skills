# Platformer 2D Example

A minimal side-scrolling platformer demonstrating Godot 4.x skill patterns.

## Skills Demonstrated

| Skill | Pattern | File |
|-------|---------|------|
| [project-setup](../../skills/godot-project-setup/SKILL.md) | Input map, named physics layers | `project.godot` |
| [gdscript-patterns](../../skills/godot-gdscript-patterns/SKILL.md) | Typed signals, `class_name`, `@export`, constants | All scripts |
| [physics](../../skills/godot-physics/SKILL.md) | CharacterBody2D gravity/jumping, StaticBody2D platforms, Area2D hitbox | `scripts/player.gd`, `scripts/enemy.gd` |
| [input](../../skills/godot-input/SKILL.md) | Jump buffering, coyote time, VirtualJoystick (4.7+) | `scripts/player.gd`, `scenes/main.tscn` |
| [animation](../../skills/godot-animation/SKILL.md) | Tween-based message fades | `scripts/hud.gd` |
| [ui](../../skills/godot-ui/SKILL.md) | CanvasLayer HUD, signal-driven labels | `scripts/hud.gd` |

## How to Run

1. Open this folder in Godot 4.7+
2. Press **F5** (Run) or click the play button
3. Move with **A/D** or the arrow keys; jump with **W**, **Up** or **Space**
4. Land on an enemy from above to defeat it (+100 points); touching it from the side costs a life
5. Avoid the red hazard on the ground; at Game Over press **Enter** to restart

## Project Structure

```
platformer-2d/
├── project.godot           # Input map and physics layer names
├── scenes/
│   └── main.tscn           # Level, player, enemies, hazard, camera, HUD
└── scripts/
    ├── player.gd           # Gravity, jump buffering, coyote time, stomp hitbox
    ├── enemy.gd            # Patrol AI that turns at bounds and walls
    ├── camera.gd           # Smooth follow camera with lerp()
    └── hud.gd              # Score/lives display with tween fades
```

## Key Patterns

### Jump Buffering + Coyote Time (input)
```gdscript
_coyote = COYOTE_TIME if is_on_floor() else maxf(_coyote - delta, 0.0)
if Input.is_action_just_pressed("jump"):
    _jump_buffer = JUMP_BUFFER_TIME
else:
    _jump_buffer = maxf(_jump_buffer - delta, 0.0)

if _jump_buffer > 0.0 and _coyote > 0.0:
    velocity.y = JUMP_VELOCITY
```

### Stomp Detection (physics)
```gdscript
if velocity.y > 0.0 and global_position.y < enemy.global_position.y:
    enemy.defeat()          # landing on top
    velocity.y = STOMP_BOUNCE
else:
    _die()                  # touching from the side or below
```

### Smooth Camera (physics-independent smoothing)
```gdscript
global_position = global_position.lerp(goal, 1.0 - exp(-smoothing_speed * delta))
```

## Notes

- No external assets — every visual is a ColorRect
- The HUD's VirtualJoystick (Godot 4.7+) presses `move_left`/`move_right` and `jump`, so the player script has no joystick code
- The HUD runs with `process_mode = Always`, so it still reads the restart key while the game is paused
