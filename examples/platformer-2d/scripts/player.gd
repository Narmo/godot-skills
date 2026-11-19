## Platformer player controller.
## Demonstrates: CharacterBody2D gravity and jumping, jump buffering, coyote
## time, and an Area2D hitbox for stomping enemies and touching hazards.
class_name Player
extends CharacterBody2D

signal died
signal enemy_stomped(points: int)

const GRAVITY := 980.0
const MOVE_SPEED := 200.0
const JUMP_VELOCITY := -420.0
const STOMP_BOUNCE := -300.0
const JUMP_BUFFER_TIME := 0.1
const COYOTE_TIME := 0.1

var _jump_buffer := 0.0
var _coyote := 0.0
var _spawn_position: Vector2

@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	_spawn_position = global_position
	_hitbox.body_entered.connect(_on_hitbox_body_entered)


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta

	# Coyote time: a jump still counts for a moment after walking off a ledge.
	_coyote = COYOTE_TIME if is_on_floor() else maxf(_coyote - delta, 0.0)
	# Jump buffering: a jump pressed shortly before landing is not lost.
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER_TIME
	else:
		_jump_buffer = maxf(_jump_buffer - delta, 0.0)

	if _jump_buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer = 0.0
		_coyote = 0.0

	# move_* and jump come from the keyboard and from the on-screen
	# VirtualJoystick in the HUD (Godot 4.7+).
	velocity.x = Input.get_axis("move_left", "move_right") * MOVE_SPEED
	move_and_slide()


func _on_hitbox_body_entered(body: Node2D) -> void:
	var enemy := body as Enemy
	if enemy:
		# Falling onto an enemy from above defeats it; any other contact hurts.
		if velocity.y > 0.0 and global_position.y < enemy.global_position.y:
			enemy.defeat()
			velocity.y = STOMP_BOUNCE
			enemy_stomped.emit(100)
		else:
			_die()
	elif body.is_in_group("hazard"):
		_die()


func _die() -> void:
	died.emit()
	global_position = _spawn_position
	velocity = Vector2.ZERO
