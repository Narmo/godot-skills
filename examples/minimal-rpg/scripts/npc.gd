## NPC that patrols between points and greets the player who comes close.
## Demonstrates: exported typed arrays, an enum state machine, and Area2D detection.
class_name NPC
extends CharacterBody2D

signal dialogue_started(npc_name: String, text: String)
signal dialogue_ended

enum State { PATROL, TALKING }

const SPEED := 40.0

@export var npc_name: String = "Merchant"
@export var dialogue_text: String = "Hello, adventurer!"
@export var patrol_points: Array[Vector2] = []

var _state: State = State.PATROL
var _point_index: int = 0

@onready var _talk_zone: Area2D = $TalkZone


func _ready() -> void:
	_talk_zone.body_entered.connect(_on_talk_zone_body_entered)
	_talk_zone.body_exited.connect(_on_talk_zone_body_exited)


func _physics_process(_delta: float) -> void:
	if _state != State.PATROL or patrol_points.is_empty():
		return
	var target := patrol_points[_point_index]
	if global_position.distance_to(target) < 4.0:
		_point_index = (_point_index + 1) % patrol_points.size()
		return
	velocity = global_position.direction_to(target) * SPEED
	move_and_slide()


func _on_talk_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		_state = State.TALKING
		dialogue_started.emit(npc_name, dialogue_text)


func _on_talk_zone_body_exited(body: Node2D) -> void:
	if body is Player:
		_state = State.PATROL
		dialogue_ended.emit()
