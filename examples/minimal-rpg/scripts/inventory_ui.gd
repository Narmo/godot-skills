## Inventory panel that lists collected items and shows NPC dialogue.
## Demonstrates: container layout and signal-driven UI updates, with the
## player and NPCs found through groups instead of hard-coded paths.
class_name InventoryUI
extends PanelContainer

var _inventory: Dictionary[String, int] = {}

@onready var _count_label: Label = $VBox/ItemCountLabel
@onready var _items: VBoxContainer = $VBox/Items
@onready var _dialogue_label: Label = $VBox/DialogueLabel


func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.item_collected.connect(_on_item_collected)
	for node in get_tree().get_nodes_in_group("npc"):
		var npc := node as NPC
		if npc:
			npc.dialogue_started.connect(_on_dialogue_started)
			npc.dialogue_ended.connect(_on_dialogue_ended)


func _on_item_collected(item_name: String, quantity: int) -> void:
	_inventory[item_name] = _inventory.get(item_name, 0) + quantity
	_refresh()


func _refresh() -> void:
	var total := 0
	for amount: int in _inventory.values():
		total += amount
	_count_label.text = "Items: %d" % total

	for child in _items.get_children():
		child.queue_free()
	for item_name: String in _inventory:
		var label := Label.new()
		label.text = "%s: %d" % [item_name.capitalize(), _inventory[item_name]]
		_items.add_child(label)


func _on_dialogue_started(npc_name: String, text: String) -> void:
	_dialogue_label.text = "%s: %s" % [npc_name, text]


func _on_dialogue_ended() -> void:
	_dialogue_label.text = ""
