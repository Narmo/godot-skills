---
name: godot-csharp-patterns
description: "C# Mono patterns for Godot 4.x: Export attributes, signal handling, performance optimization, cross-language interop with GDScript, and best practices for first-class C# support. Use when writing C# code in Godot."
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
    - csharp
    - mono
    - performance
  created: 2026-06-20
---

# C# Patterns for Godot 4.x

Best practices for Godot's first-class C# (Mono) support.

## Export Attributes

### Inspector Properties

```csharp
using Godot;

public partial class Player : CharacterBody2D
{
    // Basic export
    [Export] public float Speed { get; set; } = 200f;

    // With range
    [Export(PropertyHint.Range, "0,100,0.5")]
    public float JumpForce { get; set; } = 400f;

    // File path
    [Export(PropertyHint.File, "*.png,*.svg")]
    public string IconPath { get; set; } = "";

    // Resource export
    [Export] public PackedScene BulletScene { get; set; }

    // Enum with hint
    [Export] public MovementMode MoveMode { get; set; }

    public enum MovementMode
    {
        Walk,
        Run,
        Sprint
    }
}
```

### Export Categories

```csharp
[ExportGroup("Combat")]
[Export] public int AttackDamage { get; set; } = 10;
[Export] public float AttackCooldown { get; set; } = 0.5f;

[ExportGroup("Movement")]
[Export] public float MoveSpeed { get; set; } = 200f;
[Export] public float JumpForce { get; set; } = 400f;
```

## Signal Handling

### Subscribing to C# Signals

Signals declared in C# with `[Signal]` become C# events:

```csharp
// EventBus.cs — autoload "EventBus"
public partial class EventBus : Node
{
    [Signal] public delegate void PlayerDiedEventHandler(Vector2 position);
}
```

```csharp
// Subscriber
private EventBus _eventBus;

public override void _Ready()
{
    _eventBus = GetNode<EventBus>("/root/EventBus");

    // Method on this node: disconnected automatically when this node is freed
    _eventBus.PlayerDied += OnPlayerDied;
}

public override void _ExitTree()
{
    // Lambdas and handlers on non-Godot objects must be removed by hand;
    // removing method handlers here is harmless and keeps intent explicit
    _eventBus.PlayerDied -= OnPlayerDied;
}

private void OnPlayerDied(Vector2 position)
{
    GD.Print($"Player died at {position}");
}
```

### Connecting to GDScript Signals

Signals declared in GDScript have no C# event; connect by name:

```csharp
var gdNode = GetNode("/root/GameState");  // a GDScript autoload
gdNode.Connect("level_completed", Callable.From<int>(OnLevelCompleted));
```

### Declaring and Emitting C# Signals

```csharp
public partial class Enemy : CharacterBody2D
{
    [Signal] public delegate void HealthChangedEventHandler(int newHealth);
    [Signal] public delegate void DefeatedEventHandler();

    private int _health = 100;

    public void TakeDamage(int amount)
    {
        _health -= amount;
        EmitSignal(SignalName.HealthChanged, _health);

        if (_health <= 0)
        {
            EmitSignal(SignalName.Defeated);
            QueueFree();
        }
    }
}
```

## Performance Considerations

### Avoiding GC Pressure

```csharp
// Bad: builds a new string every frame, even when nothing changed
public override void _Process(double delta)
{
    label.Text = $"Score: {_score}";
}

// Good: update only when the value changes
private int _score;

public int Score
{
    get => _score;
    set
    {
        if (_score == value) return;
        _score = value;
        label.Text = $"Score: {_score}";
    }
}
```

### Structs vs Classes

```csharp
// Use structs for small, short-lived data (Godot's own Vector2/Vector2I are structs too)
public readonly struct HitInfo
{
    public readonly int Damage;
    public readonly Vector2 Direction;
    public HitInfo(int damage, Vector2 direction) => (Damage, Direction) = (damage, direction);
}

// Godot objects are classes; Resources need partial, [GlobalClass] and [Export] to be saved
[GlobalClass]
public partial class PlayerData : Resource
{
    [Export] public string Name { get; set; } = "";
    [Export] public int Level { get; set; } = 1;
}
```

### Instance Pooling

```csharp
public partial class BulletPool : Node
{
    [Export] public PackedScene BulletScene { get; set; }

    private readonly Queue<Bullet> _pool = new();

    public Bullet Get()
    {
        if (!_pool.TryDequeue(out var bullet))
        {
            bullet = BulletScene.Instantiate<Bullet>();
            AddChild(bullet);
        }
        bullet.Visible = true;
        bullet.ProcessMode = ProcessModeEnum.Inherit;
        return bullet;
    }

    public void Return(Bullet bullet)
    {
        // Deactivate instead of freeing — a freed node can't be reused
        bullet.Visible = false;
        bullet.ProcessMode = ProcessModeEnum.Disabled;
        _pool.Enqueue(bullet);
    }
}
```

## Cross-Language Interop

### Calling GDScript from C#

```csharp
// GDScript autoload "GameData" with: var high_score: int = 0
var gameData = GetNode("/root/GameData");
int highScore = gameData.Get("high_score").AsInt32();
gameData.Call("add_score", 100);
```

### Using C# Classes from GDScript

C# and GDScript classes in the same project can use each other directly. Mark C# classes
with `[GlobalClass]` to make them appear in the editor's "Create New Node/Resource" dialogs
and usable by name in GDScript. GDExtension is for native (C++/Rust) libraries, not for C#.

## Godot 4.7 C# Notes

- New 4.7 APIs are available in C# under PascalCase names, e.g. `tween.TweenAwait(signal)` for `tween_await()` and the `VirtualJoystick` class
- Await a tween with `await ToSignal(tween, Tween.SignalName.Finished)`
- Use the .NET build of the editor and the .NET SDK version its release notes require
