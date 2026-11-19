## Collectible item the player picks up by walking into it.
## Demonstrates: exported data, Area2D triggers, and collision masks.
class_name Collectible
extends Area2D

@export var item_name: String = "gem"
@export var quantity: int = 1

@onready var _label: Label = $Label


func _ready() -> void:
	_label.text = "%dx %s" % [quantity, item_name]
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player:
		player.collect(item_name, quantity)
		queue_free()
