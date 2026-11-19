---
name: godot-save-systems
description: "Save system patterns for Godot 4.x: resource-based saves, JSON vs binary serialization, versioning/migration strategies, cloud save integration, and corruption recovery. Use when implementing persistence in Godot games."
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
    - save-system
    - persistence
    - serialization
    - migration
  created: 2026-06-21
---

# Save Systems in Godot

Patterns for persisting game state reliably.

## Never Load a Save File as a Resource

`ResourceLoader.load()` on a `.tres`/`.res` file is **code execution**, not
deserialization. A resource file can reference a script, and that script's
`_init()` runs the moment the file is loaded. Save files live in `user://`, which
the player — or anything that can write to their disk, including a compromised
cloud save endpoint — fully controls.

```gdscript
# DANGEROUS — a crafted user://savegame.tres executes arbitrary code on load
var data = ResourceLoader.load("user://savegame.tres") as SaveData
```

Save game state as plain data instead: JSON for readability, `var_to_bytes()` for
compactness. Both round-trip Godot's built-in types without instantiating objects.

## Dictionary Saves (Recommended)

Godot's `Resource` system provides native serialization with type safety, and is
the right tool for *authored* content shipped inside `res://`. For player saves,
keep the typed `SaveData` class as your in-memory shape but persist a dictionary:

```gdscript
class_name SaveData extends Resource

const SAVE_VERSION := 1

@export var save_version: int = SAVE_VERSION
@export var timestamp: float = 0.0
@export var player_position: Vector2 = Vector2.ZERO
@export var player_health: int = 100
@export var inventory: Array[String] = []  # item ids, resolved against res:// on load
@export var quest_flags: Dictionary = {}

func to_dict() -> Dictionary:
    return {
        "save_version": save_version,
        "timestamp": timestamp,
        "player_position": player_position,
        "player_health": player_health,
        "inventory": inventory,
        "quest_flags": quest_flags,
    }

# Every field is untrusted — a save file can claim anything.
static func from_dict(d: Dictionary) -> SaveData:
    var data := SaveData.new()
    data.save_version = int(d.get("save_version", 0))
    data.timestamp = float(d.get("timestamp", 0.0))
    data.player_health = clampi(int(d.get("player_health", 100)), 0, 100)

    var pos = d.get("player_position", Vector2.ZERO)
    data.player_position = pos if pos is Vector2 else Vector2.ZERO

    var flags = d.get("quest_flags", {})
    data.quest_flags = flags if flags is Dictionary else {}

    for item in d.get("inventory", []):
        if item is String:
            data.inventory.append(item)

    return data
```

Storing item **ids** rather than `Array[Resource]` is what keeps the save free of
objects: ids are looked up in a table you control, so a save file can never name a
script to instantiate.

### Save Manager

```gdscript
class_name SaveManager
extends Node

const SAVE_PATH := "user://savegame.save"


func save_game(data: SaveData) -> Error:
    data.timestamp = Time.get_unix_time_from_system()
    # Write to a temporary file first, then swap it in: a crash mid-write
    # leaves the previous save intact instead of a half-written one.
    var tmp_path := SAVE_PATH + ".tmp"
    var file := FileAccess.open(tmp_path, FileAccess.WRITE)
    if file == null:
        push_error("SaveManager: Failed to save — %s" % error_string(FileAccess.get_open_error()))
        return ERR_FILE_CANT_OPEN
    # allow_objects stays off: only built-in types cross this boundary
    file.store_var(data.to_dict(), false)
    file.close()
    return DirAccess.rename_absolute(tmp_path, SAVE_PATH)


func load_game() -> SaveData:
    var raw := read_raw(SAVE_PATH)
    return SaveData.from_dict(migrate(raw)) if not raw.is_empty() else null


func read_raw(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("SaveManager: Failed to open %s" % path)
        return {}
    var raw: Variant = file.get_var(false)
    if raw is not Dictionary:
        push_error("SaveManager: %s is malformed" % path)
        return {}
    return raw


func delete_game() -> void:
    DirAccess.remove_absolute(SAVE_PATH)


func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)
```

`store_var`/`get_var` with `allow_objects = false` is the whole mitigation: a
malicious save can then only produce wrong *data*, never running code. Treat every
field as untrusted input and clamp it in `from_dict()`.

Don't name these methods `load()`/`save()`: `load()` would shadow the global function and
every `load("res://...")` inside the class would call your method instead.

### Multiple Save Slots

```gdscript
func get_slot_path(slot_index: int) -> String:
    return "user://savegame_%d.save" % slot_index


# Slot metadata for the load menu, stored next to each save as plain data.
# Keep a thumbnail as a PNG file (Image.save_png) rather than a Texture2D in the save.
func write_slot_info(slot_index: int, player_level: int) -> void:
    var info := {
        "slot_index": slot_index,
        "timestamp": Time.get_unix_time_from_system(),
        "player_level": player_level,
        "thumbnail_path": "user://slot_%d.png" % slot_index,
    }
    var file := FileAccess.open("user://slot_%d.info" % slot_index, FileAccess.WRITE)
    if file:
        file.store_var(info, false)
```

## JSON Serialization

For human-readable saves or cross-platform data exchange. JSON only knows strings, numbers,
booleans, arrays and objects, so convert Godot types yourself:

```gdscript
func save_as_json(data: SaveData, path: String) -> Error:
    var dict := data.to_dict()
    dict["player_position"] = [data.player_position.x, data.player_position.y]
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return ERR_FILE_CANT_OPEN
    file.store_string(JSON.stringify(dict, "  "))
    return OK


func load_from_json(path: String) -> SaveData:
    if not FileAccess.file_exists(path):
        return null
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if parsed is not Dictionary:
        return null
    var dict: Dictionary = parsed
    var pos: Variant = dict.get("player_position")
    if pos is Array and pos.size() == 2:
        dict["player_position"] = Vector2(float(pos[0]), float(pos[1]))
    return SaveData.from_dict(dict)  # numbers come back as floats; from_dict converts them
```

`JSON.from_native()` / `JSON.to_native()` (Godot 4.4+) round-trip Godot types automatically,
at the cost of a less readable file.

## Versioning and Migration

Migrate the raw dictionary before turning it into `SaveData`, one version step at a time:

```gdscript
func migrate(raw: Dictionary) -> Dictionary:
    var version := int(raw.get("save_version", 0))
    while version < SaveData.SAVE_VERSION:
        match version:
            0:
                # v0 → v1: quest flags were added
                raw["quest_flags"] = {}
            _:
                push_warning("SaveManager: No migration from v%d" % version)
                break
        version += 1
        raw["save_version"] = version
    return raw
```

## Corruption Recovery

Protect against corrupted save files:

```gdscript
const BACKUP_PATH := SAVE_PATH + ".bak"


func load_safe() -> SaveData:
    var raw := read_raw(SAVE_PATH)
    if _validate(raw):
        return SaveData.from_dict(migrate(raw))

    var backup := read_raw(BACKUP_PATH)
    if _validate(backup):
        push_warning("SaveManager: Primary save corrupted, loading backup")
        # Keep the broken file for bug reports instead of deleting it
        DirAccess.rename_absolute(SAVE_PATH, SAVE_PATH + ".corrupt")
        DirAccess.copy_absolute(BACKUP_PATH, SAVE_PATH)
        return SaveData.from_dict(migrate(backup))

    push_error("SaveManager: No valid save found")
    return null


func _validate(raw: Dictionary) -> bool:
    return not raw.is_empty() and raw.has("save_version") and raw.has("player_health")


# Create a backup of the last good save before overwriting it
func save_with_backup(data: SaveData) -> Error:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
    return save_game(data)
```

## Cloud Save Integration Pattern

A downloaded save is attacker-controlled input: it crossed a network you do not
control. Parse it with the same object-free loader used for local saves, and
validate before applying. Never hand a downloaded blob to `ResourceLoader`.

Abstract the cloud provider behind a base class (GDScript has no interfaces, so the base
methods report that they must be overridden):

```gdscript
class_name CloudSaveProvider
extends RefCounted


func upload(_data: PackedByteArray, _key: String) -> bool:
    push_error("CloudSaveProvider.upload() must be overridden")
    return false


func download(_key: String) -> PackedByteArray:
    push_error("CloudSaveProvider.download() must be overridden")
    return PackedByteArray()


func delete(_key: String) -> bool:
    push_error("CloudSaveProvider.delete() must be overridden")
    return false

# Concrete providers extend it:
# class_name GooglePlaySaveProvider extends CloudSaveProvider
```

Decode a download with `bytes_to_var(bytes)` — never `bytes_to_var_with_objects()` — and
validate it like a local save.

## Auto-Save Strategies

```gdscript
class_name AutoSaver
extends Node

@export var interval_seconds: float = 30.0
@export var save_manager: SaveManager

var _timer: Timer


func _ready() -> void:
    _timer = Timer.new()
    _timer.wait_time = interval_seconds
    _timer.timeout.connect(_on_auto_save)
    add_child(_timer)
    _timer.start()


func _on_auto_save() -> void:
    save_manager.save_game(build_save_data())


func build_save_data() -> SaveData:
    var data := SaveData.new()
    # Fill from the current game state here
    return data
```

## Notes

- **ResourceSaver/ResourceLoader** are for authored `res://` content, not player saves
- **ConfigFile** — use for settings and preferences, kept separate from game saves
