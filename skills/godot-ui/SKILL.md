---
name: godot-ui
description: "UI systems for Godot 4.x: Control node hierarchy, containers and layout modes (Anchor, Margin, Center, Fill, Expand), theme resources, custom styles, RichTextLabel formatting, PopupMenu search, and control offset transforms. Use when building menus, HUDs, inventory screens, or any UI in Godot."
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
    - ui
    - control
    - container
    - theme
    - rich-text
  created: 2026-06-20
---

# UI Systems for Godot 4.x

Comprehensive patterns for user interfaces, menus, and HUD elements in Godot 4.x.

## Control Node Hierarchy and Containers

### Container Types

Godot 4.x provides several container nodes for responsive UI layouts.

```gdscript
# Vertical layout
var vbox = VBoxContainer.new()
vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
add_child(vbox)

# Horizontal layout
var hbox = HBoxContainer.new()
hbox.add_child(Button.new())
hbox.add_child(Button.new())
vbox.add_child(hbox)

# Grid layout
var grid = GridContainer.new()
grid.columns = 3
for i in range(9):
    var btn = Button.new()
    btn.text = str(i)
    grid.add_child(btn)
vbox.add_child(grid)
```

### Anchor Presets

Use anchor presets for responsive positioning.

```gdscript
# Top-left corner, stays fixed
button.set_anchors_preset(Control.PRESET_TOP_LEFT)

# Full screen (fills parent)
panel.set_anchors_preset(Control.PRESET_FULL_RECT)

# Centered with margins
label.set_anchors_preset(Control.PRESET_CENTER)
label.offset_left = -100
label.offset_right = 100
```
## Layout Modes (Anchor, Margin, Center, Fill, Expand)

### Anchor Mode

Control how a node positions itself relative to its parent.

```gdscript
# Manual anchor setup
control.anchor_right = 1.0   # Right edge sticks to parent right
control.offset_right = -20   # But 20px from the edge
control.anchor_bottom = 1.0
control.offset_bottom = -20
```

### Margin Container

Add padding around a child node.

```gdscript
var margin = MarginContainer.new()
margin.add_theme_constant_override("margin_left", 16)
margin.add_theme_constant_override("margin_top", 16)
margin.add_theme_constant_override("margin_right", 16)
margin.add_theme_constant_override("margin_bottom", 16)
margin.add_child(content_panel)
```

### Center Container

Center a child node within its parent. CenterContainer centers its children automatically;
there is nothing to configure except `use_top_left`.

```gdscript
var center := CenterContainer.new()
center.set_anchors_preset(Control.PRESET_FULL_RECT)
center.add_child(dialog_panel)
```

### Fill and Expand

Inside containers, size flags decide how much space a child takes:

```gdscript
# Take a share of the free space and fill it
button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

# Fill the cell but don't ask for extra space
label.size_flags_horizontal = Control.SIZE_FILL

# Weight the share of free space between expanding siblings
sidebar.size_flags_stretch_ratio = 1.0
content.size_flags_stretch_ratio = 3.0
```
## Theme Resources and Custom Styles

### Creating a Custom Theme

```gdscript
# Create theme in code
var theme := Theme.new()

# Default font for every control using this theme
theme.default_font = load("res://fonts/my_font.ttf")  # .ttf/.otf import as FontFile
theme.default_font_size = 16

# Custom button style
var normal_style := StyleBoxTexture.new()
normal_style.texture = load("res://ui/button_normal.png")
normal_style.texture_margin_left = 8
normal_style.texture_margin_right = 8
normal_style.texture_margin_top = 4
normal_style.texture_margin_bottom = 4

var hover_style: StyleBoxTexture = normal_style.duplicate()
hover_style.modulate_color = Color(1.2, 1.2, 1.2)  # Lighter on hover

theme.set_stylebox("normal", "Button", normal_style)
theme.set_stylebox("hover", "Button", hover_style)
```

### Theme Overrides per Control

```gdscript
# Override theme on individual controls
button.add_theme_color_override("font_color", Color.WHITE)
button.add_theme_font_size_override("font_size", 20)
button.add_theme_stylebox_override("normal", custom_style)

# Apply theme to entire scene tree
add_child(button)
button.theme = theme
```

### Theme Variation Pattern

```gdscript
# Create themed button scenes for consistency
# ui_button_primary.tscn, ui_button_secondary.tscn, etc.
const PRIMARY_BTN = preload("res://ui/button_primary.tscn")
const SECONDARY_BTN = preload("res://ui/button_secondary.tscn")

func create_primary_button(text: String) -> Button:
    var btn = PRIMARY_BTN.instantiate()
    btn.text = text
    return btn
```
## RichTextLabel Formatting and Image Sizing

### BBCode and Custom Effects

BBCode needs `bbcode_enabled = true`. Custom tags come from `RichTextEffect` scripts:

```gdscript
rich_text_label.bbcode_enabled = true
rich_text_label.text = "[color=red]Alert![/color] Health is low."
rich_text_label.text = "[b]Bold[/b] and [i]italic[/i] text"
rich_text_label.text = "[img=64]res://icons/heart.png[/img] 10/20 HP"
```

```gdscript
# rich_text_shake.gd — use as [shake strength=4]Hit![/shake]
@tool
class_name RichTextShake
extends RichTextEffect

var bbcode := "shake"


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var strength: float = char_fx.env.get("strength", 2.0)
	char_fx.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
	return true
```

Register it once with `rich_text_label.install_effect(RichTextShake.new())`.

### Image Sizing in RichTextLabel

```gdscript
# Fixed size images
rich_text_label.text = "[img=32]res://icons/coin.png[/img] [img=32]res://icons/coin.png[/img]"

# Scale by font size
rich_text_label.text = "[font_size=48][img=48]res://icons/star.png[/img][/font_size]"

# Size icons from the font the label actually uses
func get_icon_size() -> int:
    var font := rich_text_label.get_theme_font("normal_font")
    var font_size := rich_text_label.get_theme_font_size("normal_font_size")
    return int(font.get_height(font_size))
```
## Godot 4.7 UI Features

### PopupMenu Search (Godot 4.7)

PopupMenu can show a search bar at the top, which filters long menus and works on touchscreens.

```gdscript
@onready var popup_menu: PopupMenu = $PopupMenu


func _ready() -> void:
	popup_menu.search_bar_enabled = true
	popup_menu.search_bar_min_item_count = 10  # only for long menus
	popup_menu.search_bar_fuzzy_search_enabled = true
	popup_menu.index_pressed.connect(_on_menu_selected)


func _on_menu_selected(index: int) -> void:
	print("Selected: ", popup_menu.get_item_text(index))
```

### Control Offset Transforms (Godot 4.7)

`offset_transform_*` properties move, scale and rotate a Control on top of its layout, so a
panel inside a container can slide or pop without fighting the container.

```gdscript
func slide_in(panel: Control) -> void:
	panel.offset_transform_enabled = true
	panel.offset_transform_position = Vector2(-300.0, 0.0)  # start off-screen
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "offset_transform_position", Vector2.ZERO, 0.3)


func pop(button: Control) -> void:
	button.offset_transform_enabled = true
	button.offset_transform_pivot_ratio = Vector2(0.5, 0.5)  # scale around the center
	var tween := create_tween()
	tween.tween_property(button, "offset_transform_scale", Vector2(1.1, 1.1), 0.08)
	tween.tween_property(button, "offset_transform_scale", Vector2.ONE, 0.12)

# Use for: sliding menus, notifications, button feedback inside containers
```
## UI Performance Tips

- Use **Container** nodes instead of manually positioning controls
- Prefer **Anchor presets** over manual offset adjustments when possible
- Cache `RichTextLabel` formatted text when content does not change
- Use `TextureRect` with `STRETCH_SCALE` for responsive images
- Avoid creating/destroying UI nodes every frame — use pooling instead
- Hide off-screen panels with `visible = false` instead of freeing and re-creating them

## Quick Reference: Container Nodes

| Container | Layout |
|-----------|--------|
| `HBoxContainer` | Horizontal row |
| `VBoxContainer` | Vertical column |
| `GridContainer` | Grid with fixed columns |
| `CenterContainer` | Centered child |
| `MarginContainer` | Padded child |
| `ScrollContainer` | Scrollable area |
| `AspectRatioContainer` | Fixed aspect ratio |
| `Control` (root) | Full rect anchor |
