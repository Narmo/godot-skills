# Changelog

All notable changes to godot-skills.

Format: [Keep a Changelog](https://keepachangelog.com/) | Versioning: [SemVer](https://semver.org/)
See [docs/changelog-guide.md](docs/changelog-guide.md) for conventions. Every version below has
a matching `vX.Y.Z` git tag; install one with `pi install git:github.com/Narmo/godot-skills@vX.Y.Z`.

## [2.0.0] — 2026-11-19

### Changed
- Fork maintained by Nikita Denin (narmo) at `github.com/Narmo/godot-skills`
- Distribution is git only: `pi install git:github.com/Narmo/godot-skills`, with pi discovering skills from the conventional `skills/` directory. Releases are git tags
- Skills checked against the Godot 4.7.2 engine and corrected where they used APIs that don't exist or describe them wrongly — most visibly `godot-networking` (Godot 4 has no `rset()`; replication is done with `MultiplayerSynchronizer` and `MultiplayerSpawner`), `godot-shaders-vfx` (Godot 4 shader syntax), `godot-performance`, `godot-physics`, `godot-ui`, `godot-i18n`, `godot-input`, `godot-animation`, `godot-audio`, `godot-save-systems`, `godot-inventory-economy`, `godot-dialog-systems`, `godot-state-management`, `godot-debugging`, `godot-csharp-patterns`, `godot-gdscript-patterns`, `godot-code-review` and `godot-47-migration`
- Godot 4.7 features described as the release notes and the engine have them: `Tween.tween_await()` pauses a tween until a signal fires; Steam Frame is an XR headset; HDR output is `display/window/hdr/request_hdr_output`; `VirtualJoystick` presses input actions
- `agents/openai.yaml` files use Codex's format (`interface`, `policy`)
- `AGENTS.md` holds the repository rules; `CLAUDE.md` is a symlink to it

### Removed
- MCP bridge (`mcp-bridge/`): the server, its protocol and tool docs, client config templates, ADR-004, the CI build job, and the "MCP Bridge Tools" sections of the skills. It needed a Godot editor plugin that was never part of this repository
- Root `package.json` — the `@vl4dt/godot-skills` npm name, the `pi-package` gallery keyword, and the `pi.skills` manifest that duplicated conventional discovery; npm publish, verify and unpublish steps from `docs/release-process.md`; the `package.json` checks in `scripts/validate-skills.sh`, `scripts/verify.sh` and `scripts/verify.ps1`
- Beads issue tracking — `.beads/`, the generated `CLAUDE.md`, `.claude/settings.json` hooks running `bd prime`, the beads block in `AGENTS.md`, and the beads entries in `.gitignore`
- `CONTEXT.md` — its repository rules moved into `AGENTS.md`; the rest duplicated README and CHANGELOG
- `docs/specs/` — completed phase plans; the delivered work is in CHANGELOG and git history
- Root `CODE_OF_CONDUCT.md` and the `CONTRIBUTING.md` redirect to `docs/contributing.md`
- `.gdignore` files at the root of the example projects

### Fixed
- Example projects load and run in Godot 4.7.2: valid input maps in `project.godot`, working scenes and scripts; the multiplayer lobby connects two instances and starts the game
- `scripts/new-godot-project.sh` — no `.gdignore` in `assets/` (it hid every asset from the editor), `.gitignore` no longer ignores `project.godot` or C# project files, the project name is filled in, window size uses `viewport_width`/`viewport_height`
- `scripts/new-skill.sh` — title capitalization works with BSD/macOS sed; generated skills pass `lint-skills.sh` and `check-agent-extensions.sh`
- `godot-headless-workflow` — Android signing variables are `GODOT_ANDROID_KEYSTORE_RELEASE_*`; AAB export needs `gradle_build/export_format`; the iOS export path is a file; gdUnit4 options and `GODOT_BIN`; the verify gate checks the right script paths; tool-built scenes set `owner`
- Documentation: skill install commands copy the contents of `skills/`; Codex user skills live in `~/.agents/skills/`; the README lists every skill; dead and mislabeled links removed from `docs/ecosystem.md` and two skills

### Security
- `godot-inventory-economy` — loading an inventory resolves item ids through a fixed table instead of building a `load()` path from save data

## [1.3.0] — 2026-11-19

### Added
- `godot-pck-encryption` — Encrypted PCK exports: key handling, building export templates with `SCRIPT_AES256_ENCRYPTION_KEY` for every platform, preset encryption settings, filters that match the names Godot actually stores (`*.gd`/`*.tscn` encrypt nothing by default), CLI export with `GODOT_SCRIPT_ENCRYPTION_KEY`, template and PCK verification, and 4.7 error messages

### Changed
- Agent instructions no longer commit or push automatically

## [1.2.1] — 2026-09-08

### Added
- `SECURITY.md` — Reporting process, MCP bridge threat model, and the Godot patterns treated as vulnerabilities here

### Removed
- Dangling `## References` sections from 20 skills — the linked files were never written. `scripts/verify.sh` now checks that reference links resolve instead of requiring a `references/` directory, so a skill may ship without one

### Fixed
- `scripts/new-skill.sh` — escape the description before using it as a `sed` replacement
- `godot-save-systems` — `Error.CANT_OPEN` corrected to `Error.ERR_FILE_CANT_OPEN`, which is the enum that actually exists
- `zod` declared explicitly instead of being hoisted from the MCP SDK as a phantom dependency

### Security
- MCP bridge validates every path-carrying RPC parameter in one place. `res://` is not a sandbox on its own: Godot resolves `res://../..` and absolute host paths outside the project
- MCP bridge sends `GODOT_MCP_TOKEN` in the connect handshake; `mcp-bridge/protocol.md` now requires token authentication and rejection of `Origin`-bearing (browser) connections, since localhost is a reachability limit rather than an authorization boundary
- `godot-save-systems` — replaced `ResourceLoader.load()` on `user://` saves with `store_var`/`get_var` at `allow_objects = false`. Loading a crafted `.tres` executes attached scripts, and the cloud-save section made that blob remote-controlled
- `godot-networking` — pickup scenes resolve through a fixed table instead of a load path built from RPC arguments

## [1.2.0] — 2026-08-25

### Added
- `godot-headless-workflow` — Agent-first development loop: headless validation/import gates, gdUnit4 CLI testing, text-scene editing safety rules, CLI export pipeline with Android/iOS presets and signing env vars, store-submission checklist, RevenueCat plugin integration playbook, and cross-platform notes for Windows/Linux hosts

## [1.1.0] — 2026-06-21

### Added
- Phase 4 skills: `godot-architecture`, `godot-state-management`, `godot-save-systems`, `godot-inventory-economy`, `godot-dialog-systems`, `godot-i18n`
- Phase 5 skills: `godot-audio`, `godot-shaders-vfx`, `godot-input`
- Phase 6 quality gates: `scripts/verify.sh`, `scripts/lint-skills.sh`, `scripts/check-agent-extensions.sh`, GitHub Actions CI
- Phase 7: project files (`project.godot`, scenes, scripts) for the three example projects
- `scripts/new-skill.sh` — Scaffold new skill directories from template
- `docs/skill-template/` — Copy-paste skill template (SKILL.md, agents/, references/)
- `docs/ecosystem.md` — Godot ecosystem integrations guide (20+ tools/plugins)
- `docs/release-process.md` — Release checklist, npm publish steps, rollback procedure
- `docs/changelog-guide.md` — Changelog format conventions and semver rules

### Changed
- Author references renamed from RoboCat to vl4dt

## [1.0.0] — 2026-06-20

### Added — Phase 1: Core Standalone Skills
- `godot-project-setup` — Project scaffolding with .gdignore, export presets, autoload setup
- `godot-brainstorming` — Architecture patterns, state machines, network architecture
- `godot-gdscript-patterns` — Node composition, typed signals, scene instantiation, singletons
- `godot-csharp-patterns` — Export attributes, signal handling, performance optimization
- `godot-code-review` — Performance checklist, anti-patterns, memory management
- `godot-debugging` — Output methods, profiler workflow, common error patterns
- `godot-47-migration` — Migration from Godot 4.x to 4.7

### Added — Phase 2: MCP Bridge
- MCP server (Node.js) with 25 tools across 6 categories (scene, script, project, runtime, file, visualization)
- Godot connector via WebSocket JSON-RPC 2.0
- Agent-specific MCP config templates (pi-agent, Claude Code, Cursor/Windsurf)
- Graceful degradation when editor is not running

### Added — Phase 3: Advanced Game Dev Domains
- `godot-physics` — Collision layers/masks, rigid body dynamics, character controllers, area triggers, physics interpolation
- `godot-animation` — AnimationPlayer vs AnimationTree, state machines, blend spaces (1D/2D/directional), root motion, tween_await()
- `godot-ui` — Control hierarchy, containers and layout modes, themes, RichTextLabel, PopupMenu search, control offset transforms (4.7)
- `godot-performance` — Profiling workflow, memory management, instancing/LOD, draw calls, mobile optimization, Perfetto tracing
- `godot-networking` — RPC system, authority models, replication patterns (rpc/rset/rset_group), lag compensation, Steam Frame

### Added — Package Infrastructure
- `package.json` with pi manifest (`pi.skills: ["skills/*"]`) and npm scoped name `@vl4dt/godot-skills`
- MIT License
- Cross-agent compatibility via Agent Skills Open Standard
- Agent-specific extensions (`agents/claude-code.yaml`, `agents/openai.yaml`) for all 12 skills
- `scripts/new-godot-project.sh` — POSIX shell project scaffolding
- `scripts/validate-gdscript.gd` — Headless GDScript syntax validator
- `scripts/validate-skills.sh` — Automated skill validation for CI
- 3 example projects (minimal-rpg, platformer-2d, multiplayer-lobby)

### Added — Documentation
- `README.md` — Full package documentation with skill table and installation guides
- `AGENTS.md` — Cross-agent installation guide for pi-agent, Claude Code, Codex CLI, Cline, Cursor/Windsurf, Gemini CLI, Kiro
- `docs/architecture.md` — 6 Architecture Decision Records
- `docs/migration-4.7.md` — Godot 4.7 migration checklist with code examples
- `docs/contributing.md` — Contributor guide with skill creation workflow
- `docs/cross-agent-testing.md` — Cross-agent testing documentation and checklist
- `mcp-bridge/README.md` — MCP bridge architecture and setup guide
- `mcp-bridge/protocol.md` — MCP protocol specification
- `mcp-bridge/tools.md` — MCP tools reference

### Godot 4.7 Feature Coverage
All 12 skills cover the following Godot 4.7 features where applicable:
- HDR output settings and configuration
- Steam Frame integration
- New AreaLight3D node support
- VirtualJoystick for mobile development
- `tween_await()` for animation sequences
- Collapsible animation tracks
- PopupMenu search functionality
- Control offset transforms for UI animation
- Perfetto tracing for Android profiling
- Nearest-neighbor viewport scaling
- DrawableTexture2D for dynamic textures

### Cross-Agent Compatibility
Designed and tested for:
- pi-agent (native via `package.json` manifest)
- Claude Code (via `.claude/skills/`)
- Codex CLI / OpenAI (via `.codex/skills/`)
- Cline (via `.cline/skills/`)
- Cursor / Windsurf (via `.cursorrules`)
- Gemini CLI (partial support)
- Kiro (emerging support)

---

## Versioning

This package follows [Semantic Versioning](https://semver.org/):
- **Major** — Breaking changes to skill format or API
- **Minor** — New skills, new features (backward compatible)
- **Patch** — Bug fixes, documentation updates
