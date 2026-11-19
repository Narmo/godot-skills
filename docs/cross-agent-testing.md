# Cross-Agent Testing Documentation

This document describes how to test godot-skills across supported coding agents.

## Validation Checklist

Run the release gate before releasing a new version:

```bash
bash scripts/verify.sh          # or scripts/verify.ps1 on Windows
```

It runs `scripts/validate-skills.sh`, `scripts/lint-skills.sh` and `scripts/check-agent-extensions.sh` plus the structural checks. The tables below show what those scripts check, for debugging a failure by hand.

### 1. SKILL.md Standard Compliance

| Check | Command | Expected |
|-------|---------|----------|
| Every skill has a SKILL.md | `ls skills/*/SKILL.md` | One per skill directory |
| Required frontmatter | `grep -c '^name:\|^description:\|^license:\|^compatibility:\|^metadata:' skills/*/SKILL.md` | 5 per file |
| Progressive disclosure (<500 lines) | `wc -l skills/*/SKILL.md` | All <500 |
| Kebab-case naming | `ls skills/` | All match `godot-*`, and each `name:` matches its directory |

### 2. Agent-Specific Extensions

| Check | Command | Expected |
|-------|---------|----------|
| claude-code.yaml present | `ls skills/*/agents/claude-code.yaml` | One per skill |
| openai.yaml present | `ls skills/*/agents/openai.yaml` | One per skill |
| Safety notice present | `grep -rL 'Safely ignored by other agents' skills/*/agents/` | No output |

### 3. No Agent-Specific Leakage

| Check | Command | Expected |
|-------|---------|----------|
| No Python try/except in GDScript | `grep -rn '^\s*try:' --include='*.gd' skills/` | 0 results |
| No agent names in SKILL.md | `grep -rli 'claude-code\|openai\|codex' --include='SKILL.md' skills/` | 0 results |

### 4. Script References

| Check | Command | Expected |
|-------|---------|----------|
| new-godot-project.sh exists | `test -f scripts/new-godot-project.sh` | true |
| validate-gdscript.gd exists | `test -f scripts/validate-gdscript.gd` | true |
| References use relative paths | `grep 'scripts/' skills/*/SKILL.md` | Relative only |

## Per-Agent Testing Instructions

Claude Code, Codex CLI and Cline expect one directory per skill (`<skills-dir>/<skill-name>/SKILL.md`), so copy the *contents* of `skills/`.

### pi-agent

```bash
# Install from a local path into the current project
pi install ./path/to/godot-skills -l

# Confirm the package is configured
pi list

# Test each skill by description trigger
# e.g., prompt: "help me set up a new Godot project"
# Should trigger: godot-project-setup (force it with /skill:godot-project-setup)
```

### Claude Code

```bash
mkdir -p ~/.claude/skills && cp -R /path/to/godot-skills/skills/. ~/.claude/skills/
ls ~/.claude/skills/godot-*/SKILL.md

# Test with a prompt like: "I want to design game architecture for an RPG"
```

### Codex CLI (OpenAI)

```bash
mkdir -p ~/.agents/skills && cp -R /path/to/godot-skills/skills/. ~/.agents/skills/
ls ~/.agents/skills/godot-*/SKILL.md

# Test with a prompt like: "help me debug a Godot error"
```

### Cline

```bash
mkdir -p ~/.cline/skills && cp -R /path/to/godot-skills/skills/. ~/.cline/skills/
ls ~/.cline/skills/godot-*/SKILL.md
```

### Cursor / Windsurf

These agents use `.cursorrules` or `.windsurfrules`. Test by:

1. Adding the example rules from `AGENTS.md` to your project's `.cursorrules`
2. Opening a Godot project in Cursor/Windsurf
3. Prompting with skill-relevant queries

## Description Trigger Matrix

Taken from each skill's `agents/claude-code.yaml`:

| Skill | Trigger Phrase Examples |
|-------|------------------------|
| godot-47-migration | "migrating to Godot 4.7", "Godot version upgrade", "breaking changes in Godot 4.7" |
| godot-animation | "animation systems in Godot", "Godot AnimationTree and state machines", "Godot blend spaces" |
| godot-architecture | "designing Godot game architecture", "Godot scene composition patterns", "ECS patterns in Godot" |
| godot-audio | "implementing audio in Godot", "Godot sound effects", "audio bus mixing Godot" |
| godot-brainstorming | "designing Godot game architecture", "Godot scene organization", "Godot state machine patterns" |
| godot-code-review | "reviewing Godot code", "Godot performance checklist", "Godot memory leak detection" |
| godot-csharp-patterns | "writing C# code in Godot", "Godot Mono / C# patterns", "Export attributes in Godot" |
| godot-debugging | "debugging Godot errors", "profiling Godot performance", "resolving Godot crashes" |
| godot-dialog-systems | "building dialogue systems in Godot", "Godot branching narrative", "NPC conversation Godot" |
| godot-gdscript-patterns | "writing GDScript code", "Godot signals and events", "node composition in Godot" |
| godot-headless-workflow | "building or modifying a Godot game from a coding agent", "validating GDScript changes without opening the editor", "running Godot tests in CI" |
| godot-i18n | "localizing Godot games", "Godot translation system", "i18n Godot patterns" |
| godot-input | "implementing input in Godot", "Godot gamepad support", "input remapping Godot" |
| godot-inventory-economy | "building inventory systems in Godot", "Godot item management", "game economy Godot" |
| godot-networking | "networking and multiplayer in Godot", "Godot RPC system and replication", "Godot server-authoritative games" |
| godot-pck-encryption | "encrypting a Godot export PCK", "compiling Godot export templates with an encryption key", "setting SCRIPT_AES256_ENCRYPTION_KEY or GODOT_SCRIPT_ENCRYPTION_KEY" |
| godot-performance | "performance optimization in Godot", "Godot profiling and benchmarking", "Godot draw call reduction" |
| godot-physics | "physics systems in Godot", "Godot collision layers and masks", "Godot rigid body dynamics" |
| godot-project-setup | "creating a new Godot project", "setting up Godot project structure", "Godot export presets" |
| godot-save-systems | "implementing save systems in Godot", "Godot persistence patterns", "save file serialization Godot" |
| godot-shaders-vfx | "writing shaders in Godot", "Godot visual effects", "particle systems Godot" |
| godot-state-management | "implementing state machines in Godot", "Godot FSM patterns", "behavior trees Godot AI" |
| godot-ui | "UI development in Godot", "Godot Control nodes and containers", "Godot custom themes and styling" |

## Release Checklist

- [ ] `bash scripts/verify.sh` passes
- [ ] Every new or changed skill loads in pi (`pi --skill ./skills/<skill-name> "Test"`)
- [ ] README skill table lists every directory in `skills/`
- [ ] CHANGELOG `[Unreleased]` covers the release
- [ ] LICENSE is MIT

## Known Limitations

- Gemini CLI and Kiro have partial/unknown support — test manually
- Cursor/Windsurf require manual `.cursorrules` configuration
- `agents/openai.yaml` uses Codex's format (`interface`, `policy`); `agents/claude-code.yaml` uses this repository's own format and is not read by Claude Code or pi. Strict-mode agents may warn about unknown config
