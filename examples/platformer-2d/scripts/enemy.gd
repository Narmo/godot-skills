## Patrol enemy that walks back and forth and can be stomped.
## Demonstrates: CharacterBody2D gravity, patrol bounds, and wall detection.
class_name Enemy
extends CharacterBody2D

const GRAVITY := 980.0
const SPEED := 60.0

@export var patrol_distance: float = 100.0

var _start_x: float
var _direction := 1.0


func _ready() -> void:
	_start_x = global_position.x


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta

	# Turn around at the patrol bounds, or when a wall blocks the way.
	var offset := global_position.x - _start_x
	var past_bounds := (offset >= patrol_distance and _direction > 0.0) \
			or (offset <= -patrol_distance and _direction < 0.0)
	var blocked := is_on_wall() and signf(get_wall_normal().x) == -_direction
	if past_bounds or blocked:
		_direction = -_direction

	velocity.x = _direction * SPEED
	move_and_slide()


func defeat() -> void:
	queue_free()
