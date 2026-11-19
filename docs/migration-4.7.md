# Godot 4.7 Migration Guide

This guide covers the Godot 4.7 changes that affect game development patterns and the skills in
this package. Features below were checked against the [4.7 release notes](https://godotengine.org/releases/4.7/)
and the 4.7.2 engine.

## New Features in Godot 4.7

### Rendering & Visual
- **HDR output** — opt-in through `display/window/hdr/request_hdr_output` (off by default) for HDR-capable displays
- **AreaLight3D** — new node for rectangular light sources (`area_size`, `area_range`, `area_attenuation`, `area_texture`); replaces the emissive-material-plus-GI workaround
- **Nearest-neighbor viewport scaling** — new `SCALING_3D_MODE_NEAREST` option for crisp, pixel-art-style 3D upscaling
- **DrawableTexture2D** — an approachable API for drawing on textures at runtime

### UI & Controls
- **VirtualJoystick** — built-in on-screen joystick with three modes (Fixed, Dynamic, Following); it triggers the input actions set in `action_left`/`action_right`/`action_up`/`action_down` (`ui_*` by default)
- **PopupMenu search bar** — optional search field for long menus (`search_bar_enabled`, `search_bar_min_item_count`, fuzzy search options)
- **Control offset transforms** — `offset_transform_*` properties (position, scale, rotation, pivot) for animating UI without fighting containers

### Animation
- **`Tween.tween_await(signal)`** — pauses a tween until a signal is emitted, handy for dialogue and cutscenes
- **Collapsible animation editor nodes** — tracks of one node can be collapsed, with an aggregate view of their keys

### Android & XR
- **Perfetto** — now the default tracing tool for Android editor and template builds
- **Android XR and Steam Frame** — production-ready XR support for both headsets (OpenXR, `xr/openxr/enabled`)

## Migration Checklist (4.6 → 4.7)

1. **Back up or commit the project**, then open it in the 4.7 editor to convert it
2. **Read the breaking changes** linked from the [4.7 release notes](https://godotengine.org/releases/4.7/)
3. **HDR** — enable `display/window/hdr/request_hdr_output` only if you target HDR displays; nothing changes otherwise
4. **Virtual joysticks** — consider replacing third-party joystick add-ons with the built-in VirtualJoystick node
5. **Tween sequences that wait for signals** — replace "await the tween, await the signal, start a new tween" chains with `tween_await()`
6. **Area lighting** — replace emissive meshes used as light panels with AreaLight3D where it looks better
7. **XR projects** — review the OpenXR settings for Android XR and Steam Frame
8. **Android profiling** — capture traces with Perfetto

## Code Examples

### Before: waiting for a signal between tweens (4.6 and earlier)
```gdscript
signal dialogue_closed

func play_cutscene() -> void:
    var tween := create_tween()
    tween.tween_property($Camera2D, "position:x", 400.0, 1.0)
    await tween.finished
    await dialogue_closed
    tween = create_tween()
    tween.tween_property($Camera2D, "position:x", 0.0, 1.0)
```

### After: `tween_await()` (4.7+)
```gdscript
signal dialogue_closed

func play_cutscene() -> void:
    var tween := create_tween()
    tween.tween_property($Camera2D, "position:x", 400.0, 1.0)
    tween.tween_await(dialogue_closed)  # the tween pauses here until the signal fires
    tween.tween_property($Camera2D, "position:x", 0.0, 1.0)
```

### New: VirtualJoystick (4.7+)
```gdscript
# Add a VirtualJoystick node to the UI. It presses the actions set in its
# action_* properties (ui_left/ui_right/ui_up/ui_down by default), so
# movement code reads them like any other input.
func _physics_process(_delta: float) -> void:
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    velocity = direction * speed
    move_and_slide()
```

## Further Reading

- [Godot 4.7 release notes](https://godotengine.org/releases/4.7/)
- [Godot 4.7 documentation](https://docs.godotengine.org/en/4.7/)
- [Godot releases on GitHub](https://github.com/godotengine/godot/releases)
