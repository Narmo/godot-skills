---
name: godot-physics
description: "Physics systems for Godot 4.x: collision layers/masks, rigid body dynamics, character controllers (CharacterBody2D/3D), area nodes for triggers, physics interpolation, bulk queries, and performance optimization. Use when implementing physics, collisions, movement, or triggers in Godot."
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
    - physics
    - collision
    - character-body
    - rigid-body
    - area
  created: 2026-06-20
---

# Physics Systems for Godot 4.x

Comprehensive patterns for physics, collisions, and movement in Godot 4.x.

## Collision Layers and Masks

Every collision object (bodies and areas) has 32 layers. `collision_layer` says which layers
the object **is on**; `collision_mask` says which layers it **detects**.

### Configuring Collision Layers

Set them on the body or area in the Inspector (**Collision > Layer / Mask**), and name the
layers in Project Settings > Layer Names so the checkboxes are readable.

```gdscript
# Bit values for the recommended layout below
const LAYER_PLAYER := 1 << 0        # layer 1
const LAYER_ENEMIES := 1 << 1       # layer 2
const LAYER_PROJECTILES := 1 << 2   # layer 3
const LAYER_ENVIRONMENT := 1 << 3   # layer 4
const LAYER_PICKUPS := 1 << 4       # layer 5
const LAYER_TRIGGERS := 1 << 5      # layer 6


func _ready() -> void:
    collision_layer = LAYER_PLAYER
    collision_mask = LAYER_ENVIRONMENT | LAYER_PICKUPS
    # Same thing by layer number:
    set_collision_mask_value(4, true)
```

### Layer Design Best Practices

| Layer | Bit value | Use Case |
|-------|-----------|----------|
| 1 | `0x1` | Player characters |
| 2 | `0x2` | Enemies and NPCs |
| 3 | `0x4` | Projectiles and weapons |
| 4 | `0x8` | Environment / terrain |
| 5 | `0x10` | Pickups and collectibles |
| 6 | `0x20` | Triggers (Area-only) |

### Raycast Queries

```gdscript
func raycast_forward(max_distance: float) -> Dictionary:
    var from := global_position
    var to := from + -global_transform.basis.z * max_distance  # -Z is forward
    var query := PhysicsRayQueryParameters3D.create(from, to, LAYER_ENVIRONMENT, [get_rid()])
    var result := get_world_3d().direct_space_state.intersect_ray(query)
    if result:
        print("Hit: ", result["collider"].name, " at ", result["position"])
    return result
```

Query the space state only in `_physics_process` — that is when it is safe to read.

## Rigid Body Dynamics

### Forces and Impulses

`RigidBody3D` is moved by the physics engine; push it, don't set its position.

```gdscript
class_name Crate
extends RigidBody3D


func _ready() -> void:
    gravity_scale = 1.0
    var bouncy := PhysicsMaterial.new()
    bouncy.bounce = 0.8
    bouncy.friction = 0.2
    physics_material_override = bouncy


func kick(direction: Vector3, strength: float) -> void:
    apply_central_impulse(direction.normalized() * strength)  # one-off push


func _physics_process(_delta: float) -> void:
    apply_central_force(Vector3.UP * 2.0)  # continuous force, applied every tick
```

### Rigid Body Projectile

```gdscript
class_name Projectile
extends RigidBody3D

@export var lifetime: float = 3.0
@export var damage: int = 10
@export var speed: float = 20.0


func _ready() -> void:
    # body_entered only fires with contact monitoring on.
    contact_monitor = true
    max_contacts_reported = 1
    body_entered.connect(_on_body_entered)
    linear_velocity = -global_transform.basis.z * speed
    get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _on_body_entered(body: Node) -> void:
    if body.has_method("take_damage"):
        body.take_damage(damage)
    queue_free()
```

## Character Controllers

`CharacterBody2D/3D` already has a `velocity` property; set it and call `move_and_slide()`.

### CharacterBody3D Movement Pattern

```gdscript
class_name ThirdPersonController
extends CharacterBody3D

@export var walk_speed: float = 4.0
@export var jump_velocity: float = 4.5
@export var sprint_factor: float = 2.0


func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity += get_gravity() * delta  # project gravity plus any Area3D overrides
    if is_on_floor() and Input.is_action_just_pressed("jump"):
        velocity.y = jump_velocity

    var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
    var speed := walk_speed * (sprint_factor if Input.is_action_pressed("sprint") else 1.0)
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, walk_speed)
        velocity.z = move_toward(velocity.z, 0.0, walk_speed)
    move_and_slide()
```

### CharacterBody2D Platformer Pattern

```gdscript
class_name PlatformerCharacter
extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_force: float = -450.0
@export var gravity: float = 1200.0
@export var max_fall_speed: float = 700.0
@export var acceleration: float = 800.0
@export var friction: float = 600.0


func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
    if is_on_floor() and Input.is_action_just_pressed("jump"):
        velocity.y = jump_force
    var move_input := Input.get_axis("move_left", "move_right")
    if move_input:
        velocity.x = move_toward(velocity.x, move_input * speed, acceleration * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, friction * delta)
    move_and_slide()
```

For slopes and moving platforms, tune `floor_snap_length`, `floor_max_angle` and
`floor_stop_on_slope`; call `apply_floor_snap()` to stick to the floor after a teleport.

## Area Nodes for Triggers and Detection

### Basic Pickup Zone

```gdscript
class_name PickupZone
extends Area3D

@export var pickup_scene: PackedScene
@export var min_items: int = 1
@export var max_items: int = 3

var _has_been_activated := false


func _ready() -> void:
    body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
    if _has_been_activated or not body is CharacterBody3D:
        return
    _has_been_activated = true
    _spawn_items()
    queue_free()


func _spawn_items() -> void:
    for i in randi_range(min_items, max_items):
        var item: Node3D = pickup_scene.instantiate()
        item.position = global_position + Vector3(randf_range(-1.0, 1.0), 0.5, randf_range(-1.0, 1.0))
        # Physics callbacks can't add collision objects directly; defer to after the step.
        get_tree().current_scene.add_child.call_deferred(item)
```

### Enemy Detection Sensor

```gdscript
class_name EnemySensor
extends Area3D

signal player_detected(player: CharacterBody3D)
signal player_lost(player: CharacterBody3D)

@export var detection_radius: float = 10.0
@export_flags_3d_physics var detection_layers: int = 1


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    var sphere := SphereShape3D.new()
    sphere.radius = detection_radius
    $CollisionShape3D.shape = sphere
    collision_mask = detection_layers


func _on_body_entered(body: Node3D) -> void:
    if body is CharacterBody3D:
        player_detected.emit(body)


func _on_body_exited(body: Node3D) -> void:
    if body is CharacterBody3D:
        player_lost.emit(body)
```

## Physics Interpolation

Physics interpolation renders moving objects smoothly between physics ticks, so a 30 Hz
physics rate still looks fluid at a 144 Hz display. Godot 4.3 added it for 2D and 4.4 for 3D.

- Enable **Project Settings > Physics > Common > Physics Interpolation** (`physics/common/physics_interpolation`)
- Move objects in `_physics_process`, not `_process`
- After teleporting an object, call `reset_physics_interpolation()` so it doesn't visibly slide to the new spot
- Custom drawing can read `Engine.get_physics_interpolation_fraction()`

## Performance: Bulk Physics Queries

### Shape Queries

```gdscript
func get_all_collisions_in_area(origin: Vector3, radius: float, mask: int) -> Array[Dictionary]:
    var sphere := SphereShape3D.new()
    sphere.radius = radius
    var query := PhysicsShapeQueryParameters3D.new()
    query.shape = sphere
    query.transform = Transform3D(Basis(), origin)
    query.collision_mask = mask
    query.exclude = [get_rid()]
    return get_world_3d().direct_space_state.intersect_shape(query)


func aoe_attack(center: Vector3, radius: float, damage: int) -> void:
    for hit in get_all_collisions_in_area(center, radius, LAYER_ENEMIES):
        var collider: Object = hit["collider"]
        if collider.has_method("take_damage"):
            collider.take_damage(damage)
```

### Collision Layer Optimization

- Only check layers you need — avoid `collision_mask = 0xFFFFFFFF`
- Use `NavigationServer3D` for pathfinding queries
- Use small-radius `Area3D` nodes for proximity checks
- Avoid querying the entire world every frame

## Quick Reference: Movement Methods

| Method | Use Case | Returns |
|--------|----------|---------|
| `move_and_slide()` | Standard character movement using `velocity` | `bool` — true if it collided |
| `move_and_collide(motion)` | Move once and handle the collision yourself | `KinematicCollision2D/3D` or `null` |
| `apply_floor_snap()` | Stick to the floor after a teleport or spawn | — |
| `RigidBody3D.apply_central_impulse()` | One-off push on a rigid body | — |
