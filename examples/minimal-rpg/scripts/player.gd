## Player controller for the minimal RPG example.
## Demonstrates: top-down CharacterBody2D movement, collision layers set in the
## scene, and a typed signal the UI connects to through the "player" group.
class_name Player
extends CharacterBody2D

signal item_collected(item_name: String, quantity: int)

const SPEED := 160.0

@export var speed_multiplier: float = 1.0


func _physics_process(_delta: float) -> void:
	# The move_* actions come from the keyboard and from the on-screen
	# VirtualJoystick in the HUD (Godot 4.7+), so no joystick code is needed here.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * SPEED * speed_multiplier
	move_and_slide()


func collect(item_name: String, quantity: int) -> void:
	item_collected.emit(item_name, quantity)
