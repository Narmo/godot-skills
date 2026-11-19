---
name: godot-brainstorming
description: "Architecture decision patterns for Godot game development across genres (RPG, platformer, RTS, puzzle). Covers scene organization, state machines, network architecture, and component composition. Use when designing a Godot game's architecture or making Godot-specific technical decisions."
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
    - architecture
    - state-machines
    - multiplayer
  created: 2026-06-20
---

# Godot Brainstorming & Architecture

Help design game architecture using Godot's node-based composition model.

## Scene Organization Strategies

### Composition Over Inheritance

Godot's strength is scene composition. Prefer composing small, focused scenes over deep inheritance hierarchies.

```gdscript
# Instead of: PlayerCharacter extends CharacterBody2D with all abilities
# Use: Compose a player from reusable components
# - BaseCharacter (CharacterBody2D) — movement, health
# - InventoryComponent (Node) — inventory logic
# - AbilitySystem (Node) — ability management
```

### Scene Hierarchy Patterns

| Pattern | When to Use | Example |
|---------|-------------|---------|
| Single root scene | Entire game/level | Main.tscn, Level1.tscn |
| Component scenes | Reusable behaviors | HealthBar.tscn, ProgressBar.tscn |
| Entity templates | Instantiable objects | Enemy.tscn, Collectible.tscn |
| UI compositions | Complex screens | MainMenu.tscn, SettingsPanel.tscn |

## State Machine Patterns

### AnimationTree State Machine

```gdscript
@export var animation_tree: AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = \
    animation_tree.get("parameters/playback")

func change_state(new_state: String):
    state_machine.travel(new_state)
```

### Custom State Machine

For complex AI or game logic:

```gdscript
class_name GameState extends RefCounted

var current_state: String = "menu"

func transition_to(new_state: String):
    var prev = current_state
    current_state = new_state
    on_transition(prev, new_state)

func on_transition(from: String, to: String):
    match to:
        "playing": handle_playing()
        "paused": handle_paused()
```

## Network Architecture Decisions

### Authoritative Server Model
- Best for competitive multiplayer
- Server validates all actions
- Client sends inputs, server simulates

### Peer-to-Peer Model
- Best for casual/co-op games
- Lower latency for local interactions
- Higher cheating risk

### Steam
Steam lobbies and Steam networking come from the third-party GodotSteam add-on; Godot itself
has no Steam API. (Steam Frame, new in Godot 4.7's feature list, is Valve's XR headset.)

## Genre-Specific Patterns

### RPG Architecture
- Entity-component system for character stats
- Dialogue tree system (use `RichTextLabel` + custom parser)
- Save/load system using `JSON` or `Resource` serialization

### Platformer Architecture
- Level streaming for large worlds
- Input buffering for responsive controls
- TileMapLayer for layered level design

### RTS Architecture
- Pathfinding with NavigationRegion3D/NavigationAgent3D (navmesh), or AStarGrid2D for grid maps
- Unit grouping and selection system
- Command queue pattern for input handling

## Godot 4.7 Brainstorming Considerations

- **`Tween.tween_await()`** — pause a tween until a signal fires; handy for dialogue and cutscene sequencing
- **VirtualJoystick** — built-in touch controls that press regular input actions
- **Control offset transforms** — animate UI elements inside containers without fighting the layout
- **Android XR and Steam Frame** — production-ready XR targets if you plan a VR/MR version
