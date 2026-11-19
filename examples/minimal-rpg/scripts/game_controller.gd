## Game controller: a two-state machine that pauses and resumes the game.
## Demonstrates: enum-based state, pausing the SceneTree, and process_mode.
## The node runs with process_mode = Always (set in main.tscn), so it still
## receives input while the rest of the tree is paused.
extends Node

signal state_changed(new_state: State)

enum State { PLAYING, PAUSED }

@export var pause_label: Label

var state: State = State.PLAYING


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_set_state(State.PAUSED if state == State.PLAYING else State.PLAYING)


func _set_state(new_state: State) -> void:
	state = new_state
	get_tree().paused = state == State.PAUSED
	if pause_label:
		pause_label.visible = state == State.PAUSED
	state_changed.emit(state)
