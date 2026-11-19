---
name: godot-debugging
description: "Debugging workflow for Godot 4.x: print vs push_error, editor output window, debugger panel, profiling with built-in profiler, network debugging, export/build troubleshooting. Use when debugging Godot games or resolving Godot-specific errors."
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
    - debugging
    - profiling
    - error-handling
  created: 2026-06-20
---

# Godot Debugging Guide

Comprehensive debugging workflow and common issue resolution for Godot 4.x.

## Output Methods

### print() vs push_error() vs push_warning()

```gdscript
# print() — General output in the Output panel
print("Debug: position = ", position)

# Formatting
print("Player %s has %d health" % [player_name, health])
prints("pos", position, "vel", velocity)   # space-separated
print_rich("[color=yellow]Highlighted[/color]")

# push_error() — Red in the Output panel and listed in Debugger > Errors with a stack trace
push_error("Failed to load resource: ", resource_path)

# push_warning() — Yellow, non-fatal issues
push_warning("Missing animation for state: ", state)

# load() returns null on failure — check before use
var data := load(risky_path)
if data == null:
    push_error("Could not load resource at: %s" % risky_path)

# ResourceLoader.exists() checks first without logging an error
if not ResourceLoader.exists(risky_path):
    push_warning("Optional resource missing: %s" % risky_path)
```

### Output Panel

The **Output** tab of the editor's bottom panel shows:
- Standard print output
- Warnings (yellow) and errors (red) with file/line info — click to jump to the line
- A filter box and toggles per message type

## Debugger Panel

### Built-in Debugger Features

The **Debugger** tab of the bottom panel, while a game runs from the editor:

1. **Stack Trace** — call stack and local variables when execution stops at a breakpoint or error
2. **Errors** — every error and warning with its stack trace
3. **Profiler** — time per script function
4. **Visual Profiler** — CPU and GPU time per rendering step
5. **Monitors** — FPS, memory, objects, draw calls over time
6. **Video RAM** — textures and other resources by memory use
7. **Network Profiler** — multiplayer traffic

### Remote Scene Tree

While the game runs, the Scene dock shows a **Remote** tab with the live scene tree. Select a
node there to inspect and edit its properties in the Inspector at runtime.

## Profiling Workflow

### CPU Profiler

Debugger > **Profiler** > Start, play the slow part, then Stop.

Key metrics:
- **Frame time** — Should be under 16.67ms for 60fps
- **Physics frame time** — Should fit the physics tick (16.67ms at 60 Hz)
- **Script functions** — time spent in your GDScript/C# code
- **Draw calls** — Monitors > Rendering

### Memory

Debugger > **Monitors** (Memory and Object sections) and **Video RAM**. Check for:
- Object or node counts that keep growing over time
- Scene instances that are never freed (orphan nodes: `print_orphan_nodes()`)
- Large textures that stay loaded

### GPU Profiler

Debugger > **Visual Profiler** > Start — shows CPU and GPU time for each rendering step.

## Common Error Patterns & Fixes

Messages as Godot 4.7 prints them:

### `Invalid call. Nonexistent function 'foo' in base 'Nil'.`
- **Cause:** Calling a method on a variable that is `null`
- **Fix:** Check where the value comes from (`get_node_or_null()`, `load()`, a missing `@export` assignment)

### `Node not found: "Missing" (relative to "/root/M").`
- **Cause:** `$Path` / `get_node()` points at a node that doesn't exist (renamed, moved, not instanced yet)
- **Fix:** Use `%UniqueName` or `@export var node: NodeType`, and don't access children before `_ready()`

### `Invalid access to property or key 'x' on a base object of type 'Timer'.`
- **Cause:** Accessing a property that doesn't exist on that object
- **Fix:** Check the node type and available properties; guard with `is` or `has_method()`

### `Attempt to connect nonexistent signal 'x' to callable '...'.`
- **Cause:** Signal name typo, or the signal is declared on a different node
- **Fix:** Use signal objects (`button.pressed.connect(...)`) — typos then fail at parse time

### `Attempt to call function 'instantiate' in base 'null instance' on a null instance.`
- **Cause:** `load()` failed (it logs `Cannot open file` first) and the result was used anyway
- **Fix:** Check the path and the return value

### Export/Build Errors

| Error | Cause | Fix |
|-------|-------|-----|
| No export template found | Templates not installed for this exact engine version | Editor > Manage Export Templates > Download and Install |
| Android export: SDK/keystore errors | SDK path or debug keystore not set | Editor Settings > Export > Android |
| Web export runs but stays black | Opened from `file://` | Serve over HTTP (the editor's Remote Debug > Run in Browser does this) |
| Windows icon or file info missing | `rcedit` not configured | Editor Settings > Export > Windows > rcedit |

## Network Debugging

### Multiplayer API Inspection

```gdscript
# Check connection status
var status := multiplayer.multiplayer_peer.get_connection_status()
print("Connected: ", status == MultiplayerPeer.CONNECTION_CONNECTED)
print("Peers: ", multiplayer.get_peers())

# Round-trip time to the server (ENet, on a client)
var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
if enet:
    var server := enet.get_peer(1)
    print("RTT: ", server.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME), " ms")
```

Use Debugger > **Network Profiler** to see RPC and synchronizer traffic per node.

## Godot 4.7 Debugging Notes

- **Perfetto** is now the default tracing tool for Android editor and template builds; record traces with Android's Perfetto tools alongside the in-editor profilers

## Debug Utility Functions

```gdscript
class_name DebugUtils
extends Node


static func log_tree(node: Node, indent: int = 0) -> void:
    # Same idea as the built-in node.print_tree_pretty(), with classes shown
    print("  ".repeat(indent) + node.name, " (", node.get_class(), ")")
    for child in node.get_children():
        log_tree(child, indent + 1)


static func check_node_ready(node: Node) -> bool:
    # Verify node is in the tree before accessing children
    if not node.is_inside_tree():
        push_error("Node not in tree: ", node.name)
    return node.is_inside_tree()
```
