# Minimal RPG Example

A minimal top-down RPG demonstrating core Godot 4.x skill patterns.

## Skills Demonstrated

| Skill | Pattern | File |
|-------|---------|------|
| [project-setup](../../skills/godot-project-setup/SKILL.md) | Input map, named physics layers | `project.godot` |
| [gdscript-patterns](../../skills/godot-gdscript-patterns/SKILL.md) | Typed signals, `class_name`, `@export`, `@onready`, groups | All scripts |
| [physics](../../skills/godot-physics/SKILL.md) | Top-down CharacterBody2D, collision layers/masks, Area2D triggers | `scripts/player.gd`, `scripts/collectible.gd`, `scripts/npc.gd` |
| [state-management](../../skills/godot-state-management/SKILL.md) | Enum state machines, pausing the SceneTree | `scripts/game_controller.gd`, `scripts/npc.gd` |
| [ui](../../skills/godot-ui/SKILL.md) | PanelContainer/VBoxContainer, signal-driven updates | `scripts/inventory_ui.gd` |
| [input](../../skills/godot-input/SKILL.md) | Input actions shared by keyboard and VirtualJoystick (4.7+) | `scenes/main.tscn` |

## How to Run

1. Open this folder in Godot 4.7+
2. Press **F5** (Run) or click the play button
3. Move with **WASD** or the arrow keys (or the on-screen joystick on touch devices)
4. Walk into the colored squares to pick them up; the HUD lists what you carry
5. Walk up to the green merchant to read his greeting; press **Esc** to pause

## Project Structure

```
minimal-rpg/
├── project.godot           # Input map and physics layer names
├── scenes/
│   └── main.tscn           # Player, collectibles, NPC, walls, HUD
└── scripts/
    ├── game_controller.gd  # Pause state machine (process_mode = Always)
    ├── player.gd           # Top-down CharacterBody2D movement
    ├── collectible.gd      # Area2D pickup items
    ├── npc.gd              # Patrolling NPC with a talk zone
    └── inventory_ui.gd     # Signal-driven inventory and dialogue display
```

## Key Patterns

### Typed Signals (gdscript-patterns)
```gdscript
signal item_collected(item_name: String, quantity: int)
signal dialogue_started(npc_name: String, text: String)
```

### Collision Layers (physics)
Layers are named in `project.godot` and set on each node in `main.tscn`:
- Player: layer 1, mask npc (2) + wall (4)
- Collectibles: layer 3, mask player (1)
- Merchant: layer 2, mask player (1) + wall (4); its TalkZone masks the player only
- Walls: layer 4

### Enum State Machine (state-management)
```gdscript
enum State { PLAYING, PAUSED }

func _set_state(new_state: State) -> void:
    state = new_state
    get_tree().paused = state == State.PAUSED
```

### Signal-Driven UI (ui)
```gdscript
var player := get_tree().get_first_node_in_group("player") as Player
if player:
    player.item_collected.connect(_on_item_collected)
```

## Notes

- No external assets — every visual is a ColorRect
- The HUD's VirtualJoystick (Godot 4.7+) presses the same `move_*` actions as the keyboard, so the player script has no joystick code; it appears only while touched
