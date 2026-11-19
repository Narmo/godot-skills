---
name: godot-i18n
description: "Localization patterns for Godot 4.x: TranslationServer, CSV and PO translation files, runtime language switching, RTL text support, font fallback chains, and pluralization. Use when implementing internationalization in Godot games."
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
    - i18n
    - localization
    - translation
    - rtl
  created: 2026-06-21
---

# Localization in Godot

Patterns for internationalizing Godot games.

## TranslationServer Basics

Godot translates through `TranslationServer`. Controls translate their `text` automatically
(`auto_translate_mode`); in code, wrap strings in `tr()`:

```gdscript
func _ready() -> void:
    $Label.text = tr("GREET")          # key-based (CSV)
    $Button.text = tr("Start Game")    # source-text based (PO)
```

### Creating Translation Files

Godot imports two formats:

**CSV** — one row per key, one column per locale. Godot generates `.translation` resources on
import:

```csv
keys,en,es,ja
GREET,"Hello, friend!","¡Hola, amigo!",こんにちは
START,Start Game,Comenzar juego,ゲームスタート
SCORE,Score: %d,Puntuación: %d,スコア: %d
```

**PO (gettext)** — one file per locale, used directly. Generate the template from your scenes
and scripts with **Project Settings > Localization > POT Generation**:

```po
msgid "Start Game"
msgstr "Comenzar juego"
```

### Registering Translations

Add the imported `.translation` or `.po` files in **Project Settings > Localization >
Translations** (`internationalization/locale/translations`).

## Runtime Language Switching

```gdscript
# language_manager.gd — autoload "LanguageManager"
extends Node

signal language_changed(locale: String)

const SETTINGS_PATH := "user://settings.cfg"

var available_locales: Array[String] = ["en", "es", "fr", "ja"]
var current_locale: String = "en"


func _ready() -> void:
    var config := ConfigFile.new()
    if config.load(SETTINGS_PATH) == OK:
        set_language(config.get_value("general", "language", "en"))


func set_language(locale: String) -> void:
    if not available_locales.has(locale):
        push_error("LanguageManager: Unsupported locale '%s'" % locale)
        return
    TranslationServer.set_locale(locale)  # auto-translated Controls update by themselves
    current_locale = locale
    language_changed.emit(locale)
    _save_preference()


func _save_preference() -> void:
    var config := ConfigFile.new()
    config.load(SETTINGS_PATH)  # keep other settings; a missing file is fine
    config.set_value("general", "language", current_locale)
    config.save(SETTINGS_PATH)
```

Text you set from code with `tr()` does not update by itself. Refresh it when the locale
changes:

```gdscript
func _notification(what: int) -> void:
    if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
        $Label.text = tr("SCORE") % score
```

### Language Selector UI

```gdscript
# language_selector.gd — attached to an OptionButton
extends OptionButton


func _ready() -> void:
    for locale in LanguageManager.available_locales:
        add_item(TranslationServer.get_locale_name(locale))
        set_item_metadata(item_count - 1, locale)
    selected = LanguageManager.available_locales.find(LanguageManager.current_locale)
    item_selected.connect(_on_item_selected)


func _on_item_selected(index: int) -> void:
    LanguageManager.set_language(get_item_metadata(index))
```

## Pluralization

`tr_n(message, plural_message, n, context)` picks the right plural form for the current locale.
PO files carry plural rules; CSV files support plurals since Godot 4.6 through a `?plural`
column.

```gdscript
func show_item_count(count: int) -> void:
    $Label.text = tr_n("You have %d item.", "You have %d items.", count) % count
```

Languages with three or more plural forms (Slavic languages, Arabic) get them from the PO
file's `Plural-Forms` header — no custom logic needed.

## RTL Text Support

For Arabic, Hebrew, and other right-to-left languages:

```gdscript
# Labels pick the direction from their text by default (TEXT_DIRECTION_AUTO).
# Force it when needed:
$Label.text_direction = Control.TEXT_DIRECTION_RTL
$Label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
$Label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

# Mixed LTR/RTL text inside one string is reordered by the BiDi algorithm automatically.
```

### RTL-Aware UI Layout

Containers mirror their children when the layout direction is right-to-left:

```gdscript
# Follow the current locale (set this on the root Control of your UI)
$UI.layout_direction = Control.LAYOUT_DIRECTION_APPLICATION_LOCALE


func is_rtl_locale() -> bool:
    var text_server := TextServerManager.get_primary_interface()
    return text_server.is_locale_right_to_left(TranslationServer.get_locale())
```

## Font Fallback Chains

Handle characters not available in the primary font:

```gdscript
# Theme approach (recommended): open the primary font resource and add
# fallback fonts in its Fallbacks list, then set it as the theme's default font.

# Code approach:
var primary: FontFile = load("res://fonts/NotoSans-Regular.ttf")
primary.fallbacks = [load("res://fonts/NotoSansCJK-Regular.otf")]
$Label.add_theme_font_override("font", primary)

# Or use the operating system's fonts, which fall back automatically:
var system_font := SystemFont.new()
system_font.font_names = PackedStringArray(["Noto Sans", "Arial"])
```

## Translation Best Practices

### Use Context

```gdscript
# The same word with different meanings gets a context:
tr("Attack", "verb")
tr("Attack", "stat")

# In .po files the context is msgctxt:
# msgctxt "verb" / msgid "Attack" / msgstr "Atacar"
# msgctxt "stat" / msgid "Attack" / msgstr "Ataque"
```

### Avoid String Concatenation for Translatable Text

```gdscript
# Bad — translators can't reorder
tr("You found ") + item_name + tr(" in the cave!")

# Good — translators control word order
tr("You found %s in the cave!") % item_name

# Better — named placeholders for clarity
tr("You found {item} in {location}!").format({"item": item_name, "location": location_name})
```

### Externalize All UI Strings

```gdscript
# Hardcoded strings make translation impossible
$Label.text = "Score: 100"  # BAD

# Use tr() for everything visible to players
$Label.text = tr("Score: %d") % score  # GOOD
```
