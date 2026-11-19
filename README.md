# godot-skills

**Godot game development skills for AI coding agents.**

Maintained by Nikita Denin (narmo). Fork of [vl4dt/godot-skills](https://github.com/vl4dt/godot-skills) by Ricardo A. Salgado.

A complete, distributable, open-source skill package providing domain knowledge, best practices, and patterns for Godot 4.x game development with full Godot 4.7 feature coverage. Compatible with pi-agent and 30+ other coding agents via the [Agent Skills Open Standard](https://agentskills.io).

## Quick Start

### Install in pi-agent
```bash
pi install git:github.com/Narmo/godot-skills
# or pin a release (tags match CHANGELOG versions):
pi install git:github.com/Narmo/godot-skills@v2.0.0
```

### Local development
```bash
cd /path/to/your-project
pi install ./path/to/godot-skills -l
```

## Available Skills

| Skill | Description |
|-------|-------------|
| **godot-project-setup** | Scaffold a new Godot 4.x project with proper folder structure, .gdignore, export presets, and GDScript/C# initialization |
| **godot-brainstorming** | Architecture decision patterns for different game genres, scene organization strategies, state machines, network architecture |
| **godot-gdscript-patterns** | GDScript best practices: node composition, typed signals, scene instantiation, resource management, singletons, event buses |
| **godot-csharp-patterns** | C# patterns: Export attributes, signal handling, performance optimization, interop with GDScript |
| **godot-code-review** | Common pitfalls, performance checklist, code style guidelines, memory management, signal leak detection |
| **godot-debugging** | Debugging workflow, common error patterns, profiling, network debugging, export/build troubleshooting |
| **godot-headless-workflow** | AI-agent development loop without the editor: headless validation (`--check-only`), import gate, gdUnit4 testing, safe text-scene editing, CLI export pipeline (Android/iOS), mobile checklist, RevenueCat plugin integration |
| **godot-pck-encryption** | PCK encryption: AES-256 key generation, custom export templates built with `SCRIPT_AES256_ENCRYPTION_KEY` per platform, encryption filters that match exported names (`.gdc`, `.scn`, `.ctex`), CLI export with `GODOT_SCRIPT_ENCRYPTION_KEY`, template/PCK verification, troubleshooting |
| **godot-47-migration** | Step-by-step migration from Godot 4.x to 4.7: HDR output, AreaLight3D, VirtualJoystick, `Tween.tween_await()`, Perfetto tracing, Android XR and Steam Frame |
| **godot-physics** | Physics systems: collision layers/masks, rigid body dynamics, character controllers (CharacterBody2D/3D), area triggers, physics interpolation |
| **godot-animation** | Animation systems: AnimationPlayer vs AnimationTree, state machines, blend spaces (1D/2D/directional), root motion, tween_await() |
| **godot-ui** | UI systems: Control hierarchy, containers and layout modes, themes, RichTextLabel, PopupMenu search, control offset transforms (4.7) |
| **godot-performance** | Performance optimization: profiling workflow, memory management, instancing/LOD, draw calls, mobile optimization, Perfetto tracing |
| **godot-networking** | Networking and multiplayer: `@rpc` annotations, authority models, MultiplayerSynchronizer/MultiplayerSpawner replication, connection management, lag compensation |
| **godot-architecture** | Game architecture: ECS-like composition, scene organization, dependency injection via signals, service locator vs direct reference, scalable project structure |
| **godot-state-management** | State management: enum-based state, finite state machines, hierarchical FSMs, behavior trees for AI |
| **godot-save-systems** | Save systems: resource-based saves, JSON vs binary serialization, versioning/migration, cloud saves, corruption recovery |
| **godot-inventory-economy** | Inventory and economy: resource-based item definitions, stackable/unique items, drag-drop UI, equip systems, currency, save integration |
| **godot-dialog-systems** | Dialogue systems: resource-based dialogue trees, branching narratives, typewriter text, voice sync, portraits |
| **godot-i18n** | Localization: TranslationServer, CSV/PO translations, runtime language switching, RTL text, font fallback chains, pluralization |
| **godot-audio** | Audio: AudioStreamPlayer hierarchy, bus mixing, spatial audio (2D/3D), randomization, dynamic music, AudioListener positioning |
| **godot-shaders-vfx** | Visual effects: Godot shading language basics, canvas_item/spatial shaders, GPU particles, shader materials, post-processing |
| **godot-input** | Input handling: input map, action polling vs events, gamepad and VirtualJoystick support, remapping UI, dead zones, touch/multi-touch |

## Godot 4.7 Feature Coverage

The skills cover these Godot 4.7 features where they apply:

- HDR output (`display/window/hdr/request_hdr_output`)
- Production-ready XR support for Android XR and Steam Frame
- New AreaLight3D node for rectangular light sources
- VirtualJoystick for mobile development
- `Tween.tween_await()` — pause a tween until a signal is emitted
- Collapsible node groups in the animation editor
- PopupMenu search functionality
- Control offset transforms for UI animation
- Perfetto tracing for Android profiling
- Nearest-neighbor viewport scaling
- DrawableTexture2D for dynamic textures

## Cross-Agent Compatibility

This package is compatible with:

| Agent | Status |
|-------|--------|
| pi-agent | Full support |
| Claude Code | Via `.claude/skills/` |
| Codex CLI (OpenAI) | Via `~/.agents/skills/` |
| Gemini CLI | Partial support |
| Cursor | Partial support |
| Cline | Via `~/.cline/skills/` |
| Kiro | Emerging support |

Each skill follows the [Agent Skills Open Standard](https://agentskills.io/specification) with proper SKILL.md frontmatter (name, description), progressive disclosure, and agent-specific extensions in `agents/` subdirectories.

## Installation for Other Agents

Install commands for Claude Code, Codex CLI, Cline and the rest are in [AGENTS.md](AGENTS.md#agent-specific-setup).

## Package Structure

```
godot-skills/
├── README.md              # This file
├── AGENTS.md              # Cross-agent guide and repository rules (CLAUDE.md is a symlink to it)
├── CHANGELOG.md           # Versioned changelog
├── SECURITY.md            # Vulnerability reporting and insecure-pattern policy
├── LICENSE                # MIT License
├── skills/                # 23 skills, one directory each: SKILL.md, agents/, optional references/
├── docs/
│   ├── architecture.md    # Architecture decision records (mirrored in docs/adr/)
│   ├── contributing.md    # Contributor guide
│   ├── cross-agent-testing.md
│   ├── migration-4.7.md   # Godot 4.7 migration guide
│   ├── ecosystem.md       # Community tools and plugins
│   ├── release-process.md
│   ├── changelog-guide.md
│   └── skill-template/    # Template used by scripts/new-skill.sh
├── scripts/               # verify.sh / verify.ps1, validators, new-skill.sh, new-godot-project.sh
└── examples/              # Example Godot projects
    ├── minimal-rpg/
    ├── platformer-2d/
    └── multiplayer-lobby/
```

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contributing

See [docs/contributing.md](docs/contributing.md) for contribution guidelines.

---

Built for the [Agent Skills Open Standard](https://agentskills.io) ecosystem.
