## Lobby UI: host/join controls, the player list, and the ready button.
## Demonstrates: container layout, unique node names (%Name), and UI that only
## reacts to MultiplayerManager signals instead of reading network state.
extends Control

@export var manager: MultiplayerManager

@onready var _name_edit: LineEdit = %NameEdit
@onready var _address_edit: LineEdit = %AddressEdit
@onready var _host_button: Button = %HostButton
@onready var _join_button: Button = %JoinButton
@onready var _ready_button: Button = %ReadyButton
@onready var _leave_button: Button = %LeaveButton
@onready var _status_label: Label = %StatusLabel
@onready var _player_list: VBoxContainer = %PlayerList


func _ready() -> void:
	_host_button.pressed.connect(_on_host_pressed)
	_join_button.pressed.connect(_on_join_pressed)
	_ready_button.pressed.connect(manager.toggle_ready)
	_leave_button.pressed.connect(_on_leave_pressed)
	manager.players_updated.connect(_on_players_updated)
	manager.status_changed.connect(_on_status_changed)
	manager.game_started.connect(_on_game_started)
	_set_in_lobby(false)


func _on_host_pressed() -> void:
	var err := manager.host(_name_edit.text)
	if err != OK:
		_status_label.text = "Could not host: %s" % error_string(err)
		return
	_set_in_lobby(true)


func _on_join_pressed() -> void:
	var err := manager.join(_address_edit.text, _name_edit.text)
	if err != OK:
		_status_label.text = "Could not join: %s" % error_string(err)
		return
	_set_in_lobby(true)


func _on_leave_pressed() -> void:
	manager.leave()
	_set_in_lobby(false)


func _on_players_updated(players: Dictionary) -> void:
	for child in _player_list.get_children():
		child.queue_free()
	for id: int in players:
		var info: Dictionary = players[id]
		var label := Label.new()
		label.text = "%s%s" % [info["name"], "  (ready)" if info["ready"] else ""]
		_player_list.add_child(label)
	# An empty list means we just left; the peer may already be gone.
	var me: Dictionary = {} if players.is_empty() else players.get(multiplayer.get_unique_id(), {})
	_ready_button.text = "Not ready" if me.get("ready", false) else "Set ready"


func _on_status_changed(status: String) -> void:
	_status_label.text = status
	if status == "Disconnected" or status == "Connection failed" or status == "Host left the lobby":
		_set_in_lobby(false)


func _on_game_started() -> void:
	_ready_button.disabled = true


func _set_in_lobby(in_lobby: bool) -> void:
	_host_button.visible = not in_lobby
	_join_button.visible = not in_lobby
	_name_edit.editable = not in_lobby
	_address_edit.editable = not in_lobby
	_ready_button.visible = in_lobby
	_ready_button.disabled = false
	_leave_button.visible = in_lobby
