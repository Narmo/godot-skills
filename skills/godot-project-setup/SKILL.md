---
name: godot-project-setup
description: "Scaffolds a new Godot 4.x project with proper folder structure, .gdignore, export presets, .gitignore, and GDScript/C# Mono initialization. Use when creating a new Godot game or app."
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
    - project-setup
    - scaffolding
    - export-presets
  created: 2026-06-20
---

# Godot Project Setup

Scaffold a complete, production-ready Godot 4.x project with industry-standard organization.

## Quick Start

```bash
# Create a new project
./scripts/new-godot-project.sh MyGame /path/to/output
```

## Standard Directory Structure

After scaffolding, your project will have:

```
MyGame/
├── .gitignore             # Version control ignores
├── project.godot          # Project configuration
├── scenes/                # Scene files (.tscn)
│   ├── ui/               # UI scene compositions
│   ├── levels/           # Level/world scenes
│   └── entities/         # Character/entity scenes
├── scripts/               # Script files (.gd, .cs)
│   ├── core/             # Game systems (manager, event bus)
│   ├── entities/         # Entity behaviors
│   ├── ui/               # UI controllers
│   └── levels/           # Level-specific logic
├── resources/             # Resource files (.tres, .res)
│   ├── data/             # Game data (items, skills, etc.)
│   └── config/           # Configuration resources
├── assets/               # Imported assets (textures, audio, fonts, models)
│   ├── textures/
│   ├── audio/
│   ├── fonts/
│   └── models/
├── art_source/           # Source files Godot must not import (has a .gdignore)
├── levels/               # Level data and configurations
└── export_presets.cfg    # Export presets (created by the Export dialog)
```

## Project.godot Configuration

Key settings for a clean project:

```ini
[application]

config/icon="res://assets/icons/icon.png"

[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"

[rendering]

renderer/rendering_method="forward_plus"
```

## .gdignore Setup

An empty `.gdignore` file makes the editor skip its whole folder: nothing in it is imported
or usable from `res://`. Put it only in folders with files that are not game assets — layered
source art, `.blend` backups, design documents:

```bash
touch art_source/.gdignore   # never in assets/: the game could no longer load those files
```

## GDScript Project Initialization

Standard project.godot autoload setup:

```gdscript
# Add to Project Settings > Autoload
# Name: GameManager, Path: res://scripts/core/game_manager.gd
# Name: EventBus, Path: res://scripts/core/event_bus.gd
# Name: AudioManager, Path: res://scripts/core/audio_manager.gd
```

## C# Mono Project Initialization

For C# projects, use the .NET build of the editor: it creates the `.csproj` and `.sln` the
first time you add a C# script (**Project > Tools > C# > Create C# solution**). Commit both
files. The scaffolding script creates a GDScript-only project.

## Godot 4.7 Specific Setup

When creating projects with Godot 4.7 features:

1. **HDR output** — opt in for HDR-capable displays:
   ```ini
   [display]
   window/hdr/request_hdr_output=true
   ```

2. **VirtualJoystick** — use the built-in node for mobile projects instead of third-party solutions

3. **Export Presets** — configure the platforms you ship: Windows, macOS, Linux, Android, iOS, Web

## Export Presets

Common export configurations:

| Target | Renderer default | Notes |
|--------|------------------|-------|
| Windows | Forward+ (Vulkan; D3D12 selectable) | Default for PC games |
| Linux | Forward+ (Vulkan) | Needs Vulkan drivers; Compatibility renderer as fallback |
| Android | Compatibility on mobile by default | Use VirtualJoystick for touch controls |
| Web | Compatibility only | Limited to web-compatible features |
