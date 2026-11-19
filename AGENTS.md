# Cross-Agent Usage Guide

This document explains how to use godot-skills across different coding agents.

## How Skills Work Across Agents

All skills follow the [Agent Skills Open Standard](https://agentskills.io/specification):

1. **SKILL.md** is the universal entry point — every agent that supports skills uses this file
2. **Progressive disclosure** means only the skill name and description appear in the system prompt; the full SKILL.md loads on-demand when the agent detects a relevant task
3. **Relative paths** from the skill directory work across all agents for scripts, references, and assets

## Working on This Repository

The repository is a git-distributed pi package: the skills in `skills/` and example Godot projects in `examples/`. The layout is in [README.md](README.md#package-structure), history in [CHANGELOG.md](CHANGELOG.md), design decisions in [docs/architecture.md](docs/architecture.md), and the contributor workflow in [docs/contributing.md](docs/contributing.md).

Every change keeps these rules:

1. **SKILL.md stays under 500 lines** — longer material goes to `references/`
2. **No agent-specific content in SKILL.md** — it belongs in `agents/` (see [Agent-Specific Extensions](#agent-specific-extensions))
3. **Every skill has `agents/claude-code.yaml` and `agents/openai.yaml`**, both carrying the "Safely ignored by other agents" notice
4. **Godot 4.7 is the primary target**; each skill lists the versions it was checked against in `compatibility` (see [Version Compatibility](#version-compatibility))
5. **Scripts are POSIX shell with `.ps1` variants** for Windows; GDScript paths always use forward slashes
6. **`bash scripts/verify.sh` is the release gate** and must pass

Skills are plain documentation with no runtime dependencies.

## Agent-Specific Setup

### pi-agent (Recommended)
```bash
pi install git:github.com/Narmo/godot-skills
# Skills auto-discover from ~/.pi/agent/git/github.com/Narmo/godot-skills/skills/
```

Claude Code, Codex CLI and Cline expect one directory per skill (`<skills-dir>/<skill-name>/SKILL.md`), so copy the *contents* of `skills/`, not the directory itself.

### Claude Code
```bash
mkdir -p ~/.claude/skills && cp -R ./skills/. ~/.claude/skills/
# Or symlink each skill for development:
for d in /path/to/godot-skills/skills/*/; do ln -s "$d" ~/.claude/skills/; done
```
Claude Code reads only `SKILL.md` (its frontmatter can grant tools via `allowed-tools`); it does not read `agents/claude-code.yaml`.

### Codex CLI (OpenAI)
```bash
mkdir -p ~/.agents/skills && cp -R ./skills/. ~/.agents/skills/
```
Codex reads user skills from `~/.agents/skills/` and repository skills from `.agents/skills/`.

### Cline
```bash
mkdir -p ~/.cline/skills && cp -R ./skills/. ~/.cline/skills/
```

### Cursor / Windsurf
These agents use `.cursorrules` or `.windsurfrules` primarily. To use these skills:
1. Reference specific skill content in your `.cursorrules` file
2. Use the skill descriptions as trigger phrases in rules

Example `.cursorrules` addition:
```markdown
When working with Godot game development, follow patterns from godot-skills.
For project setup, use godot-project-setup patterns.
For GDScript code, follow godot-gdscript-patterns guidelines.
```

### Gemini CLI / Kiro
Partial support — copy skills directory to the agent's skills folder and test manually.

## Agent-Specific Extensions

Each skill may include an `agents/` subdirectory with agent-specific configuration:

```
skills/godot-project-setup/
├── SKILL.md              # Universal skill instructions
└── agents/
    ├── claude-code.yaml  # Trigger phrases and tool needs (repository format)
    └── openai.yaml       # Codex metadata: interface (display name, short description) and policy
```

These files are **safely ignored** by agents that don't recognize them. `openai.yaml` uses Codex's own format — `interface` for the name and description shown in Codex and the ChatGPT desktop app, `policy.allow_implicit_invocation` for automatic triggering. `claude-code.yaml` uses this repository's own format (`when_to_use` phrases, `tool_permissions`); Claude Code and pi do not read it, and it feeds the trigger matrix in [docs/cross-agent-testing.md](docs/cross-agent-testing.md).

## Troubleshooting

### Skills not loading
1. Verify the skills directory is in your agent's discovery path
2. Check that each skill has a valid SKILL.md with name and description frontmatter
3. Ensure SKILL.md names use lowercase kebab-case and match the directory name (e.g., `godot-project-setup`)

### Description not triggering
1. Make sure descriptions are specific enough (avoid vague phrases like "helps with Godot")
2. Check the skill's description matches the prompt language your agent uses
3. Try invoking explicitly: `/skill:godot-project-setup` (pi-agent) or equivalent for your agent

### Godot not found
- All skills assume Godot 4.x is installed and in PATH

## Version Compatibility

| Skill Version | Godot Version | Notes |
|--------------|---------------|-------|
| 0.1.0 | 4.0 - 4.7 | Targets Godot 4.7 features. Some skills need newer engines: `godot-headless-workflow` 4.2+, `godot-pck-encryption` 4.7 — see each skill's `compatibility` list |
| TBD | 5.0+ | Future compatibility updates |

## Cross-Agent Testing

See [docs/cross-agent-testing.md](docs/cross-agent-testing.md) for the full testing checklist, per-agent instructions, and description trigger matrix.

## Reporting Issues

Report compatibility issues at: https://github.com/Narmo/godot-skills/issues

Include:
- Agent name and version
- SKILL.md that isn't loading or triggering correctly
- Error messages or unexpected behavior
