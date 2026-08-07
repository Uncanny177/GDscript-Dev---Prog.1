## PauseMenu — In-game pause overlay accessible during dungeon/combat.
##
## Pauses the game tree (everything freezes) and shows options.
## ESC or Start button opens/closes it.
## Uses process_mode = ALWAYS so it still receives input while paused.

extends CanvasLayer

var is_active: bool = false
var panel: PanelContainer = null
var content_label: Label = null
var selected_index: int = 0

## Dark overlay reference
var overlay: ColorRect = null
const MENU_ITEMS: Array[String] = ["Resume", "Settings", "Save & Quit to Hub"]


func _ready() -> void:
	layer = 90  # Below transition (100) but above everything else
	process_mode = Node.PROCESS_MODE_ALWAYS  # Runs even when tree is paused
	_build_ui()
	panel.hide()
	overlay.hide()


func _build_ui() -> void:
	# Dark overlay behind the menu
	overlay = ColorRect.new()
	overlay.name = "PauseOverlay"
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	
	panel = PanelContainer.new()
	panel.name = "PausePanel"
	panel.anchor_left = 0.25
	panel.anchor_right = 0.75
	panel.anchor_top = 0.2
	panel.anchor_bottom = 0.8
	add_child(panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	content_label = Label.new()
	content_label.name = "ContentLabel"
	content_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	margin.add_child(content_label)
	
	panel.hide()
	overlay.hide()


func _unhandled_input(event: InputEvent) -> void:
	# Open/close with ESC or Start button
	if not event is InputEventKey and not event is InputEventJoypadButton:
		return
	if not event.is_pressed():
		return
	
	# Toggle pause
	if not is_active:
		if event is InputEventKey and event.keycode == KEY_ESCAPE:
			# Only pause during dungeon or combat (not hub/title)
			if _can_pause():
				_open()
				get_viewport().set_input_as_handled()
		elif Input.is_action_just_pressed("pause"):
			if _can_pause():
				_open()
				get_viewport().set_input_as_handled()
	else:
		get_viewport().set_input_as_handled()
		
		if event is InputEventKey:
			match event.keycode:
				KEY_ESCAPE:
					_close()
				KEY_UP, KEY_W:
					selected_index -= 1
					if selected_index < 0:
						selected_index = MENU_ITEMS.size() - 1
					_refresh()
				KEY_DOWN, KEY_S:
					selected_index += 1
					if selected_index >= MENU_ITEMS.size():
						selected_index = 0
					_refresh()
				KEY_ENTER, KEY_SPACE:
					_select_item()
		
		if Input.is_action_just_pressed("cancel"):
			_close()
		elif Input.is_action_just_pressed("ui_accept"):
			_select_item()


func _can_pause() -> bool:
	## Only allow pausing during dungeon exploration or combat.
	## Don't pause from hub (hub has its own settings via ESC).
	if SettingsMenu.is_active:
		return false
	var state: int = GameManager.current_state
	return state == GameManager.GameState.DUNGEON or state == GameManager.GameState.COMBAT


func _open() -> void:
	is_active = true
	selected_index = 0
	get_tree().paused = true
	_refresh()
	panel.show()
	overlay.show()


func _close() -> void:
	is_active = false
	get_tree().paused = false
	panel.hide()
	overlay.hide()
	overlay.hide()


func _refresh() -> void:
	var text: String = "═══ PAUSED ═══\n\n"
	text += "Floor %d | Gold: %d\n\n" % [GameManager.current_floor, GameManager.current_gold]
	
	for i in range(MENU_ITEMS.size()):
		var marker: String = "> " if i == selected_index else "  "
		text += "%s%s\n" % [marker, MENU_ITEMS[i]]
	
	text += "\n[ESC] Resume"
	content_label.text = text


func _select_item() -> void:
	match MENU_ITEMS[selected_index]:
		"Resume":
			_close()
		"Settings":
			# Unpause temporarily so settings menu can function, then re-pause after
			get_tree().paused = false
			panel.hide()
	overlay.hide()
			overlay.hide()
			is_active = false
			SettingsMenu.open_settings()
			# When settings closes, we don't automatically re-open pause
			# (player is back in the game — they can ESC to pause again)
		"Save & Quit to Hub":
			_close()
			# Save run state so player can resume later
			SaveManager.save_run()
			SaveManager.save_meta()
			GameManager.is_run_active = false
			GameManager.current_state = GameManager.GameState.HUB
			TransitionManager.transition_to("res://scenes/hub/hub.tscn")
