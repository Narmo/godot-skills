# ADR-006: Skill Naming Convention

**Status:** Accepted (revised 2026-11-19)  
**Date:** 2026-06-21

## Context
Skill names need to be discoverable, unique, and follow the Agent Skills standard.

## Decision
Prefix all skills with `godot-` for clear domain identification. Use kebab-case. Keep names under 64 characters. Each name matches its directory name — pi does not require it, but other Agent Skills implementations do, so matching names are the portable choice.

## Consequences
- **Pros:** Clear namespace, easy to discover, follows best practices
- **Cons:** Long names for compound skills
- **Alternatives considered:** No prefix (conflicts with other packages), domain-specific prefixes (godot-gdscript vs godot-patterns)
