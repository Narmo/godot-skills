## HUD overlay for score, lives, and short messages.
## Demonstrates: CanvasLayer UI, signal-driven updates, and tween-based fades.
## The HUD runs with process_mode = Always (set in main.tscn), so it still
## reads the restart key while the game is paused after Game Over.
extends CanvasLayer

var _score := 0
var _lives := 3
var _tween: Tween

@onready var _score_label: Label = $Margin/VBox/ScoreLabel
@onready var _lives_label: Label = $Margin/VBox/LivesLabel
@onready var _message_label: Label = $MessageLabel


func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.died.connect(_on_player_died)
		player.enemy_stomped.connect(_on_enemy_stomped)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if _lives <= 0 and event.is_action_pressed("ui_accept"):
		get_tree().paused = false
		get_tree().reload_current_scene()


func _on_enemy_stomped(points: int) -> void:
	_score += points
	_refresh()
	show_message("+%d" % points, 0.6)


func _on_player_died() -> void:
	_lives -= 1
	_refresh()
	if _lives > 0:
		show_message("Ouch!", 0.8)
		return
	if _tween:
		_tween.kill()
	_message_label.text = "Game Over - press Enter to restart"
	_message_label.modulate.a = 1.0
	_message_label.show()
	get_tree().paused = true


func show_message(text: String, duration: float) -> void:
	if _tween:
		_tween.kill()
	_message_label.text = text
	_message_label.modulate.a = 1.0
	_message_label.show()
	_tween = create_tween()
	_tween.tween_interval(duration)
	_tween.tween_property(_message_label, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(_message_label.hide)


func _refresh() -> void:
	_score_label.text = "Score: %d" % _score
	_lives_label.text = "Lives: %d" % _lives
