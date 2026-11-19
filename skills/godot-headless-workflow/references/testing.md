# gdUnit4 Testing Deep Dive

Standardize every Godot project on [gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) — the
actively maintained test framework with a headless CLI runner built for CI and agents.

## Install

1. AssetLib → "gdUnit4" → Install (or add as git submodule under `addons/gdUnit4`)
2. Enable the addon in Project Settings → Plugins
3. Keep `addons/gdUnit4/` under version control with the project so agents on fresh clones can run tests

## Layout

```
tests/
├── unit/          # pure logic: score, economy, state machines
│   └── test_score_manager.gd
├── integration/   # scenes wired together
└── fixtures/      # test data (.tres)
reports/           # generated HTML/XML — .gitignore this
```

## Suite Conventions

```gdscript
# tests/unit/test_score_manager.gd
class_name TestScoreManager
extends GdUnitTestSuite

const ScoreManager := preload("res://scripts/core/score_manager.gd")

var _sm

func before_test() -> void:
	_sm = auto_free(ScoreManager.new())   # freed after each test

func test_add_score_increments() -> void:
	_sm.add(10)
	assert_int(_sm.score).is_equal(10)

func test_score_never_negative() -> void:
	_sm.add(-5)
	assert_int(_sm.score).is_equal(0)

# Runs once per entry in test_parameters
func test_addition_is_parameterized(a: int, b: int, expected: int, test_parameters := [
		[1, 2, 3],
		[5, 5, 10],
	]) -> void:
	_sm.add(a + b)
	assert_int(_sm.score).is_equal(expected)
```

Assertion helpers to know: `assert_int`, `assert_float`, `assert_str`, `assert_bool`,
`assert_that(expr)`, `assert_array`, `assert_dict`, `assert_object(obj).is_instanceof(...)`,
`assert_signal(emitter).is_emitted("name")` (after `monitor_signals(emitter)`). Full list in
the gdUnit4 docs.

## Async & Scene Tests

Await signals/frames inside tests — essential for scene-dependent logic:

```gdscript
func test_enemy_dies_after_hit() -> void:
	var enemy: Node = auto_free(load("res://scenes/entities/enemy.tscn").instantiate())
	add_child(enemy)                    # the test suite is a Node inside the running tree
	await get_tree().process_frame

	monitor_signals(enemy)
	enemy.take_damage(enemy.hp)
	await assert_signal(enemy).is_emitted("died")   # always await is_emitted()

# For whole scenes with simulated input, use scene_runner("res://scenes/main.tscn").
```

Keep rendering-dependent asserts out of headless runs: no pixel/screenshot checks in CI.

## Running From CLI

```bash
# The runner needs the Godot executable in GODOT_BIN
export GODOT_BIN=/path/to/godot

# everything under res://tests (--continue: run all tests instead of stopping at the first failure)
addons/gdUnit4/runtest.cmd -a res://tests --continue       # Windows
./addons/gdUnit4/runtest.sh -a res://tests --continue      # Linux/macOS

# one suite only
./addons/gdUnit4/runtest.sh -a res://tests/unit/test_score_manager.gd

# skip a suite or a single test
./addons/gdUnit4/runtest.sh -a res://tests -i test_score_manager:test_score_never_negative
```

- Without `--continue` the run stops at the first failure — handy for fast loops
- Exit code 0 = all passed; non-zero = failures → CI/agent gate safe
- Reports: `res://reports/` (HTML + XML/JUnit)
- Runner is headless by default when no display is available

## Agent Workflow Integration

1. Write the failing test FIRST when fixing a bug (reproduce via test, then fix)
2. Run only the touched suite while iterating (`-a path/to/suite.gd`), full suite before commit
3. If a test is flaky (async timing), fix the race condition — never delete the assertion
4. New feature ⇒ new suite; refactoring ⇒ tests unchanged, code changes

## Common Pitfalls

| Pitfall | Fix |
|---|---|
| Test class missing `class_name` / wrong base class | Must be `extends GdUnitTestSuite` + `class_name Test*` |
| Asserting inside awaited coroutines after timeout | Use `await assert_signal(...)` helpers, not manual timers |
| Scene loads but `_ready` errors | Run smoke test (`SKILL.md §Smoke run`) — it surfaces these |
| Tests pass alone, fail together | Suites sharing autoload state → reset in `before_test()` |
| Adding tests without enabling addon | `--import` + check plugin enabled in project.godot |
