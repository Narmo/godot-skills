# Security Policy

## Reporting a Vulnerability

Report vulnerabilities privately through
[GitHub Security Advisories](https://github.com/Narmo/godot-skills/security/advisories/new).
Please do not open a public issue for a security problem.

Include what the issue is, how to reproduce it, and what an attacker gains. Expect
an initial response within a week.

## Scope

The skills and examples (`skills/`, `examples/`) are in scope: they are copied into real
games, so an insecure pattern documented here propagates downstream. Insecure guidance is
a vulnerability in this repository, not just a documentation bug.

## Known-Dangerous Godot Patterns

These come up repeatedly in game code and are treated as security bugs in this
repository:

- `ResourceLoader.load()` on any file the player or network can write (save games,
  downloaded content, mods). Loading a `.tres`/`.res` executes attached scripts.
  Use `FileAccess.store_var`/`get_var` with `allow_objects = false`, or JSON.
- `bytes_to_var(buf, true)` / `var_to_bytes_with_objects()` on untrusted input, for
  the same reason.
- Building a `load()` path out of RPC arguments or other remote input. Look the
  value up in a fixed table instead.
