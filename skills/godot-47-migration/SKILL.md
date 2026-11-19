---
name: godot-47-migration
description: "Godot 4.7 migration guide: new features (HDR output, AreaLight3D, VirtualJoystick, Tween.tween_await, PopupMenu search, Control offset transforms, Perfetto tracing, Android XR and Steam Frame support) and step-by-step migration patterns for existing Godot 4.x projects. Use when upgrading a Godot project to version 4.7."
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
    - migration
    - godot-4.7
    - breaking-changes
  created: 2026-06-20
---

# Godot 4.7 Migration Guide

Guide for migrating Godot 4.x projects to version 4.7. Features below were checked against the
[4.7 release notes](https://godotengine.org/releases/4.7/) and the 4.7.2 engine.

## What's New in Godot 4.7

### Rendering & Visual
- **HDR output** — opt-in with `display/window/hdr/request_hdr_output` (off by default)
- **AreaLight3D** — new node for rectangular light sources (`area_size`, `area_range`, `area_attenuation`, `area_texture`)
- **Nearest-neighbor viewport scaling** — `Viewport.SCALING_3D_MODE_NEAREST` for crisp low-resolution 3D
- **DrawableTexture2D** — simple API for drawing on textures at runtime

### UI & Controls
- **VirtualJoystick** — built-in touch joystick (Fixed, Dynamic, Following modes) that presses input actions
- **PopupMenu search bar** — `search_bar_enabled` filters long menus
- **Control offset transforms** — `offset_transform_*` properties animate Controls on top of their layout

### Animation
- **Collapsible animation editor nodes** — collapse the tracks of one node in the Animation panel
- **`Tween.tween_await(signal)`** — pause a tween until a signal is emitted

### Android & XR
- **Perfetto** — the default tracing tool for Android editor and template builds
- **Android XR and Steam Frame** — production-ready XR support for both headsets

## Step-by-Step Migration

### Step 1: Backup Your Project
```bash
git commit -am "Before Godot 4.7 upgrade"   # or copy the project folder
```

### Step 2: Open in Godot 4.7 Editor
1. Launch Godot 4.7
2. Open your existing project and confirm the conversion prompt
3. Review warnings in the Output panel
4. Read the breaking changes linked from the release notes

### Step 3: Opt In to New Settings
```ini
; HDR output for HDR-capable displays
[display]
window/hdr/request_hdr_output=true
```

### Step 4: Replace Workarounds with New Nodes
- Emissive panels used as light sources → `AreaLight3D`
- Third-party virtual joysticks → the built-in `VirtualJoystick` (point its `action_*` properties at your existing input actions; movement code that reads actions needs no change)

### Step 5: Update Tween Patterns
Replace "await the tween, await a signal, start another tween" chains with `tween_await()`:

```gdscript
signal dialogue_closed

# Before (4.6)
func play_sequence_46() -> void:
    var tween := create_tween()
    tween.tween_property($Sprite, "position:x", 100.0, 1.0)
    await tween.finished
    await dialogue_closed
    tween = create_tween()
    tween.tween_property($Sprite, "position:y", 50.0, 0.5)

# After (4.7)
func play_sequence_47() -> void:
    var tween := create_tween()
    tween.tween_property($Sprite, "position:x", 100.0, 1.0)
    tween.tween_await(dialogue_closed)  # the tween pauses until the signal fires
    tween.tween_property($Sprite, "position:y", 50.0, 0.5)
```

### Step 6: Test All Platforms
- Desktop builds (Windows, macOS, Linux)
- Android build (capture a Perfetto trace if you profile on device)
- Web build
- XR builds if you target Android XR or Steam Frame

## Migration Checklist

- [ ] Project opened and converted in 4.7, Output panel warnings reviewed
- [ ] Breaking changes from the release notes checked against your project
- [ ] HDR output enabled only if you target HDR displays
- [ ] Workarounds replaced where the new nodes fit (AreaLight3D, VirtualJoystick)
- [ ] Tween sequences that wait on signals moved to `tween_await()`
- [ ] XR settings reviewed if targeting Android XR or Steam Frame

## Godot 4.7 Feature Quick Reference

| Feature | Category | Skill Coverage |
|---------|----------|---------------|
| VirtualJoystick | Input | godot-input |
| `Tween.tween_await()`, collapsible nodes | Animation | godot-animation |
| PopupMenu search, Control offset transforms | UI | godot-ui |
| Perfetto tracing, nearest-neighbor scaling | Performance | godot-performance |
| HDR output, AreaLight3D, Android XR, Steam Frame | Rendering / XR | this skill and [docs/migration-4.7.md](../../docs/migration-4.7.md) |

## References

- [Full Migration Guide](../../docs/migration-4.7.md)
- [Godot 4.7 release notes](https://godotengine.org/releases/4.7/)
- [Godot 4.7 documentation](https://docs.godotengine.org/en/4.7/)
