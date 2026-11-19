## Smooth follow camera.
## Demonstrates: frame-rate independent smoothing with lerp() and Camera2D limits.
extends Camera2D

@export var target: Node2D
@export var smoothing_speed: float = 6.0
@export var vertical_offset: float = -60.0


func _ready() -> void:
	if target:
		global_position = target.global_position + Vector2(0.0, vertical_offset)


func _process(delta: float) -> void:
	if not target:
		return
	var goal := target.global_position + Vector2(0.0, vertical_offset)
	global_position = global_position.lerp(goal, 1.0 - exp(-smoothing_speed * delta))
