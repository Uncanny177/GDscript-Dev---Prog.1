## GuildUI — Recruit new party members and manage your party.
##
## KEY CONCEPT: MULTI-SCREEN MENU
## This UI has multiple screens the player navigates between:
##   Main → Recruit (pick a class) → Party (swap active/reserve)
##
## Recruitment creates a new CharacterData with the chosen class.
## Characters are permanent — they persist in PartyManager across runs.

extends CanvasLayer

signal guild_closed

## UI state
var is_active: bool = false
var mode: int = 0  # 0=main, 1=recruit, 2=party, 3=equip, 4=equip_target

## UI nodes
var panel: PanelContainer = null
var content_label: Label = null

## Tracking for equipment flow
var equip_character_index: int = 0
var equip_slot: int = 0  # 0=weapon, 1=armor, 2=accessory

## Names pool for recruited characters
const NAMES: Array[String] = [
	"Aldric", "Brynn", "Cassia", "Draven", "Elira",
	"Finn", "Greta", "Holt", "Isolde", "Jareth",
	"Kira", "Lorne", "Mira", "Nix", "Orin",
	"Petra", "Quinn", "Riven", "Sera", "Thane"
]


func _ready() -> void:
	_build_ui()
	panel.hide()


func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.name = "GuildPanel"
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


func open_guild() -> void:
	is_active = true
	mode = 0
	_show_main_menu()
	panel.show()


func _show_main_menu() -> void:
	mode = 0
	var text: String = "═══ ADVENTURER'S GUILD ═══\n\n"
	text += "Party: %d/%d active\n" % [PartyManager.active_party.size(), PartyManager.MAX_PARTY_SIZE]
	text += "Reserve: %d\n\n" % PartyManager.reserve.size()
	text += "[1] Recruit New Member\n"
	text += "[2] Manage Party\n"
	text += "[3] Equipment\n"
	text += "[ESC] Leave\n"
	content_label.text = text


func _show_recruit_menu() -> void:
	mode = 1
	var text: String = "═══ RECRUIT ═══\n\n"
	text += "Choose a class:\n\n"
	
	var classes: Array = ClassDatabase.get_all_classes()
	for i in range(classes.size()):
		var c: ClassData = classes[i]
		text += "[%d] %s — %s\n" % [i + 1, c.class_name_text, c.description]
		if c.base_stats:
			text += "    HP:%d ATK:%d DEF:%d MAG:%d SPD:%d\n" % [
				c.base_stats.max_hp, c.base_stats.atk, c.base_stats.def_stat,
				c.base_stats.mag, c.base_stats.spd
			]
	
	text += "\n[ESC] Back"
	content_label.text = text


func _show_party_menu() -> void:
	mode = 2
	var text: String = "═══ PARTY MANAGEMENT ═══\n\n"
	text += "── Active Party ──\n"
	for i in range(PartyManager.active_party.size()):
		var member: CharacterData = PartyManager.active_party[i]
		var class_name_str: String = member.character_class.class_name_text if member.character_class else "None"
		text += "  [%d] %s (%s) HP:%d/%d\n" % [
			i + 1, member.character_name, class_name_str,
			member.current_hp, member.character_class.base_stats.max_hp if member.character_class and member.character_class.base_stats else 0
		]
	
	if not PartyManager.reserve.is_empty():
		text += "\n── Reserve ──\n"
		for i in range(PartyManager.reserve.size()):
			var member: CharacterData = PartyManager.reserve[i]
			var class_name_str: String = member.character_class.class_name_text if member.character_class else "None"
			var key_num: int = PartyManager.active_party.size() + i + 1
			text += "  [%d] %s (%s)\n" % [key_num, member.character_name, class_name_str]
	
	text += "\n[S] Swap (enter two numbers)\n[ESC] Back"
	content_label.text = text


func _show_equip_menu() -> void:
	mode = 3
	var text: String = "═══ EQUIPMENT ═══\n\n"
	text += "Choose character to equip:\n\n"
	
	for i in range(PartyManager.active_party.size()):
		var member: CharacterData = PartyManager.active_party[i]
		var weapon_name: String = member.weapon.item_name if member.weapon else "(none)"
		var armor_name: String = member.armor.item_name if member.armor else "(none)"
		var accessory_name: String = member.accessory.item_name if member.accessory else "(none)"
		text += "[%d] %s\n" % [i + 1, member.character_name]
		text += "    Weapon: %s | Armor: %s | Accessory: %s\n" % [weapon_name, armor_name, accessory_name]
	
	text += "\n[ESC] Back"
	content_label.text = text


func _show_equip_slot_menu(char_index: int) -> void:
	mode = 4
	equip_character_index = char_index
	var member: CharacterData = PartyManager.active_party[char_index]
	
	var text: String = "═══ EQUIP: %s ═══\n\n" % member.character_name
	
	# Show available equipment from inventory
	var weapons: Array = _get_equipment_by_slot(ItemData.EquipSlot.WEAPON)
	var armors: Array = _get_equipment_by_slot(ItemData.EquipSlot.ARMOR)
	var accessories: Array = _get_equipment_by_slot(ItemData.EquipSlot.ACCESSORY)
	
	var current_weapon: String = member.weapon.item_name if member.weapon else "(none)"
	var current_armor: String = member.armor.item_name if member.armor else "(none)"
	var current_accessory: String = member.accessory.item_name if member.accessory else "(none)"
	
	text += "Current: W:%s | A:%s | Acc:%s\n\n" % [current_weapon, current_armor, current_accessory]
	text += "[1] Change Weapon (%d available)\n" % weapons.size()
	text += "[2] Change Armor (%d available)\n" % armors.size()
	text += "[3] Change Accessory (%d available)\n" % accessories.size()
	text += "[4] Unequip All\n"
	text += "\n[ESC] Back"
	content_label.text = text


func _get_equipment_by_slot(slot: ItemData.EquipSlot) -> Array:
	## Get equipment items from inventory matching a slot.
	var result: Array = []
	var all_items: Array = GameManager.inventory.get_all_items()
	for entry in all_items:
		var item: ItemData = entry["item"]
		if item.item_type == ItemData.ItemType.EQUIPMENT and item.equip_slot == slot:
			result.append(item)
	return result


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if not event is InputEventKey or not event.pressed:
		return
	
	get_viewport().set_input_as_handled()
	
	match mode:
		0: _handle_main_input(event)
		1: _handle_recruit_input(event)
		2: _handle_party_input(event)
		3: _handle_equip_input(event)
		4: _handle_equip_slot_input(event)


func _handle_main_input(event: InputEventKey) -> void:
	match event.keycode:
		KEY_1: _show_recruit_menu()
		KEY_2: _show_party_menu()
		KEY_3: _show_equip_menu()
		KEY_ESCAPE: _close()


func _handle_recruit_input(event: InputEventKey) -> void:
	if event.keycode == KEY_ESCAPE:
		_show_main_menu()
		return
	
	var num: int = event.keycode - KEY_1
	var classes: Array = ClassDatabase.get_all_classes()
	if num >= 0 and num < classes.size():
		_recruit_character(classes[num])
		_show_main_menu()


func _handle_party_input(event: InputEventKey) -> void:
	if event.keycode == KEY_ESCAPE:
		_show_main_menu()
		return
	
	# Number keys swap: first press = select from active, second = select target
	# For simplicity: odd numbers move active→reserve, pressing on reserve moves→active
	var total_members: int = PartyManager.active_party.size() + PartyManager.reserve.size()
	var num: int = event.keycode - KEY_1
	
	if num >= 0 and num < PartyManager.active_party.size():
		# Selected an active member — move to reserve (if party > 1)
		if PartyManager.active_party.size() > 1:
			PartyManager.remove_from_party(num)
			print("[Guild] Moved member to reserve")
		_show_party_menu()
	elif num >= PartyManager.active_party.size() and num < total_members:
		# Selected a reserve member — move to active (if party < max)
		var reserve_idx: int = num - PartyManager.active_party.size()
		if PartyManager.active_party.size() < PartyManager.MAX_PARTY_SIZE:
			var member: CharacterData = PartyManager.reserve[reserve_idx]
			PartyManager.reserve.remove_at(reserve_idx)
			PartyManager.active_party.append(member)
			print("[Guild] Moved member to active party")
		_show_party_menu()


func _handle_equip_input(event: InputEventKey) -> void:
	if event.keycode == KEY_ESCAPE:
		_show_main_menu()
		return
	
	var num: int = event.keycode - KEY_1
	if num >= 0 and num < PartyManager.active_party.size():
		_show_equip_slot_menu(num)


func _handle_equip_slot_input(event: InputEventKey) -> void:
	if event.keycode == KEY_ESCAPE:
		_show_equip_menu()
		return
	
	var member: CharacterData = PartyManager.active_party[equip_character_index]
	
	match event.keycode:
		KEY_1:
			_equip_from_inventory(member, ItemData.EquipSlot.WEAPON)
		KEY_2:
			_equip_from_inventory(member, ItemData.EquipSlot.ARMOR)
		KEY_3:
			_equip_from_inventory(member, ItemData.EquipSlot.ACCESSORY)
		KEY_4:
			_unequip_all(member)
	
	_show_equip_slot_menu(equip_character_index)


func _equip_from_inventory(member: CharacterData, slot: ItemData.EquipSlot) -> void:
	## Equip the first matching item from inventory to the character.
	var available: Array = _get_equipment_by_slot(slot)
	if available.is_empty():
		return
	
	var item: ItemData = available[0]
	
	# Unequip current item in that slot (return to inventory)
	match slot:
		ItemData.EquipSlot.WEAPON:
			if member.weapon:
				GameManager.inventory.add_item(member.weapon)
			member.weapon = item
		ItemData.EquipSlot.ARMOR:
			if member.armor:
				GameManager.inventory.add_item(member.armor)
			member.armor = item
		ItemData.EquipSlot.ACCESSORY:
			if member.accessory:
				GameManager.inventory.add_item(member.accessory)
			member.accessory = item
	
	# Remove from inventory
	GameManager.inventory.remove_item(item)
	print("[Guild] Equipped %s on %s" % [item.item_name, member.character_name])


func _unequip_all(member: CharacterData) -> void:
	## Return all equipment to inventory.
	if member.weapon:
		GameManager.inventory.add_item(member.weapon)
		member.weapon = null
	if member.armor:
		GameManager.inventory.add_item(member.armor)
		member.armor = null
	if member.accessory:
		GameManager.inventory.add_item(member.accessory)
		member.accessory = null
	print("[Guild] Unequipped all from %s" % member.character_name)


func _recruit_character(class_data: ClassData) -> void:
	## Create a new character of the given class and add to party/reserve.
	var character := CharacterData.new()
	character.character_name = _pick_random_name()
	character.character_class = class_data
	character.initialize()
	
	var added_to_active: bool = PartyManager.add_to_party(character)
	if added_to_active:
		print("[Guild] Recruited %s (%s) — added to active party" % [character.character_name, class_data.class_name_text])
	else:
		print("[Guild] Recruited %s (%s) — added to reserve (party full)" % [character.character_name, class_data.class_name_text])


func _pick_random_name() -> String:
	## Pick a random name not already used by existing party/reserve members.
	var used_names: Array[String] = []
	for member in PartyManager.active_party:
		used_names.append(member.character_name)
	for member in PartyManager.reserve:
		used_names.append(member.character_name)
	
	var available: Array[String] = []
	for n in NAMES:
		if n not in used_names:
			available.append(n)
	
	if available.is_empty():
		return "Recruit_%d" % (PartyManager.active_party.size() + PartyManager.reserve.size())
	
	return available[randi() % available.size()]


func _close() -> void:
	panel.hide()
	is_active = false
	guild_closed.emit()
