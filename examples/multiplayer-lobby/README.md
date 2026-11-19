# Multiplayer Lobby Example

A multiplayer lobby demonstrating Godot 4.x networking patterns.

## Skills Demonstrated

| Skill | Pattern | File |
|-------|---------|------|
| [networking](../../skills/godot-networking/SKILL.md) | ENetMultiplayerPeer, `@rpc` annotations, server-authoritative lobby | `scripts/multiplayer_manager.gd` |
| [ui](../../skills/godot-ui/SKILL.md) | Container layout, unique node names (`%Name`), signal-driven UI | `scripts/lobby_ui.gd` |
| [gdscript-patterns](../../skills/godot-gdscript-patterns/SKILL.md) | Typed signals, `class_name`, exported node references | All scripts |

## How to Run

1. Open this folder in Godot 4.7+ and press **F5** — click **Host**
2. Start a second instance from a terminal: `godot --path examples/multiplayer-lobby`
3. In the second window keep the address `127.0.0.1` and click **Join**
4. Both players click **Set ready**; the host starts the game once everyone is ready

> **Note:** The address field defaults to `127.0.0.1`. For play over a network, enter the host's IP and allow UDP port 8910 through its firewall.

## Project Structure

```
multiplayer-lobby/
├── project.godot               # Project config
├── scenes/
│   └── main.tscn               # Manager node and lobby UI
└── scripts/
    ├── multiplayer_manager.gd  # Peer lifecycle, RPCs, player list
    └── lobby_ui.gd             # Host/join controls, player list, ready button
```

## Key Patterns

### Clients Request, the Server Decides (networking)
```gdscript
@rpc("any_peer", "call_local", "reliable")
func _request_ready(is_ready: bool) -> void:
    if not multiplayer.is_server():
        return
    var id := multiplayer.get_remote_sender_id()
    players[id]["ready"] = is_ready
    _sync_players.rpc(players)
    if _all_ready():
        _start_game.rpc()
```

### Server-Owned State Broadcast (networking)
```gdscript
@rpc("authority", "call_local", "reliable")
func _sync_players(new_players: Dictionary) -> void:
    players = new_players
    players_updated.emit(players)
```

### ENet Peer Setup (networking)
```gdscript
var peer := ENetMultiplayerPeer.new()
peer.create_server(SERVER_PORT, MAX_PLAYERS)  # host
# or
peer.create_client(address, SERVER_PORT)      # client
multiplayer.multiplayer_peer = peer
```

## Networking Architecture

This example uses Godot's built-in **high-level multiplayer API**:

1. The **host** creates an `ENetMultiplayerPeer` server and owns the player list
2. **Clients** connect, then announce their name to the server with `_register.rpc_id(1, name)`
3. Ready toggles are **requests** to the server; it validates them and broadcasts the updated list with `_sync_players.rpc()`
4. The server starts the game when at least two players are connected and all are ready

## Notes

- Uses Godot's built-in ENet transport (no external dependencies)
- Up to 4 players (`MAX_PLAYERS`)
- Disconnects are handled on both sides: the server drops leaving peers, clients return to the menu when the host leaves
