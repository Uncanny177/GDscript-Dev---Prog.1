## TitleScreen — The first thing the player sees on launch.
##
## Options:
##   - New Game (resets all progress, starts fresh)
##   - Continue (loads meta save, goes to hub)
##   - Settings (opens settings menu)
##   - Quit (exits application)

extends Node2D

var selected_index: int = 0
var menu_items: Array[String] = []
var has_save: bool = false

## Visual state
var title_pulse: float = 0.0


func _ready() -> void:
	# Check if a save exists
	has_save = FileAccess.file_exists("user://meta_save.json")
	
	# Build menu items based on save state
	menu_items.clear()
	if has_save:
		menu_items.append("Continue")
	menu_items.append("New Game")
	menu_items.append("Settings")
	menu_items.append("Stats")
	menu_items.append("Quit")
	
	selected_index = 0


func _process(delta: float) -> void:
	# Pulse animation for title
	title_pulse += delta * 2.0
	queue_redraw()


func _draw() -> void:
	var screen_w: float = 640.0
	var screen_h: float = 480.0
	
	# Background gradient (dark blue to black)
	draw_rect(Rect2(0, 0, screen_w, screen_h), Color(0.02, 0.02, 0.08), true)
	
	# Decorative border
	var border_color := Color(0.3, 0.2, 0.5, 0.4)
	draw_rect(Rect2(20, 20, screen_w - 40, screen_h - 40), border_color, false, 2.0)
	draw_rect(Rect2(24, 24, screen_w - 48, screen_h - 48), Color(0.2, 0.15, 0.35, 0.3), false, 1.0)
	
	# Title
	var font: Font = ThemeDB.fallback_font
	var title_y: float = 120.0 + sin(title_pulse) * 3.0  # Gentle bob
	var title_color := Color(0.9, 0.75, 0.3)  # Gold
	draw_string(font, Vector2(screen_w / 2.0 - 120, title_y), "ROGUELITE RPG", HORIZONTAL_ALIGNMENT_CENTER, 240, 32, title_color)
	
	# Subtitle
	draw_string(font, Vector2(screen_w / 2.0 - 100, title_y + 35), "~ Descent into Darkness ~", HORIZONTAL_ALIGNMENT_CENTER, 200, 14, Color(0.6, 0.5, 0.7))
	
	# Menu items
	var menu_start_y: float = 240.0
	var spacing: float = 40.0
	
	for i in range(menu_items.size()):
		var item: String = menu_items[i]
		var y_pos: float = menu_start_y + i * spacing
		var is_selected: bool = i == selected_index
		
		var text_color: Color = Color(1.0, 0.9, 0.5) if is_selected else Color(0.6, 0.6, 0.65)
		var font_size: int = 20 if is_selected else 16
		
		# Selection indicator
		if is_selected:
			# Highlight bar behind selected item
			draw_rect(Rect2(screen_w / 2.0 - 80, y_pos - 18, 160, 26), Color(0.3, 0.2, 0.5, 0.3), true)
			# Arrow
			draw_string(font, Vector2(screen_w / 2.0 - 90, y_pos), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.9, 0.7, 0.2))
		
		draw_string(font, Vector2(screen_w / 2.0 - 50, y_pos), item, HORIZONTAL_ALIGNMENT_LEFT, 120, font_size, text_color)
	
	# Footer
	draw_string(font, Vector2(screen_w / 2.0 - 80, screen_h - 50), "[UP/DOWN] Select  [ENTER] Confirm", HORIZONTAL_ALIGNMENT_CENTER, 160, 10, Color(0.4, 0.4, 0.45))
	
	# Version
	draw_string(font, Vector2(screen_w - 80, screen_h - 30), "v0.15", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.3, 0.3, 0.35))


func _unhandled_input(event: InputEvent) -> void:
	if SettingsMenu.is_active:
		return
	if StatsScreen.is_active:
		return
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		KEY_UP, KEY_W:
			selected_index -= 1
			if selected_index < 0:
				selected_index = menu_items.size() - 1
		KEY_DOWN, KEY_S:
			selected_index += 1
			if selected_index >= menu_items.size():
				selected_index = 0
		KEY_ENTER, KEY_SPACE:
			_select_item()
		KEY_ESCAPE:
			# ESC on title = quit
			get_tree().quit()


func _select_item() -> void:
	var item: String = menu_items[selected_index]
	
	match item:
		"Continue":
			_continue_game()
		"New Game":
			_new_game()
		"Settings":
			SettingsMenu.open_settings()
		"Stats":
			StatsScreen.open_stats()
		"Quit":
			get_tree().quit()


func _continue_game() -> void:
	## Load saved progress and go to hub.
	TransitionManager.transition_to("res://scenes/hub/hub.tscn")


func _new_game() -> void:
	## Reset all progress and start fresh.
	# Clear save files
	if FileAccess.file_exists("user://meta_save.json"):
		DirAccess.remove_absolute("user://meta_save.json")
	if FileAccess.file_exists("user://run_save.json"):
		DirAccess.remove_absolute("user://run_save.json")
	
	# Reset GameManager state
	GameManager.meta_crystals = 0
	GameManager.total_runs = 0
	GameManager.current_gold = 0
	
	# Reset UnlocksManager
	UnlocksManager.shop_tier = 1
	UnlocksManager.blacksmith_tier = 0
	UnlocksManager.training_ground_tier = 0
	UnlocksManager.highest_floor_reached = 0
	UnlocksManager.total_bosses_defeated = 0
	UnlocksManager.total_enemies_defeated = 0
	UnlocksManager.total_runs_completed = 0
	UnlocksManager.unlocked_classes = ["Warrior", "Mage", "Rogue"]
	
	# Reset party to default (PartyManager recreates on next _ready or we force it)
	PartyManager.active_party.clear()
	PartyManager.reserve.clear()
	PartyManager._create_default_party()
	
	# Go to hub
	TransitionManager.transition_to("res://scenes/hub/hub.tscn")
