## Multiplayer lobby manager.
## Demonstrates: ENetMultiplayerPeer, the high-level multiplayer API, @rpc
## annotations, and a server-authoritative lobby: clients only send requests,
## the server owns the player list and decides when the game starts.
class_name MultiplayerManager
extends Node

signal players_updated(players: Dictionary)
signal status_changed(status: String)
signal game_started

const SERVER_PORT := 8910
const MAX_PLAYERS := 4

## peer id -> {"name": String, "ready": bool}. Edited on the server only;
## clients receive a copy through _sync_players().
var players: Dictionary = {}

var _pending_name := ""


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host(player_name: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(SERVER_PORT, MAX_PLAYERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	players = {1: {"name": player_name, "ready": false}}
	players_updated.emit(players)
	status_changed.emit("Hosting on port %d" % SERVER_PORT)
	return OK


func join(address: String, player_name: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, SERVER_PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	_pending_name = player_name
	status_changed.emit("Connecting to %s..." % address)
	return OK


func leave() -> void:
	players.clear()
	players_updated.emit(players)
	multiplayer.multiplayer_peer = null
	status_changed.emit("Disconnected")


func toggle_ready() -> void:
	var me: Dictionary = players.get(multiplayer.get_unique_id(), {})
	_request_ready.rpc_id(1, not me.get("ready", false))


@rpc("any_peer", "reliable")
func _register(player_name: String) -> void:
	# Runs on the server when a client announces itself after connecting.
	if not multiplayer.is_server() or players.size() >= MAX_PLAYERS:
		return
	players[multiplayer.get_remote_sender_id()] = {"name": player_name, "ready": false}
	_sync_players.rpc(players)


@rpc("any_peer", "call_local", "reliable")
func _request_ready(is_ready: bool) -> void:
	# Runs on the server; "call_local" lets the host send it to itself.
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if not players.has(id):
		return
	players[id]["ready"] = is_ready
	_sync_players.rpc(players)
	if _all_ready():
		_start_game.rpc()


@rpc("authority", "call_local", "reliable")
func _sync_players(new_players: Dictionary) -> void:
	players = new_players
	players_updated.emit(players)


@rpc("authority", "call_local", "reliable")
func _start_game() -> void:
	status_changed.emit("Game starting!")
	game_started.emit()


func _all_ready() -> bool:
	if players.size() < 2:
		return false
	for info: Dictionary in players.values():
		if not info["ready"]:
			return false
	return true


func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server() and players.erase(id):
		_sync_players.rpc(players)


func _on_connected_to_server() -> void:
	status_changed.emit("Connected")
	_register.rpc_id(1, _pending_name)


func _on_connection_failed() -> void:
	leave()
	status_changed.emit("Connection failed")


func _on_server_disconnected() -> void:
	leave()
	status_changed.emit("Host left the lobby")
