## Tooltip — Shows item/skill descriptions on demand.
##
## A floating info panel that can be triggered from any menu to show
## details about an item, skill, or status effect.
##
## USAGE:
##   Tooltip.show_item(item_data, screen_position)
##   Tooltip.show_skill(skill_data, screen_position)
##   Tooltip.show_status(status_effect)
##   Tooltip.hide()
##
## Automatically hides after a timeout or on any input.

extends CanvasLayer

var is_visible: bool = false
var panel: PanelContainer = null
var content_label: Label = null
var hide_timer: float = 0.0
const AUTO_HIDE_TIME: float = 5.0  # Hide after 5 seconds if no input


func _ready() -> void:
	layer = 95  # Above most UI, below transition
	_build_ui()
	panel.hide()


func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.name = "TooltipPanel"
	# Positioned dynamically when shown
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.offset_left = 50
	panel.offset_top = 50
	panel.offset_right = 300
	panel.offset_bottom = 200
	add_child(panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	
	content_label = Label.new()
	content_label.name = "TooltipText"
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(content_label)
	
	panel.hide()


func _process(delta: float) -> void:
	if is_visible:
		hide_timer -= delta
		if hide_timer <= 0:
			hide_tooltip()


func _unhandled_input(event: InputEvent) -> void:
	## Any input hides the tooltip.
	if is_visible and event.is_pressed():
		hide_tooltip()


## ─── PUBLIC API ─────────────────────────────────────────────────

func show_item(item: ItemData, pos: Vector2 = Vector2(50, 50)) -> void:
	if not item:
		return
	
	var text: String = "── %s ──\n" % item.item_name
	text += "%s\n\n" % item.description
	
	match item.item_type:
		ItemData.ItemType.CONSUMABLE:
			text += "Type: Consumable\n"
			if item.heal_hp > 0:
				text += "Heals: %d HP\n" % item.heal_hp
			if item.heal_mp > 0:
				text += "Restores: %d MP\n" % item.heal_mp
		ItemData.ItemType.EQUIPMENT:
			text += "Type: Equipment (%s)\n" % ItemData.EquipSlot.keys()[item.equip_slot]
			if item.stat_bonus:
				text += "Stats: %s\n" % _format_stat_bonus(item.stat_bonus)
		ItemData.ItemType.KEY_ITEM:
			text += "Type: Material\n"
	
	text += "Value: %dG" % item.buy_price
	if not item.sellable:
		text += " (unsellable)"
	
	_show(text, pos)


func show_skill(skill: SkillData, pos: Vector2 = Vector2(50, 50)) -> void:
	if not skill:
		return
	
	var text: String = "── %s ──\n" % skill.skill_name
	text += "%s\n\n" % skill.description
	text += "MP Cost: %d\n" % skill.mp_cost
	text += "Target: %s\n" % skill.get_target_description()
	text += "Type: %s\n" % SkillData.DamageType.keys()[skill.damage_type]
	if skill.power_multiplier > 0:
		text += "Power: x%.1f\n" % skill.power_multiplier
	if skill.element != "none":
		text += "Element: %s\n" % skill.element
	if not skill.status_on_hit.is_empty():
		var status_name: String = StatusEffect.Type.keys()[skill.status_on_hit.get("type", 0)]
		text += "Applies: %s (%d%% chance)\n" % [status_name, skill.status_on_hit.get("chance", 100)]
	
	_show(text, pos)


func show_status(effect: StatusEffect, pos: Vector2 = Vector2(50, 50)) -> void:
	if not effect:
		return
	
	var text: String = "── %s ──\n" % effect.get_name()
	text += "Turns remaining: %d\n" % effect.duration
	text += "Potency: %d\n" % effect.potency
	if effect.source_name != "":
		text += "Applied by: %s\n" % effect.source_name
	
	_show(text, pos)


func show_text(title: String, body: String, pos: Vector2 = Vector2(50, 50)) -> void:
	## Generic tooltip with custom text.
	var text: String = "── %s ──\n%s" % [title, body]
	_show(text, pos)


func hide_tooltip() -> void:
	is_visible = false
	panel.hide()


## ─── INTERNAL ───────────────────────────────────────────────────

func _show(text: String, pos: Vector2) -> void:
	content_label.text = text
	panel.offset_left = pos.x
	panel.offset_top = pos.y
	panel.offset_right = pos.x + 250
	panel.offset_bottom = pos.y + 180
	panel.show()
	is_visible = true
	hide_timer = AUTO_HIDE_TIME


func _format_stat_bonus(stats: StatBlock) -> String:
	var parts: Array[String] = []
	if stats.max_hp != 0:
		parts.append("+%d HP" % stats.max_hp)
	if stats.max_mp != 0:
		parts.append("+%d MP" % stats.max_mp)
	if stats.atk != 0:
		parts.append("+%d ATK" % stats.atk)
	if stats.def_stat != 0:
		parts.append("+%d DEF" % stats.def_stat)
	if stats.mag != 0:
		parts.append("+%d MAG" % stats.mag)
	if stats.res_stat != 0:
		parts.append("+%d RES" % stats.res_stat)
	if stats.spd != 0:
		parts.append("+%d SPD" % stats.spd)
	return ", ".join(parts) if not parts.is_empty() else "None"
