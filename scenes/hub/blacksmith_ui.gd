## BlacksmithUI — Crafting interface at the Blacksmith NPC.
## Shows available recipes, material requirements, and handles crafting.

extends CanvasLayer

signal blacksmith_closed

var is_active: bool = false
var panel: PanelContainer = null
var content_label: Label = null


func _ready() -> void:
	_build_ui()
	panel.hide()


func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.name = "BlacksmithPanel"
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


func open_blacksmith() -> void:
	is_active = true
	_show_recipes()
	panel.show()


func _show_recipes() -> void:
	var recipes: Array[Dictionary] = CraftingSystem.get_recipes()
	var blacksmith_tier: int = UnlocksManager.blacksmith_tier
	
	var text: String = "═══ BLACKSMITH ═══\n"
	text += "Gold: %d | Tier: %d\n\n" % [GameManager.current_gold, blacksmith_tier]
	
	if blacksmith_tier <= 0:
		text += "The Blacksmith hasn't been built yet!\nVisit the Town Hall to unlock it.\n"
		text += "\n[ESC] Leave"
		content_label.text = text
		return
	
	var recipe_index: int = 0
	for recipe in recipes:
		if recipe["tier"] > blacksmith_tier:
			continue  # Skip recipes above current tier
		
		recipe_index += 1
		var can_make: bool = CraftingSystem.can_craft(recipe)
		var status: String = "" if can_make else " (missing materials)"
		
		text += "[%d] %s — %dG%s\n" % [recipe_index, recipe["name"], recipe["gold_cost"], status]
		text += "    %s\n" % recipe["description"]
		
		# Show materials
		var mats_text: String = "    Needs: "
		var materials: Dictionary = recipe["materials"]
		var mat_parts: Array[String] = []
		for mat_name in materials:
			var needed: int = materials[mat_name]
			var item: ItemData = ItemDatabase.get_item(mat_name)
			var have: int = GameManager.inventory.get_count(item) if item else 0
			mat_parts.append("%s %d/%d" % [mat_name, have, needed])
		mats_text += ", ".join(mat_parts)
		text += mats_text + "\n\n"
	
	if recipe_index == 0:
		text += "No recipes available at this tier.\n"
	
	text += "[ESC] Leave"
	content_label.text = text


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if not event is InputEventKey and not event is InputEventJoypadButton:
		return
	if not event.is_pressed():
		return
	
	get_viewport().set_input_as_handled()
	
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		_close()
		return
	if Input.is_action_just_pressed("cancel"):
		_close()
		return
	
	# Number key crafts a recipe
	if event is InputEventKey:
		var num: int = event.keycode - KEY_1
		_try_craft(num)


func _try_craft(index: int) -> void:
	var recipes: Array[Dictionary] = CraftingSystem.get_recipes()
	var blacksmith_tier: int = UnlocksManager.blacksmith_tier
	
	# Filter to available recipes
	var available: Array[Dictionary] = []
	for recipe in recipes:
		if recipe["tier"] <= blacksmith_tier:
			available.append(recipe)
	
	if index < 0 or index >= available.size():
		return
	
	var recipe: Dictionary = available[index]
	if CraftingSystem.craft(recipe):
		print("[Blacksmith] Crafted %s!" % recipe["name"])
	
	_show_recipes()  # Refresh


func _close() -> void:
	panel.hide()
	is_active = false
	blacksmith_closed.emit()
