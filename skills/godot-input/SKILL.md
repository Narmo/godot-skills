---
name: godot-input
description: "Input handling patterns for Godot 4.x: Input map configuration, action polling vs events, gamepad/virtual joystick support, input remapping UI, dead zones, and touch/multi-touch. Use when implementing player controls, controller support, or input customization in Godot."
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
    - input
    - controls
    - gamepad
    - touch
    - remapping
  created: 2026-06-21
---

# Input Handling in Godot

Patterns for robust, accessible input systems.

## Input Map Configuration

Define actions in **Project Settings → Input Map** or via code:

```gdscript
# Register actions at runtime (or use editor)
InputMap.add_action("move_left")

var left_event = InputEventKey.new()
left_event.keycode = KEY_A
InputMap.action_add_event("move_left", left_event)

# Add gamepad button
var dpad_event = InputEventJoypadButton.new()
dpad_event.button_index = JOY_BUTTON_DPAD_LEFT
dpad_event.pressed = true
InputMap.action_add_event("move_left", dpad_event)
```

### Recommended Action Naming

```
move_left, move_right, move_up, move_down
jump, crouch, interact, attack
inventory, pause, menu_confirm, menu_cancel
```

## Polling vs Events

Two approaches to reading input:

### Polling (Continuous — `_physics_process`)

For movement and analog input:

```gdscript
class_name PlayerController extends CharacterBody2D

@export var speed: float = 200.0

func _physics_process(delta: float) -> void:
    # get_vector() combines keyboard + gamepad, applies the actions' dead zones,
    # and limits the length to 1 (diagonals aren't faster)
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * speed

    move_and_slide()
```

### Events (Discrete — `_unhandled_input`)

For camera rotation, menu navigation, one-shot actions:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        interact_with_target()
    elif event.is_action_pressed("pause"):
        toggle_pause()

# Use _unhandled_input so UI can consume input first
# Use _input if this node should always receive input
```

### When to Use Each

| Approach | Use For | Method |
|----------|---------|--------|
| Polling | Movement, analog sticks, continuous actions | `_physics_process` / `_process` |
| Events | Camera rotation, one-shot actions, menu nav | `_unhandled_input` |
| Both | Games with movement + discrete actions | Combined |

## Gamepad Support

### Detecting Connected Controllers

```gdscript
func _ready() -> void:
    var connected = Input.get_connected_joypads()
    if connected.size() > 0:
        print("Gamepad connected: ", connected[0])
        # Enable rumble, vibrate, etc.
```

### Rumble / Haptic Feedback

```gdscript
# Simple rumble on action
func play_rumble(strength: float = 0.5, duration: float = 0.1) -> void:
    Input.start_joy_vibration(0, strength, strength, duration)

# Dual-motor (separate weak/strong rumble)
Input.start_joy_vibration(0, 0.3, 0.8, 0.2)  # weak, strong, duration
```

### Dead Zone Configuration

Prevent drift from analog sticks. Each action has its own dead zone (Project Settings > Input
Map, the value next to the action), also settable in code:

```gdscript
InputMap.action_set_deadzone("move_left", 0.2)

# get_vector() and get_axis() accept a dead zone override:
var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down", 0.15)
```

## Input Remapping UI

Let players customize controls:

```gdscript
class_name InputRemapButton extends Button

var current_action: String = ""
var waiting_for_input: bool = false

func _ready():
    pressed.connect(_on_button_pressed)

func set_action(action: String) -> void:
    current_action = action
    update_display()

func _on_button_pressed() -> void:
    if waiting_for_input:
        return
    waiting_for_input = true
    text = "Press a key..."
    # Grab focus so input events come here
    grab_focus()

func _input(event: InputEvent) -> void:
    if not waiting_for_input:
        return

    if (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed():
        # Clear old bindings for this action
        InputMap.action_erase_events(current_action)

        # Add new binding
        InputMap.action_add_event(current_action, event.duplicate())
        waiting_for_input = false
        update_display()
        get_viewport().set_input_as_handled()  # Prevent game from receiving it

func update_display() -> void:
    if not waiting_for_input:
        var events = InputMap.action_get_events(current_action)
        if events.size() > 0:
            text = _event_to_string(events[0])
        else:
            text = "Not assigned"

func _event_to_string(event: InputEvent) -> String:
    if event is InputEventKey:
        return OS.get_keycode_string(event.keycode)
    elif event is InputEventJoypadButton:
        return "Gamepad Button %d" % event.button_index
    return "Unknown"
```

### Saving Remapped Controls

```gdscript
class_name InputSettings extends Node

const SETTINGS_PATH := "user://input_settings.cfg"

func save_bindings() -> void:
    var config = ConfigFile.new()
    var actions = InputMap.get_actions()

    for action in actions:
        var events = InputMap.action_get_events(action)
        var event_strings = []
        for event in events:
            event_strings.append(_event_to_string(event))
        config.set_value("input", action, ",".join(event_strings))

    config.save(SETTINGS_PATH)

func load_bindings() -> Error:
    var config = ConfigFile.new()
    if config.load(SETTINGS_PATH) != OK:
        return Error.ERR_FILE_NOT_FOUND

    var actions = InputMap.get_actions()
    for action in actions:
        var event_strings = config.get_value("input", action, "") as String
        if event_strings.is_empty():
            continue

        # Clear and re-add
        InputMap.action_erase_events(action)
        for entry in event_strings.split(","):
            var event := _string_to_event(entry)
            if event:
                InputMap.action_add_event(action, event)

    return Error.OK

func _event_to_string(event: InputEvent) -> String:
    if event is InputEventKey:
        return "key:%d" % event.keycode
    elif event is InputEventJoypadButton:
        return "joypad:%d" % event.button_index
    return ""

func _string_to_event(entry: String) -> InputEvent:
    var parts := entry.split(":")
    if parts[0] == "key":
        var event = InputEventKey.new()
        event.keycode = int(parts[1])
        return event
    elif parts[0] == "joypad":
        var event = InputEventJoypadButton.new()
        event.button_index = int(parts[1])
        event.pressed = true
        return event
    return null
```

## Touch and Multi-Touch

### Virtual Joystick (Godot 4.7+)

Godot 4.7 adds a `VirtualJoystick` control. It doesn't expose a vector of its own: it presses
the input actions named in `action_left`, `action_right`, `action_up` and `action_down`
(`ui_*` by default), so the same movement code serves keyboard, gamepad and touch.

```gdscript
# In the scene: VirtualJoystick with action_left = "move_left", action_right = "move_right",
# action_up = "move_up", action_down = "move_down".
# joystick_mode: Fixed, Dynamic or Following; visibility_mode: Always or When Touched.

func _physics_process(_delta: float) -> void:
    velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * speed
    move_and_slide()
```

### Multi-Touch Gestures

```gdscript
class_name TouchHandler extends Node2D

var _touch_points: Dictionary = {}  # index -> Vector2

func _input(event: InputEvent) -> void:
    if event is InputEventScreenDrag:
        _handle_drag(event)
    elif event is InputEventScreenTouch:
        if event.pressed:
            _touch_points[event.index] = event.position
        else:
            _touch_points.erase(event.index)
        _update_pinch()

func _handle_drag(event: InputEventScreenDrag) -> void:
    if _touch_points.has(event.index):
        var delta = event.position - _touch_points[event.index]
        _touch_points[event.index] = event.position
        _update_pinch()
        # Use delta for movement, camera pan, etc.

# Pinch-to-zoom with two fingers
signal pinched(scale_factor: float)

var _last_pinch_distance := 0.0


func _update_pinch() -> void:
    # Call after updating _touch_points in _input()
    if _touch_points.size() < 2:
        _last_pinch_distance = 0.0
        return
    var points := _touch_points.values()
    var distance: float = points[0].distance_to(points[1])
    if _last_pinch_distance > 0.0:
        pinched.emit(distance / _last_pinch_distance)  # >1 spreads, <1 pinches
    _last_pinch_distance = distance
```

## Accessibility Patterns

### Hold vs Toggle Actions

```gdscript
# Support both hold and toggle for accessibility
@export var use_toggle_jump: bool = false
var jump_toggled: bool = false

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        if use_toggle_jump:
            jump_toggled = !jump_toggled
        # Movement code checks either:
        # Input.is_action_pressed("jump") OR jump_toggled
```

### Sensitivity Slider

```gdscript
# For camera or aim sensitivity
@export var sensitivity: float = 1.0

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        camera.rotate_y(-event.relative.x * sensitivity * 0.002)
        camera.rotate_x(-event.relative.y * sensitivity * 0.002)
```

## Godot 4.7 Input Notes

- **VirtualJoystick** — new built-in control for touch input; it presses regular input actions
