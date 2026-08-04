## EventUI — Displays dungeon events with choices.
## Created when player steps on an event tile (? marker in room templates).

extends CanvasLayer

signal event_resolved(result: Dictionary)

var is_active: bool = false
var panel: PanelContainer = null
var content_label: Label = null
var current_event: DungeonEvent = null
var _showing_result: bool = false
var _last_result_type: String = ""


func _ready() -> void:
	_build_ui()
	panel.hide()


func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.name = "EventPanel"
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.1
	panel.anchor_bottom = 0.9
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


func show_event(event: DungeonEvent) -> void:
	current_event = event
	is_active = true
	_display_choices()
	panel.show()


func _display_choices() -> void:
	var text: String = "═══ %s ═══\n\n" % current_event.event_name
	text += "%s\n\n" % current_event.description
	text += "── What do you do? ──\n\n"
	
	for i in range(current_event.choices.size()):
		var choice: Dictionary = current_event.choices[i]
		text += "[%d] %s\n" % [i + 1, choice["text"]]
	
	content_label.text = text


func _display_result(result: Dictionary) -> void:
	var text: String = "═══ %s ═══\n\n" % current_event.event_name
	text += "%s\n\n" % result.get("message", "Something happened.")
	text += "\n[ENTER] Continue"
	content_label.text = text


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if not event is InputEventKey or not event.pressed:
		return
	
	get_viewport().set_input_as_handled()
	
	if current_event == null:
		return
	
	# Check if we're showing result (waiting for ENTER)
	if _showing_result:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_close()
		return
	
	# Choice selection
	var num: int = event.keycode - KEY_1
	if num >= 0 and num < current_event.choices.size():
		_make_choice(num)


func _make_choice(choice_index: int) -> void:
	var result: Dictionary = current_event.resolve_choice(choice_index)
	
	# Store result type for ambush detection on close
	_last_result_type = result.get("type", "nothing")
	
	# Apply the result
	_apply_result(result, choice_index)
	
	# Show the outcome
	_showing_result = true
	_display_result(result)


func _apply_result(result: Dictionary, choice_index: int) -> void:
	## Apply the mechanical effect of the event outcome.
	var result_type: String = result.get("type", "nothing")
	var value = result.get("value", 0)
	
	match result_type:
		"heal_party":
			for member in PartyManager.active_party:
				if member.is_alive:
					member.current_hp = mini(member.current_hp + int(value), member.get_stats().max_hp)
		"restore_mp":
			for member in PartyManager.active_party:
				if member.is_alive:
					member.current_mp = mini(member.current_mp + int(value), member.get_stats().max_mp)
		"poison_party":
			for member in PartyManager.active_party:
				if member.is_alive:
					member.current_hp = maxi(member.current_hp - int(value), 1)
		"damage_party":
			for member in PartyManager.active_party:
				if member.is_alive:
					member.current_hp = maxi(member.current_hp - int(value), 1)
		"gold":
			GameManager.add_gold(int(value))
		"lose_gold":
			# Deduct gold (can't go below 0)
			GameManager.current_gold = maxi(GameManager.current_gold - int(value), 0)
		"item":
			var item: ItemData = ItemDatabase.get_item(str(value))
			if item:
				GameManager.inventory.add_item(item)
		"crystal":
			GameManager.meta_crystals += int(value)
		"buff_atk":
			pass  # TODO: apply temporary buff via status system once in combat
		"ambush":
			pass  # Will trigger combat after event closes
		"nothing":
			pass
	
	# Handle cost of choices that require spending
	var choice_text: String = current_event.choices[choice_index]["text"]
	if "10G" in choice_text or "20G" in choice_text:
		var cost: int = 20 if "20G" in choice_text else 10
		GameManager.current_gold = maxi(GameManager.current_gold - cost, 0)
	if "50G" in choice_text:
		GameManager.current_gold = maxi(GameManager.current_gold - 50, 0)
	if "Health Potion" in choice_text and "use" in choice_text.to_lower():
		var potion: ItemData = ItemDatabase.get_item("Health Potion")
		if potion:
			GameManager.inventory.remove_item(potion)
	if "sacrifice" in choice_text.to_lower():
		if PartyManager.active_party.size() > 0:
			var leader: CharacterData = PartyManager.active_party[0]
			leader.current_hp = maxi(leader.current_hp - 30, 1)


func _close() -> void:
	_showing_result = false
	panel.hide()
	is_active = false
	
	event_resolved.emit({"type": _last_result_type})
	_last_result_type = ""
	current_event = null
