---
name: godot-state-management
description: "State management patterns for Godot 4.x: enum-based state, finite state machines (FSM), hierarchical FSM, and behavior trees for AI. Use when implementing character states, game flow, menu systems, or AI decision-making in Godot."
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
    - state-machine
    - fsm
    - behavior-tree
    - ai
  created: 2026-06-21
---

# State Management in Godot

Patterns for managing game and entity states cleanly.

## Enum-Based State (Simple)

For straightforward state tracking without transitions:

```gdscript
class_name PlayerController extends CharacterBody2D

enum State { IDLE, RUNNING, JUMPING, FALLING, ATTACKING }

var current_state: State = State.IDLE

func _physics_process(delta: float) -> void:
    match current_state:
        State.IDLE:
            _handle_idle(delta)
        State.RUNNING:
            _handle_running(delta)
        State.JUMPING:
            _handle_jumping(delta)
        State.FALLING:
            _handle_falling(delta)
        State.ATTACKING:
            _handle_attacking(delta)

func set_state(new_state: State) -> void:
    if current_state == new_state:
        return
    current_state = new_state
```

## Finite State Machine (FSM)

For entities with defined transitions between states:

```gdscript
class_name FSM extends Node

signal state_entered(state_name: StringName)
signal state_exited(state_name: StringName)

var current_state: FSMState = null
var states: Dictionary = {}

func _ready() -> void:
    for child in get_children():
        if child is FSMState:
            states[child.name] = child
            child.fsm = self

func initialize(initial: StringName) -> void:
    if not states.has(initial):
        push_error("FSM: Initial state '%s' not found" % initial)
        return
    current_state = states[initial]
    current_state.enter()
    state_entered.emit(initial)

func change_state(new_state_name: StringName) -> void:
    if not states.has(new_state_name):
        push_error("FSM: State '%s' not found" % new_state_name)
        return
    if current_state:
        current_state.exit()
        state_exited.emit(current_state.name)
    current_state = states[new_state_name]
    current_state.enter()
    state_entered.emit(new_state_name)

func _process(delta: float) -> void:
    if current_state:
        current_state.update(delta)

func _unhandled_input(event: InputEvent) -> void:
    if current_state:
        current_state.handle_input(event)
```

### FSM State Base Class

```gdscript
class_name FSMState
extends Node

## Set by the FSM that owns this state.
var fsm: FSM


func enter() -> void:
    pass  # Override


func exit() -> void:
    pass  # Override


func update(_delta: float) -> void:
    pass  # Override


func handle_input(_event: InputEvent) -> void:
    pass  # Override


# Helper to transition from within a state
func transition_to(new_state: StringName) -> void:
    fsm.change_state(new_state)
```

### Concrete State Example

```gdscript
# enemy_idle.gd — a child node of the FSM
class_name EnemyIdle
extends FSMState

@export var idle_time: float = 2.0

var _timer: float = 0.0


func enter() -> void:
    _timer = 0.0


func update(delta: float) -> void:
    _timer += delta
    if _timer >= idle_time:
        transition_to(&"Patrol")
```

## Hierarchical State Machine

For nested states (e.g., combat has sub-states for melee/range):

```gdscript
class_name HierarchicalFSM extends Node

var current_parent: StringName = ""
var current_child: StringName = ""

# Parent states: "Exploring", "Combat", "Dead"
# Combat child states: "Melee", "Ranged", "Dodging"

func enter_state(parent: StringName, child: StringName) -> void:
    current_parent = parent
    current_child = child
```

### Hierarchical State Pattern

```gdscript
# PlayerCombatState.gd — parent state delegates to children
class_name PlayerCombatState extends FSMState

var sub_states: Dictionary = {}
var active_sub_state: StringName = ""

func enter() -> void:
    # Register sub-states from child nodes
    for child in get_children():
        if child is FSMState:
            sub_states[child.name] = child

func update(delta: float) -> void:
    # Choose sub-state based on context
    var new_sub_state = _determine_sub_state()
    if new_sub_state != active_sub_state:
        _switch_sub_state(new_sub_state)
    if sub_states.has(active_sub_state):
        sub_states[active_sub_state].update(delta)

func _determine_sub_state() -> StringName:
    # Example: switch based on weapon type or enemy distance
    return &"Melee"


func _switch_sub_state(new_sub_state: StringName) -> void:
    if sub_states.has(active_sub_state):
        sub_states[active_sub_state].exit()
    active_sub_state = new_sub_state
    if sub_states.has(active_sub_state):
        sub_states[active_sub_state].enter()
```

## Behavior Trees (AI)

For complex AI decision-making. Each node type is its own script (GDScript allows one
`class_name` per file); build the tree as child nodes in the editor.

```gdscript
# behavior_tree.gd
class_name BehaviorTree
extends Node

## Shared data between nodes, e.g. { "target": Node, "health": int, "last_seen_pos": Vector2 }
var blackboard: Dictionary = {}


func _physics_process(delta: float) -> void:
    var root := get_child(0) as BTNode
    if root:
        root.execute(blackboard, delta)
```

### BT Node Types

```gdscript
# bt_node.gd
class_name BTNode
extends Node

enum Status { SUCCESS, FAILURE, RUNNING }


func execute(_blackboard: Dictionary, _delta: float) -> Status:
    return Status.SUCCESS  # Override in subclasses
```

```gdscript
# bt_sequence.gd — succeeds when every child succeeds, stops at the first that doesn't
class_name BTSequence
extends BTNode


func execute(blackboard: Dictionary, delta: float) -> Status:
    for child in get_children():
        var node := child as BTNode
        if node:
            var result := node.execute(blackboard, delta)
            if result != Status.SUCCESS:
                return result
    return Status.SUCCESS
```

```gdscript
# bt_selector.gd — succeeds at the first child that succeeds
class_name BTSelector
extends BTNode


func execute(blackboard: Dictionary, delta: float) -> Status:
    for child in get_children():
        var node := child as BTNode
        if node:
            var result := node.execute(blackboard, delta)
            if result != Status.FAILURE:
                return result
    return Status.FAILURE
```

```gdscript
# bt_condition.gd — leaf: override check()
class_name BTCondition
extends BTNode


func check(_blackboard: Dictionary) -> bool:
    return true  # Override


func execute(blackboard: Dictionary, _delta: float) -> Status:
    return Status.SUCCESS if check(blackboard) else Status.FAILURE
```

```gdscript
# bt_action.gd — leaf: override do_action(); with a duration it stays RUNNING until done
class_name BTAction
extends BTNode

@export var duration: float = 0.0

var _elapsed: float = 0.0


func do_action(_blackboard: Dictionary) -> void:
    pass  # Override


func execute(blackboard: Dictionary, delta: float) -> Status:
    do_action(blackboard)
    if duration <= 0.0:
        return Status.SUCCESS
    _elapsed += delta
    if _elapsed < duration:
        return Status.RUNNING
    _elapsed = 0.0  # ready for the next run
    return Status.SUCCESS
```

## Godot 4.7 State Notes

- **`Tween.tween_await(signal)`** — a state's enter/exit animation can wait for a signal inside one tween
- **AnimationTree** — combine FSM logic with AnimationTree state machines for visual feedback
