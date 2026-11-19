---
name: godot-networking
description: "Networking and multiplayer for Godot 4.x: high-level multiplayer API with @rpc annotations, authority models (server-authoritative vs client-predictive), state replication with MultiplayerSynchronizer and MultiplayerSpawner, connection management, and lag compensation. Use when building multiplayer games, networked simulations, or online features in Godot."
license: MIT
compatibility:
  - godot-4.0
  - godot-4.1
  - godot-4.2
  - godot-4.3
  - godot-4.4
  - godot-4.5
  - godot-4.6
  - godot-4.7
metadata:
  author: vl4dt
  version: 0.1.0
  tags:
    - godot
    - networking
    - multiplayer
    - rpc
    - replication
  created: 2026-06-20
---

# Networking and Multiplayer for Godot 4.x

Patterns for multiplayer, RPC communication, and network synchronization with Godot 4's
high-level multiplayer API. The runnable `examples/multiplayer-lobby` project uses them.

## Multiplayer API Basics

### Setting Up a Peer

```gdscript
const PORT := 9000
const MAX_PLAYERS := 16


func host() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_PLAYERS)
	if err == OK:
		multiplayer.multiplayer_peer = peer  # the server's peer id is always 1
	return err


func join(address: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, PORT)
	if err == OK:
		multiplayer.multiplayer_peer = peer  # connected_to_server fires once the handshake is done
	return err


func leave() -> void:
	multiplayer.multiplayer_peer = null
```

### RPC Annotations

`@rpc(mode, sync, transfer_mode, transfer_channel)` — arguments may come in any order:

| Argument | Values | Meaning |
|----------|--------|---------|
| mode | `"authority"` (default), `"any_peer"` | Who may call it: only the node's multiplayer authority, or any peer |
| sync | `"call_remote"` (default), `"call_local"` | Whether the call also runs on the caller |
| transfer_mode | `"reliable"`, `"unreliable"` (default), `"unreliable_ordered"` | Delivery guarantee |
| transfer_channel | integer (default `0`) | Separate ordering channel |

```gdscript
# Only the authority (here: the server) may broadcast damage results.
@rpc("authority", "call_local", "reliable")
func apply_damage(amount: int) -> void:
	health -= amount


# Frequent, loss-tolerant updates.
@rpc("authority", "unreliable_ordered")
func sync_transform(new_position: Vector3, new_yaw: float) -> void:
	global_position = new_position
	rotation.y = new_yaw
```

### Calling RPCs

```gdscript
apply_damage.rpc(10)          # every peer (plus the caller with "call_local")
apply_damage.rpc_id(1, 10)    # one peer by id; 1 is always the server
rpc("apply_damage", 10)       # string form, same effect as apply_damage.rpc(10)
```

Inside an RPC, `multiplayer.get_remote_sender_id()` tells you who called it. Arguments must be
plain data — objects are not sent unless you enable object decoding, so pass values, not
`InputEvent` instances.

## Authority Models

### Server-Authoritative Model

The server has final say on all game state. Clients send inputs, the server validates them and
replicates the result.

```gdscript
class_name ServerAuthPlayer
extends CharacterBody3D

const SPEED := 5.0


func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server():
		# Clients only report intent; the server owns the movement.
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		submit_input.rpc_id(1, input)


@rpc("any_peer", "unreliable_ordered")
func submit_input(input: Vector2) -> void:
	if not multiplayer.is_server():
		return
	# Validate before applying: clamp the vector so a modified client cannot speed-hack.
	var direction := input.limit_length(1.0)
	velocity = Vector3(direction.x, 0.0, direction.y) * SPEED
	move_and_slide()
```

### Client-Predictive Model

Clients apply their own input immediately and reconcile when the server's state arrives.

```gdscript
class_name PredictedPlayer
extends CharacterBody3D

var _pending_inputs: Array[Dictionary] = []
var _sequence := 0


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	_sequence += 1
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_pending_inputs.append({"seq": _sequence, "input": input})
	_apply_input(input, delta)  # predict locally
	submit_input.rpc_id(1, _sequence, input)


@rpc("authority", "unreliable_ordered")
func server_state(last_seq: int, server_position: Vector3) -> void:
	# Snap to the server's answer, then replay inputs it has not seen yet.
	global_position = server_position
	_pending_inputs = _pending_inputs.filter(func(entry: Dictionary) -> bool: return entry["seq"] > last_seq)
	for entry in _pending_inputs:
		_apply_input(entry["input"], get_physics_process_delta_time())


@rpc("any_peer", "unreliable_ordered")
func submit_input(_seq: int, _input: Vector2) -> void:
	pass  # the server simulates and answers with server_state.rpc_id(sender, ...)


func _apply_input(input: Vector2, delta: float) -> void:
	global_position += Vector3(input.x, 0.0, input.y) * 5.0 * delta
```

### When to Use Which

| Model | Best For |
|-------|----------|
| Server-authoritative | Competitive games, anti-cheat priority |
| Client-predictive | Fast-paced action, smooth feel priority |
| Hybrid (recommended) | Most multiplayer games: predict the local player, trust the server |

## State Replication

Godot 4 has no `rset()`; property replication is done by nodes.

### MultiplayerSynchronizer

Add a `MultiplayerSynchronizer` as a child of the replicated node and list the properties in its
**Replication** panel, or configure it in code:

```gdscript
func _ready() -> void:
	var sync := MultiplayerSynchronizer.new()
	sync.root_path = NodePath("..")
	var config := SceneReplicationConfig.new()
	config.add_property(NodePath(".:position"))
	config.property_set_replication_mode(NodePath(".:position"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	config.add_property(NodePath(".:health"))
	config.property_set_replication_mode(NodePath(".:health"), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	sync.replication_config = config
	add_child(sync)
```

The synchronizer sends from the node's multiplayer authority to everyone else. Give each player
node its owner's peer id with `set_multiplayer_authority(peer_id)` when it spawns.

### MultiplayerSpawner

A `MultiplayerSpawner` replicates `add_child()`/`queue_free()` of listed scenes from the server
to all clients:

```gdscript
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner


func _ready() -> void:
	spawner.spawn_path = NodePath("../Players")
	spawner.add_spawnable_scene("res://scenes/player.tscn")
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_spawn_player)


func _spawn_player(peer_id: int) -> void:
	var player := preload("res://scenes/player.tscn").instantiate()
	player.name = str(peer_id)  # same name on every peer keeps node paths in sync
	get_node("../Players").add_child(player)
```

### Never Trust RPC Arguments

```gdscript
const PICKUP_SCENES := {
	"health": preload("res://scenes/pickups/health.tscn"),
	"ammo": preload("res://scenes/pickups/ammo.tscn"),
}


@rpc("authority", "call_local", "reliable")
func spawn_pickup(pickup_type: String, at: Vector3) -> void:
	# Never build a load path from RPC arguments: the sender controls that string
	# and would choose which resource you load. Look it up in a fixed table.
	if not PICKUP_SCENES.has(pickup_type):
		push_warning("Rejected unknown pickup type: %s" % pickup_type)
		return
	var pickup: Node3D = PICKUP_SCENES[pickup_type].instantiate()
	pickup.position = at
	get_tree().current_scene.add_child(pickup)
```

## Connection Management

### Networked Autoload

```gdscript
# network_manager.gd (autoload "Network")
extends Node

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)

var players: Dictionary[int, String] = {}


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(func() -> void: print("Connected as ", multiplayer.get_unique_id()))
	multiplayer.connection_failed.connect(func() -> void: multiplayer.multiplayer_peer = null)
	multiplayer.server_disconnected.connect(func() -> void: multiplayer.multiplayer_peer = null)


func _on_peer_connected(peer_id: int) -> void:
	players[peer_id] = "Player %d" % peer_id
	player_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	players.erase(peer_id)
	player_disconnected.emit(peer_id)
```

Wait for `connected_to_server` instead of a timer — connection time depends on the network.

### Lag Compensation

```gdscript
# Keep recent positions so the server can rewind hit checks to what the shooter saw.
class_name PositionHistory
extends Node3D

@export var history_seconds: float = 1.0

var _history: Array[Dictionary] = []


func _physics_process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	_history.push_back({"position": global_position, "time": now})
	var cutoff := now - int(history_seconds * 1000.0)
	while not _history.is_empty() and _history[0]["time"] < cutoff:
		_history.pop_front()


func get_position_at(time_ms: int) -> Vector3:
	for entry in _history:
		if entry["time"] >= time_ms:
			return entry["position"]
	return global_position
```

## Best Practices

### Do
- Use unreliable or `unreliable_ordered` RPCs for frequent position updates — saves bandwidth
- Validate all client input on the server before applying it
- Keep RPC payloads small — send only what changed
- Guard server-only code with `multiplayer.is_server()`
- Set `set_multiplayer_authority()` on every node a client controls

### Don't
- Don't call RPCs every frame without throttling — floods the network
- Don't trust client-reported health/damage — always recalculate server-side
- Don't send full state snapshots every frame — replicate on change
- Don't pass objects (`InputEvent`, `Resource`) as RPC arguments — send plain values
- Don't build resource paths from RPC arguments (see above)

### Debugging
- The editor's **Debugger → Network Profiler** shows RPC and synchronizer traffic per node
- Run several instances locally with **Debug → Customize Run Instances**, or start extra processes with `godot --path <project>`
- Log peers as they come and go:

```gdscript
multiplayer.peer_connected.connect(func(id: int) -> void: print("Peer connected: ", id))
multiplayer.peer_disconnected.connect(func(id: int) -> void: print("Peer disconnected: ", id))
```

Steam lobbies and Steam networking are not part of Godot; they come from the third-party
GodotSteam add-on.
