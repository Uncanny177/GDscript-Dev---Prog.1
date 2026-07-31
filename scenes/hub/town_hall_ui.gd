## TownHallUI — Spend meta-crystals to upgrade the town.
##
## This is where permanent progression happens. The player spends
## meta-crystals earned from dungeon runs to unlock new facilities
## and upgrade existing ones.

extends CanvasLayer

signal town_hall_closed

var is_active: bool = false
var panel: PanelContainer = null
var content_label: Label = null


func _ready() -> void:
	_build_ui()
	panel.hide()


func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.name = "TownHallPanel"
	panel.anchor_left = 0.05
	panel.anchor_right = 0.95
	panel.anchor_top = 0.05
	panel.anchor_bottom = 0.95
	add_child(panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)
	
	content_label = Label.new()
	content_label.name = "ContentLabel"
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(content_label)
	
	panel.hide()


func open_town_hall() -> void:
	is_active = true
	_show_menu()
	panel.show()


func _show_menu() -> void:
	var text: String = "═══ TOWN HALL ═══\n"
	text += "Meta-Crystals: %d\n\n" % GameManager.meta_crystals
	
	# Show current town status
	text += "── Town Status ──\n"
	text += "  Shop: Tier %d\n" % UnlocksManager.shop_tier
	text += "  Blacksmith: %s\n" % ("Tier %d" % UnlocksManager.blacksmith_tier if UnlocksManager.blacksmith_tier > 0 else "Not Built")
	text += "  Training Ground: %s\n" % ("Tier %d" % UnlocksManager.training_ground_tier if UnlocksManager.training_ground_tier > 0 else "Not Built")
	
	# Show milestones
	text += "\n── Progress ──\n"
	text += "  Highest Floor: %d\n" % UnlocksManager.highest_floor_reached
	text += "  Bosses Defeated: %d\n" % UnlocksManager.total_bosses_defeated
	text += "  Runs Completed: %d\n" % UnlocksManager.total_runs_completed
	
	# Show available upgrades
	var upgrades: Array[Dictionary] = UnlocksManager.get_available_upgrades()
	if upgrades.is_empty():
		text += "\n── All upgrades purchased! ──\n"
	else:
		text += "\n── Available Upgrades ──\n"
		for i in range(upgrades.size()):
			var upgrade: Dictionary = upgrades[i]
			var can_afford: String = "" if GameManager.meta_crystals >= upgrade["cost"] else " (need more)"
			text += "[%d] %s — %d crystals%s\n" % [i + 1, upgrade["name"], upgrade["cost"], can_afford]
			text += "    %s\n" % upgrade["description"]
	
	text += "\n[ESC] Leave"
	content_label.text = text


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if not event is InputEventKey or not event.pressed:
		return
	
	get_viewport().set_input_as_handled()
	
	if event.keycode == KEY_ESCAPE:
		_close()
		return
	
	var num: int = event.keycode - KEY_1
	var upgrades: Array[Dictionary] = UnlocksManager.get_available_upgrades()
	if num >= 0 and num < upgrades.size():
		var upgrade: Dictionary = upgrades[num]
		if UnlocksManager.purchase_upgrade(upgrade["id"]):
			print("[TownHall] Upgraded: %s" % upgrade["name"])
		else:
			print("[TownHall] Can't afford: %s" % upgrade["name"])
		_show_menu()  # Refresh


func _close() -> void:
	panel.hide()
	is_active = false
	town_hall_closed.emit()
