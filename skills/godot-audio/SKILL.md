---
name: godot-audio
description: "Audio patterns for Godot 4.x: AudioStreamPlayer hierarchy, bus mixing, spatial audio (2D/3D), randomization, dynamic music, and AudioListener positioning. Use when implementing sound effects, music systems, or audio mixing in Godot games."
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
    - audio
    - sound
    - music
    - spatial-audio
    - bus-mixing
  created: 2026-06-21
---

# Audio in Godot

Patterns for game audio implementation.

## AudioStreamPlayer Hierarchy

Godot provides separate nodes for 2D and 3D audio:

```gdscript
# 2D audio — pans and attenuates by distance to the screen center
# (or to the current AudioListener2D)
var sfx_player = AudioStreamPlayer2D.new()
sfx_player.stream = preload("res://sounds/footstep.ogg")
add_child(sfx_player)
sfx_player.play()

# 3D audio — attenuates and pans by distance to the current camera (or AudioListener3D)
var sfx_player_3d = AudioStreamPlayer3D.new()
sfx_player_3d.stream = preload("res://sounds/explosion.ogg")
sfx_player_3d.unit_size = 10.0  # Higher values keep the sound audible further away
add_child(sfx_player_3d)
sfx_player_3d.play()
```

### AudioListener Placement

The current camera is the listener by default. Add a listener only when the "ears" should be
somewhere else — for example on the player in a third-person game:

```gdscript
# 3D: hear from the player instead of the camera
var listener := AudioListener3D.new()
$Player.add_child(listener)
listener.make_current()

# 2D works the same way with AudioListener2D
var listener_2d := AudioListener2D.new()
$Player2D.add_child(listener_2d)
listener_2d.make_current()
```

## Bus Mixing

Route audio through buses for independent volume/effects control:

```gdscript
# Create buses in the editor's Audio panel (saved as default_bus_layout.tres),
# then adjust them from code:
func setup_audio_buses() -> void:
    # Find bus index by name
    var music_bus = AudioServer.get_bus_index("Music")
    var sfx_bus = AudioServer.get_bus_index("SFX")
    var ambient_bus = AudioServer.get_bus_index("Ambient")

    # Volumes are in dB; convert from a linear 0..1 slider value
    AudioServer.set_bus_volume_db(music_bus, linear_to_db(0.7))
    AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(1.0))
    AudioServer.set_bus_volume_db(ambient_bus, linear_to_db(0.5))

    # Mute individual buses
    AudioServer.set_bus_mute(sfx_bus, false)
```

### Per-Player Bus Assignment

```gdscript
# Assign a player node to a specific bus — the property takes the bus name
$AudioStreamPlayer.bus = &"SFX"
```

## Spatial Audio (3D)

`AudioStreamPlayer3D` automatically handles distance attenuation and stereo panning:

```gdscript
class_name EnemyExplosion extends Node3D

var explosion_player: AudioStreamPlayer3D

func _ready() -> void:
    explosion_player = AudioStreamPlayer3D.new()
    explosion_player.stream = preload("res://sounds/explosion.ogg")
    explosion_player.unit_size = 1.0  # 1 unit = 1 meter
    explosion_player.max_distance = 50.0
    explosion_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
    add_child(explosion_player)

func explode() -> void:
    explosion_player.play()
    # Visual effects here...
```

### Spatial Audio Models

| Model | Use Case |
|-------|----------|
| `ATTENUATION_DISABLED` | UI sounds, non-spatial audio in 3D scenes |
| `ATTENUATION_INVERSE_DISTANCE` | Default — realistic falloff |
| `ATTENUATION_INVERSE_SQUARE_DISTANCE` | Steeper falloff, sounds fade quickly |
| `ATTENUATION_LOGARITHMIC` | Gentle falloff for large spaces |

## Sound Effect Randomization

Avoid the "machine gun" effect by randomizing pitch and playback. Without code: assign an
`AudioStreamRandomizer` (random clip, pitch and volume) as the stream and raise the player's
`max_polyphony` so overlapping plays don't cut each other off. With a pool:

```gdscript
class_name SFXPool extends Node

@export var sounds: Array[AudioStream] = []
var _players: Array[AudioStreamPlayer] = []
@export var pool_size: int = 8

func _ready() -> void:
    for i in range(pool_size):
        var player = AudioStreamPlayer.new()
        player.bus = "SFX"
        add_child(player)
        _players.append(player)

func play_random() -> void:
    if sounds.is_empty():
        return

    # Find first available player
    for player in _players:
        if not player.playing:
            player.stream = sounds[randi() % sounds.size()]
            # Randomize pitch slightly (0.9 to 1.1)
            player.pitch_scale = randf_range(0.9, 1.1)
            player.play()
            return

    # All busy — steal the first one
    _players[0].stream = sounds[randi() % sounds.size()]
    _players[0].pitch_scale = randf_range(0.9, 1.1)
    _players[0].play()
```

## Dynamic Music System

Crossfade between music tracks based on game state:

```gdscript
class_name MusicManager extends Node

var _current_player: AudioStreamPlayer = null
var _next_player: AudioStreamPlayer = null
const FADE_DURATION := 1.5

func _ready() -> void:
    _current_player = AudioStreamPlayer.new()
    _current_player.bus = "Music"
    add_child(_current_player)

    _next_player = AudioStreamPlayer.new()
    _next_player.bus = "Music"
    add_child(_next_player)

func play(track: AudioStream) -> void:
    if _current_player.stream == track and _current_player.playing:
        return

    # Start next player at silent
    _next_player.stream = track
    _next_player.volume_db = -80.0  # Effectively silent
    _next_player.play()

    # Crossfade: both fades run at the same time
    var tween = create_tween().set_parallel(true)
    if _current_player.playing:
        tween.tween_method(_set_current_volume, 0.0, -80.0, FADE_DURATION)
    tween.tween_method(_set_next_volume, -80.0, 0.0, FADE_DURATION)

    # Swap roles after fade
    await tween.finished
    var temp = _current_player
    _current_player = _next_player
    _next_player = temp
    _next_player.stop()
    _next_player.volume_db = -80.0

func _set_current_volume(vol: float) -> void:
    if _current_player:
        _current_player.volume_db = vol

func _set_next_volume(vol: float) -> void:
    if _next_player:
        _next_player.volume_db = vol

func stop(fade_out: bool = true) -> void:
    if not _current_player or not _current_player.playing:
        return
    if fade_out:
        var tween = create_tween()
        tween.tween_method(_set_current_volume, _current_player.volume_db, -80.0, FADE_DURATION)
        await tween.finished
        _current_player.stop()
    else:
        _current_player.stop()
```

## Accessibility Patterns

### Subtitle/SRT Sync

```gdscript
# subtitle_cue.gd
class_name SubtitleCue
extends Resource

@export var time: float = 0.0
@export_multiline var text: String = ""
```

```gdscript
class_name DialogueAudio
extends AudioStreamPlayer

signal subtitle_shown(text: String)

@export var subtitles: Array[SubtitleCue] = []

var _active_cue_index: int = -1


func play_with_subtitles() -> void:
    _active_cue_index = -1
    play()


func _process(_delta: float) -> void:
    if not playing:
        return
    var elapsed := get_playback_position()
    while _active_cue_index + 1 < subtitles.size():
        var cue := subtitles[_active_cue_index + 1]
        if elapsed < cue.time:
            break
        _active_cue_index += 1
        subtitle_shown.emit(cue.text)
```

### Audio Cues for Visually Impaired Players

```gdscript
# Emit directional audio cues for important events
func play_directional_cue(direction: Vector3, sound: AudioStream) -> void:
    var player := AudioStreamPlayer3D.new()
    player.stream = sound
    player.max_distance = 20.0
    add_child(player)
    # Place the sound two meters from the listener in the given direction
    var ears := get_viewport().get_camera_3d().global_position
    player.global_position = ears + direction.normalized() * 2.0
    player.play()

    # Auto-cleanup after sound ends
    player.finished.connect(player.queue_free)
```
