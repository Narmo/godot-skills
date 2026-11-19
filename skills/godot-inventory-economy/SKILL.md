---
name: godot-inventory-economy
description: "Inventory and economy patterns for Godot 4.x: resource-based item definitions, stackable/unique items, drag-drop UI, equip systems, currency management, and save integration. Use when building item systems, shops, or economies in Godot games."
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
    - inventory
    - economy
    - items
    - equip
  created: 2026-06-21
---

# Inventory and Economy Systems in Godot

Patterns for item management, equipping, and game economies.

## Resource-Based Item Definitions

Define all items as `Resource` files — no code changes needed for new items:

```gdscript
class_name ItemData extends Resource

enum ItemType { CONSUMABLE, EQUIPMENT, KEY_ITEM, MATERIAL }
enum EquipmentSlot { HEAD, CHEST, HANDS, FEET, WEAPON, ACCESSORY }

@export var item_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
@export var item_type: ItemType = ItemType.MATERIAL
@export var stack_size: int = 1  # Max per stack; 1 = doesn't stack
@export var value: int = 0  # Gold/sell value
@export var equipment_slot: EquipmentSlot = EquipmentSlot.WEAPON

# Stat modifiers (for equipment)
@export var stat_modifiers: Dictionary = {}  # {"speed": 10, "defense": 5}

# Consumable effects
@export var heal_amount: int = 0
@export var effect_script: Script = null  # Optional custom effect
```

### Item Instance (Runtime)

```gdscript
class_name InventoryItem extends Resource

@export var item_data: ItemData
@export var quantity: int = 1
@export var durability: float = 1.0  # 0.0 to 1.0, -1 = unbreakable
@export var is_equipped: bool = false
```

## Inventory Manager

Core inventory system with stack management:

```gdscript
class_name Inventory extends Node

signal item_added(item: InventoryItem)
signal item_removed(item: InventoryItem)
signal item_equipped(item: InventoryItem, slot: ItemData.EquipmentSlot)
signal item_unequipped(slot: ItemData.EquipmentSlot)
signal inventory_changed()

var items: Array[InventoryItem] = []
var equipped: Dictionary = {}  # slot -> InventoryItem
@export var max_slots: int = 20

## Adds as much as fits; returns false if some of the quantity didn't fit.
func add_item(data: ItemData, quantity: int = 1) -> bool:
    # Fill existing stacks first
    if data.stack_size > 1:
        for inv_item in items:
            if quantity <= 0:
                break
            if inv_item.item_data == data and inv_item.quantity < data.stack_size:
                var add_amount := mini(quantity, data.stack_size - inv_item.quantity)
                inv_item.quantity += add_amount
                quantity -= add_amount
                item_added.emit(inv_item)

    # Then open new stacks while there are free slots
    while quantity > 0 and items.size() < max_slots:
        var new_item := InventoryItem.new()
        new_item.item_data = data
        new_item.quantity = mini(quantity, maxi(data.stack_size, 1))
        new_item.durability = 1.0 if data.item_type == ItemData.ItemType.EQUIPMENT else -1.0
        items.append(new_item)
        item_added.emit(new_item)
        quantity -= new_item.quantity

    inventory_changed.emit()
    return quantity <= 0

func remove_item(index: int, quantity: int = 1) -> bool:
    if index < 0 or index >= items.size():
        return false

    var inv_item = items[index]
    if inv_item.quantity <= quantity:
        item_removed.emit(inv_item)
        items.remove_at(index)
    else:
        inv_item.quantity -= quantity
        item_removed.emit(inv_item)

    inventory_changed.emit()
    return true

func equip(item_index: int) -> bool:
    if item_index < 0 or item_index >= items.size():
        return false
    var inv_item := items[item_index]
    if inv_item.item_data.item_type != ItemData.ItemType.EQUIPMENT:
        return false
    var slot := inv_item.item_data.equipment_slot

    # Unequip current item in slot
    if equipped.has(slot):
        unequip(slot)

    inv_item.is_equipped = true
    equipped[slot] = inv_item
    item_equipped.emit(inv_item, slot)
    return true

func unequip(slot: ItemData.EquipmentSlot) -> bool:
    if not equipped.has(slot):
        return false

    var inv_item = equipped[slot]
    inv_item.is_equipped = false
    equipped.erase(slot)
    item_unequipped.emit(slot)
    return true
```

## Drag-and-Drop Inventory UI

Controls have built-in drag and drop: return data from `_get_drag_data()`, accept it in
`_can_drop_data()`, and handle it in `_drop_data()`.

```gdscript
class_name InventorySlot
extends PanelContainer

signal drop_requested(from_index: int, to_index: int)

var item: InventoryItem = null
var slot_index: int = 0

@onready var _icon: TextureRect = $Icon
@onready var _quantity_label: Label = $Quantity


func _get_drag_data(_at_position: Vector2) -> Variant:
    if item == null:
        return null
    var preview := TextureRect.new()
    preview.texture = item.item_data.icon
    set_drag_preview(preview)
    return {"from_index": slot_index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    return data is Dictionary and data.has("from_index") and data["from_index"] != slot_index


func _drop_data(_at_position: Vector2, data: Variant) -> void:
    drop_requested.emit(data["from_index"], slot_index)


func update_display() -> void:
    _icon.texture = item.item_data.icon if item else null
    _quantity_label.text = str(item.quantity) if item and item.quantity > 1 else ""
```

### Inventory Grid

```gdscript
class_name InventoryGrid
extends GridContainer

@export var inventory: Inventory
@export var slot_scene: PackedScene


func _ready() -> void:
    for i in inventory.max_slots:
        var slot := slot_scene.instantiate() as InventorySlot
        slot.slot_index = i
        slot.drop_requested.connect(_on_drop_requested)
        add_child(slot)
    inventory.inventory_changed.connect(refresh)
    refresh()


func refresh() -> void:
    for child in get_children():
        var slot := child as InventorySlot
        if slot:
            slot.item = inventory.items[slot.slot_index] if slot.slot_index < inventory.items.size() else null
            slot.update_display()


func _on_drop_requested(from: int, to: int) -> void:
    var items := inventory.items
    if from >= items.size():
        return
    if to >= items.size():
        items.append(items.pop_at(from))  # dropped on an empty slot: move to the end
    else:
        var temp := items[from]
        items[from] = items[to]
        items[to] = temp
    refresh()
```

## Currency and Shop System

```gdscript
class_name EconomyManager extends Node

signal gold_changed(amount: int)
signal item_purchased(item: ItemData, cost: int)
signal item_sold(item: ItemData, price: int)

var gold: int = 0

func add_gold(amount: int) -> void:
    gold += amount
    gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
    if gold < amount:
        return false
    gold -= amount
    gold_changed.emit(gold)
    return true

# Shop transaction
func buy_item(inventory: Inventory, item_data: ItemData, price: int) -> bool:
    if not spend_gold(price):
        return false
    inventory.add_item(item_data)
    item_purchased.emit(item_data, price)
    return true

func sell_item(inventory: Inventory, item_index: int, price: int) -> bool:
    if item_index < 0 or item_index >= inventory.items.size():
        return false
    var inv_item := inventory.items[item_index]
    inventory.remove_item(item_index, 1)
    add_gold(price)
    item_sold.emit(inv_item.item_data, price)
    return true
```

## Save Integration

Serialize item **ids**, and resolve them through a fixed table on load. Never build a
`load()` path from save data — the player controls the save file, and would control which
resource you load.

```gdscript
# item_database.gd — autoload "ItemDatabase": every item the game ships, by id
extends Node

const ITEMS: Dictionary[String, ItemData] = {
    "potion": preload("res://items/potion.tres"),
    "iron_sword": preload("res://items/iron_sword.tres"),
}


func get_item(item_id: String) -> ItemData:
    return ITEMS.get(item_id)
```

```gdscript
# Add to Inventory
func serialize_inventory() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for inv_item in items:
        result.append({
            "item_id": inv_item.item_data.item_id,
            "quantity": inv_item.quantity,
            "durability": inv_item.durability,
            "equipped": inv_item.is_equipped,
        })
    return result


func deserialize_inventory(data: Array) -> void:
    items.clear()
    for entry in data:
        if entry is not Dictionary:
            continue
        var item_data := ItemDatabase.get_item(str(entry.get("item_id", "")))
        if item_data == null:
            continue  # unknown id: skip it rather than trusting the file
        var inv_item := InventoryItem.new()
        inv_item.item_data = item_data
        inv_item.quantity = clampi(int(entry.get("quantity", 1)), 1, maxi(item_data.stack_size, 1))
        inv_item.durability = clampf(float(entry.get("durability", 1.0)), -1.0, 1.0)
        items.append(inv_item)
    inventory_changed.emit()
```
