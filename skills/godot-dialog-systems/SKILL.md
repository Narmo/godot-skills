---
name: godot-dialog-systems
description: "Dialogue system patterns for Godot 4.x: resource-based dialogue trees, branching narratives, typewriter text effects, voice sync, and portrait management. Use when building NPC conversations, quest dialogue, or narrative systems in Godot."
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
    - dialogue
    - narrative
    - branching
    - typewriter
  created: 2026-06-21
---

# Dialogue Systems in Godot

Patterns for building conversation and narrative systems.

## Resource-Based Dialogue Data

Store dialogue as `Resource` files for easy editing and versioning. One `class_name` per file:

```gdscript
# dialogue_choice.gd
class_name DialogueChoice
extends Resource

@export var choice_text: String = ""
@export var target_line_id: String = ""
@export var requires_flag: String = ""  # Optional quest flag check
```

```gdscript
# dialogue_line.gd
class_name DialogueLine
extends Resource

@export var speaker: String = ""
@export_multiline var text: String = ""
@export var voice: AudioStream = null  # Optional voice clip
@export var portrait_index: int = -1
@export var next_line_id: String = ""  # Where to go when there are no choices
@export var choices: Array[DialogueChoice] = []
```

### Dialogue Script Resource

```gdscript
# dialogue_script.gd
class_name DialogueScript
extends Resource

@export var script_name: String = ""
@export var start_line_id: String = ""
@export var lines: Dictionary[String, DialogueLine] = {}
```

## Dialogue Manager

Central system for playing dialogue sequences. The UI shows each line and calls `advance()`
or `select_choice()` when the player continues:

```gdscript
class_name DialogueManager
extends Node

signal line_shown(line: DialogueLine)
signal choices_presented(choices: Array[DialogueChoice])
signal dialogue_ended

var current_dialogue: DialogueScript = null
var current_line: DialogueLine = null
var is_playing: bool = false
var flags: Dictionary[String, bool] = {}  # Quest/state flags


func play(dialogue: DialogueScript) -> void:
    current_dialogue = dialogue
    is_playing = true
    _show_line(dialogue.start_line_id)


func _show_line(line_id: String) -> void:
    if not current_dialogue.lines.has(line_id):
        push_error("DialogueManager: Line '%s' not found" % line_id)
        end_dialogue()
        return

    current_line = current_dialogue.lines[line_id]
    line_shown.emit(current_line)
    var available := available_choices(current_line)
    if not available.is_empty():
        choices_presented.emit(available)


func advance() -> void:
    if current_line == null or not available_choices(current_line).is_empty():
        return  # a choice is pending
    if current_line.next_line_id.is_empty():
        end_dialogue()
    else:
        _show_line(current_line.next_line_id)


func select_choice(choice: DialogueChoice) -> void:
    if current_line == null or choice not in available_choices(current_line):
        return
    _show_line(choice.target_line_id)


## Choices whose flag requirement is met.
func available_choices(line: DialogueLine) -> Array[DialogueChoice]:
    var result: Array[DialogueChoice] = []
    for choice in line.choices:
        if choice.requires_flag.is_empty() or flags.get(choice.requires_flag, false):
            result.append(choice)
    return result


func end_dialogue() -> void:
    is_playing = false
    current_dialogue = null
    current_line = null
    dialogue_ended.emit()


func set_flag(flag: String, value: bool = true) -> void:
    flags[flag] = value
```

A line whose choices are all locked behaves like a line without choices and follows
`next_line_id`.

## Typewriter Text Effect

Reveal text character by character with `visible_characters`, which keeps BBCode formatting
intact (unlike cutting the string):

```gdscript
class_name DialogueText
extends RichTextLabel

signal typing_progress(chars_shown: int, total_chars: int)
signal typing_complete

@export var chars_per_second: float = 30.0

var _visible := 0.0


func start_typing(line_text: String) -> void:
    bbcode_enabled = true
    text = line_text
    visible_characters = 0
    _visible = 0.0


func is_typing() -> bool:
    return visible_characters != -1 and visible_characters < get_total_character_count()


func _process(delta: float) -> void:
    if not is_typing():
        return
    _visible += chars_per_second * delta
    visible_characters = mini(int(_visible), get_total_character_count())
    typing_progress.emit(visible_characters, get_total_character_count())
    if not is_typing():
        typing_complete.emit()


# Skip to the end on click
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and is_typing():
        visible_characters = -1  # show everything
        typing_complete.emit()
```

## Branching Dialogue Pattern

Branches are just choices with targets and optional flag requirements:

```gdscript
# Line "greeting":
#   text: "Hello there, {name}!"
#   choices:
#     - "Hi!"           → "friendly_chat"
#     - "Who are you?"  → "hostile_chat"
#     - "I need help."  → "quest_offer"   (requires_flag: met_quest_giver)

func show_line(line: DialogueLine, player_name: String) -> void:
    # Fill placeholders at display time, after translation
    $DialogueText.start_typing(tr(line.text).format({"name": player_name}))
```

## Portrait Management

Display character portraits during dialogue:

```gdscript
class_name DialoguePortrait
extends TextureRect

enum PortraitState { IDLE, TALKING, SURPRISED }

@export var portrait_frames: Array[Texture2D] = []

var current_state: PortraitState = PortraitState.IDLE


func show_portrait(index: int) -> void:
    if index < 0 or index >= portrait_frames.size():
        hide()
        return
    texture = portrait_frames[index]
    show()


# Small "talking" bounce while text types
func play_talking() -> void:
    current_state = PortraitState.TALKING
    pivot_offset = size / 2.0
    var tween := create_tween().set_loops(3)
    tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.08)
    tween.tween_property(self, "scale", Vector2.ONE, 0.08)
```

## Godot 4.7 Dialogue Notes

- **`Tween.tween_await(signal)`** — one tween can open the panel, wait for `DialogueManager.dialogue_ended`, then close it
- **RichTextLabel effects** — built-in `[wave]`, `[shake]`, `[tornado]`, `[fade]`, `[rainbow]` and `[pulse]` tags add emphasis to lines
