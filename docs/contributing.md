# Contributing to godot-skills

Thank you for your interest in contributing! This document covers how to contribute skills, fix issues, and improve the package.

## Getting Started

### Prerequisites
- Godot 4.7 editor (for testing skill content accuracy)
- Basic understanding of the [Agent Skills Open Standard](https://agentskills.io/specification)
- Familiarity with pi-agent package conventions

### Setup
```bash
# Clone the repository
git clone https://github.com/Narmo/godot-skills.git
cd godot-skills

# Test skill loading in pi-agent (local)
pi --skill ./skills/godot-project-setup "Test skill loading"
```

## Adding a New Skill

### 1. Scaffold the skill
```bash
scripts/new-skill.sh godot-new-skill "Specific description of what this skill does and when to use it."
```

This copies `docs/skill-template/` to `skills/godot-new-skill/` with `SKILL.md`, `agents/claude-code.yaml`, `agents/openai.yaml` and `references/DETAIL.md`.

### 2. Fill in SKILL.md

The frontmatter must carry every field the checks require:

```markdown
---
name: godot-new-skill
description: "Specific description of what this skill does and when to use it."
license: MIT
compatibility:
  - godot-4.7
metadata:
  author: Your Name (handle)
  version: 0.1.0
  tags:
    - godot
  created: YYYY-MM-DD
---
```

`name` must be lowercase kebab-case, at most 64 characters, and match the directory name. List every Godot version the skill was checked against in `compatibility`.

### 3. Add references (if needed)

Put content that would push `SKILL.md` past 500 lines into `references/` and link it with a relative path. Delete `references/DETAIL.md` if the skill does not need it — every link in `SKILL.md` must resolve.

### 4. Test
```bash
bash scripts/verify.sh
pi --skill ./skills/godot-new-skill "Test skill loading"
```
- Check that the description triggers the skill for a realistic prompt
- Ensure relative paths work

## Skill Quality Checklist

- [ ] Frontmatter has `name`, `description`, `license`, `compatibility` and `metadata` (`author`, `version`, `tags`)
- [ ] Name is <=64 chars, lowercase kebab-case, and matches the directory name
- [ ] Description is specific and actionable (not "helps with Godot")
- [ ] SKILL.md body is under 500 lines
- [ ] `agents/claude-code.yaml` (trigger phrases) and `agents/openai.yaml` (Codex `interface` and `policy`) exist and carry the safety notice
- [ ] References are in `references/` and every relative link resolves
- [ ] Godot 4.7 features documented where applicable
- [ ] Cross-platform considerations noted (Windows paths, etc.)
- [ ] `bash scripts/verify.sh` passes

## Making Changes to Existing Skills

1. Fork the repository
2. Create a feature branch: `git checkout -b improve-godot-debugging`
3. Make your changes
4. Test locally with pi-agent
5. Submit a pull request

## Pull Request Guidelines

- Keep PRs focused (one skill or one topic per PR)
- Update relevant docs if changing patterns
- Include Godot 4.7 notes for new features covered
- Run `bash scripts/verify.sh` and `pi --skill ./skills/<skill-name> "Test"` to verify loading
