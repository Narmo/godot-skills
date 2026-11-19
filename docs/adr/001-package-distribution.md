# ADR-001: Package Distribution Model

**Status:** Accepted (revised 2026-11-19)  
**Date:** 2026-06-21

## Context
We need to distribute Godot development skills to 30+ coding agents through a single package.

## Decision
Distribute through git only. pi installs the repository with `pi install git:github.com/Narmo/godot-skills` and discovers skills from the conventional `skills/` directory; other agents copy or symlink `skills/`. Each skill is a self-contained directory with its own SKILL.md.

## Consequences
- **Pros:** One source of truth, no registry account or package manifest to maintain; releases are git tags
- **Cons:** No listing in the pi package gallery, which indexes npm packages only
- **History:** The earlier npm distribution is recorded in CHANGELOG.md
