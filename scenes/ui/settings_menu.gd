## SettingsMenu — Player-configurable game options.
##
## Accessible from the hub (ESC key) or pause menu.
## Settings are saved to user:// and persist across sessions.
##
## OPTIONS:
## - Master Volume (0-100%)
## - Music Volume (0-100%)
## - SFX Volume (0-100%)
## - Window Mode (Windowed / Fullscreen)
## - Screen Shake (On / Off)
## - Show Damage Numbers (On / Off)

extends CanvasLayer

signal settings_closed

var is_active: bool = false
var panel: PanelContainer = null
var content_label: Label = null

## Current settings values
var settings: Dictionary = {
	"master_volume": 100,
	"music_volume": 80,
	"sfx_volume": 100,
	"fullscreen": false,
	"screen_shake": true,
	"show_damage_numbers": true,
}

## Which setting is currently selected (for keyboard navigation)
var selected_index: int = 0
const SETTING_KEYS: Array[String] = [
	"master_volume", "music_volume", "sfx_volume",
	"fullscreen", "screen_shake", "show_damage_numbers"
]
const SETTING_NAMES: Array[String] = [
	"Master Volume", "Music Volume", "SFX Volume",
	"Window Mode", "Screen Shake", "Damage Numbers"
]

const SAVE_PATH: String = "user://settings.json"


func _ready() -> void:
	_build_ui()
	panel.hide()
	_load_settings()


func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.name = "SettingsPanel"
	panel.anchor_left = 0.1
	panel.anchor_right = 0.9
	panel.anchor_top = 0.05
	panel.anchor_bottom = 0.95
	add_child(panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	
	content_label = Label.new()
	content_label.name = "ContentLabel"
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(content_label)
	
	panel.hide()


func open_settings() -> void:
	is_active = true
	selected_index = 0
	_refresh_display()
	panel.show()


func _refresh_display() -> void:
	var text: String = "═══ SETTINGS ═══\n\n"
	
	for i in range(SETTING_KEYS.size()):
		var key: String = SETTING_KEYS[i]
		var name: String = SETTING_NAMES[i]
		var marker: String = "> " if i == selected_index else "  "
		var value_str: String = _get_value_display(key)
		text += "%s%s: %s\n" % [marker, name, value_str]
	
	text += "\n── Controls ──\n"
	text += "  [UP/DOWN] Select option\n"
	text += "  [LEFT/RIGHT] Change value\n"
	text += "  [ESC] Save & Close\n"
	
	content_label.text = text


func _get_value_display(key: String) -> String:
	var value = settings[key]
	match key:
		"master_volume", "music_volume", "sfx_volume":
			var bar: String = _make_bar(value, 100)
			return "%s %d%%" % [bar, value]
		"fullscreen":
			return "Fullscreen" if value else "Windowed"
		"screen_shake":
			return "ON" if value else "OFF"
		"show_damage_numbers":
			return "ON" if value else "OFF"
		_:
			return str(value)


func _make_bar(value: int, max_val: int) -> String:
	## Create a visual bar like [████░░░░░░]
	var filled: int = int(float(value) / float(max_val) * 10.0)
	var empty: int = 10 - filled
	return "[" + "█".repeat(filled) + "░".repeat(empty) + "]"


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if not event is InputEventKey or not event.pressed:
		return
	
	get_viewport().set_input_as_handled()
	
	match event.keycode:
		KEY_UP, KEY_W:
			selected_index -= 1
			if selected_index < 0:
				selected_index = SETTING_KEYS.size() - 1
			_refresh_display()
		KEY_DOWN, KEY_S:
			selected_index += 1
			if selected_index >= SETTING_KEYS.size():
				selected_index = 0
			_refresh_display()
		KEY_LEFT, KEY_A:
			_adjust_setting(-1)
			_refresh_display()
		KEY_RIGHT, KEY_D:
			_adjust_setting(1)
			_refresh_display()
		KEY_ESCAPE:
			_save_and_close()


func _adjust_setting(direction: int) -> void:
	## Change the currently selected setting by the given direction (-1 or +1).
	var key: String = SETTING_KEYS[selected_index]
	
	match key:
		"master_volume", "music_volume", "sfx_volume":
			settings[key] = clampi(settings[key] + direction * 10, 0, 100)
			_apply_volume()
		"fullscreen":
			settings[key] = not settings[key]
			_apply_fullscreen()
		"screen_shake", "show_damage_numbers":
			settings[key] = not settings[key]


func _apply_volume() -> void:
	## Apply volume settings to Godot's audio buses.
	## AudioServer uses decibels. 0 dB = full, -80 dB = silent.
	## We convert percentage (0-100) to dB.
	var master_db: float = _percent_to_db(settings["master_volume"])
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_db)
	
	# Music and SFX buses might not exist yet (we haven't set them up).
	# Apply to Master for now — separate buses can be added later.


func _percent_to_db(percent: int) -> float:
	## Convert 0-100 percentage to decibels. 0% = -80dB (silent), 100% = 0dB.
	if percent <= 0:
		return -80.0
	return (float(percent) / 100.0 - 1.0) * 40.0  # Linear-ish mapping


func _apply_fullscreen() -> void:
	## Toggle fullscreen mode.
	if settings["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _save_and_close() -> void:
	_save_settings()
	panel.hide()
	is_active = false
	settings_closed.emit()


## ─── PERSISTENCE ────────────────────────────────────────────────

func _save_settings() -> void:
	var json_string: String = JSON.stringify(settings, "\t")
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("[Settings] Saved")


func _load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(json_string) == OK:
		var data = json.get_data()
		if data is Dictionary:
			# Merge loaded values (preserves defaults for new settings)
			for key in data:
				if settings.has(key):
					settings[key] = data[key]
			_apply_volume()
			if settings["fullscreen"]:
				_apply_fullscreen()
			print("[Settings] Loaded")


## ─── PUBLIC ACCESSORS (for other scripts to check settings) ─────

func get_setting(key: String):
	return settings.get(key, null)
