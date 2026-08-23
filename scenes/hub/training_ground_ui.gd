## TrainingGroundUI — Unlock new skills for classes using meta-crystals.
## Requires Training Ground facility to be built (UnlocksManager).

extends CanvasLayer

signal training_closed

var is_active: bool = false
var panel: PanelContainer = null
var content_label: Label = null
var mode: int = 0  # 0 = class select, 1 = skill select
var selected_class: String = ""

## Tracks which skills have been permanently unlocked (persists via UnlocksManager)
## Stored as Array[String] of skill IDs in UnlocksManager.unlocks["learned_skills"]


func _ready() -> void:
	_build_ui()
	panel.hide()


func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.name = "TrainingPanel"
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


func open_training() -> void:
	is_active = true
	mode = 0
	_show_class_select()
	panel.show()


func _show_class_select() -> void:
	mode = 0
	var text: String = "═══ TRAINING GROUND ═══\n"
	text += "Meta-Crystals: %d\n\n" % GameManager.meta_crystals
	
	if UnlocksManager.training_ground_tier <= 0:
		text += "The Training Ground hasn't been built yet!\nVisit the Town Hall to unlock it.\n"
		text += "\n[ESC] Leave"
		content_label.text = text
		return
	
	text += "Choose a class to train:\n\n"
	var classes: Array = ClassDatabase.get_all_classes()
	for i in range(classes.size()):
		var c: ClassData = classes[i]
		var learnable: Array = SkillTree.get_learnable_skills(c.class_name_text)
		var learned_count: int = _count_learned(c.class_name_text, learnable)
		text += "[%d] %s (%d/%d skills learned)\n" % [i + 1, c.class_name_text, learned_count, learnable.size()]
	
	text += "\n[ESC] Leave"
	content_label.text = text


func _show_skill_select() -> void:
	mode = 1
	var text: String = "═══ %s SKILLS ═══\n" % selected_class.to_upper()
	text += "Meta-Crystals: %d\n\n" % GameManager.meta_crystals
	
	var learnable: Array[Dictionary] = SkillTree.get_learnable_skills(selected_class)
	
	if learnable.is_empty():
		text += "No additional skills available.\n"
	else:
		for i in range(learnable.size()):
			var entry: Dictionary = learnable[i]
			var skill: SkillData = entry["skill"]
			var is_learned: bool = _is_skill_learned(entry["id"])
			
			if is_learned:
				text += "  [✓] %s (learned)\n" % skill.skill_name
			else:
				var can_afford: String = "" if GameManager.meta_crystals >= entry["cost"] else " (need more)"
				text += "  [%d] %s — %d crystals, Lv%d req%s\n" % [i + 1, skill.skill_name, entry["cost"], entry["level_req"], can_afford]
				text += "      %s (MP: %d)\n" % [skill.description, skill.mp_cost]
	
	text += "\n[ESC] Back"
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
		if mode == 1:
			_show_class_select()
		else:
			_close()
		return
	if Input.is_action_just_pressed("cancel"):
		if mode == 1:
			_show_class_select()
		else:
			_close()
		return
	
	if event is InputEventKey:
		var num: int = event.keycode - KEY_1
		if mode == 0:
			_select_class(num)
		elif mode == 1:
			_try_learn_skill(num)


func _select_class(index: int) -> void:
	var classes: Array = ClassDatabase.get_all_classes()
	if index < 0 or index >= classes.size():
		return
	selected_class = classes[index].class_name_text
	_show_skill_select()


func _try_learn_skill(index: int) -> void:
	var learnable: Array[Dictionary] = SkillTree.get_learnable_skills(selected_class)
	if index < 0 or index >= learnable.size():
		return
	
	var entry: Dictionary = learnable[index]
	
	# Already learned?
	if _is_skill_learned(entry["id"]):
		return
	
	# Can afford?
	if not GameManager.spend_meta_crystals(entry["cost"]):
		return
	
	# Learn it
	_mark_skill_learned(entry["id"])
	
	# Add to all characters of this class
	_apply_skill_to_class(selected_class, entry["skill"])
	
	print("[Training] Learned %s for %s class" % [entry["skill"].skill_name, selected_class])
	_show_skill_select()


func _apply_skill_to_class(class_name_text: String, skill: SkillData) -> void:
	## Add the skill to the class definition so all characters of that class have it.
	var class_data: ClassData = ClassDatabase.get_class_data(class_name_text)
	if class_data and skill not in class_data.skills:
		class_data.skills.append(skill)


func _is_skill_learned(skill_id: String) -> bool:
	var learned: Array = UnlocksManager.unlocks.get("learned_skills", [])
	return skill_id in learned


func _mark_skill_learned(skill_id: String) -> void:
	if not UnlocksManager.unlocks.has("learned_skills"):
		UnlocksManager.unlocks["learned_skills"] = []
	UnlocksManager.unlocks["learned_skills"].append(skill_id)


func _count_learned(class_name_text: String, learnable: Array) -> int:
	var count: int = 0
	for entry in learnable:
		if _is_skill_learned(entry["id"]):
			count += 1
	return count


func _close() -> void:
	panel.hide()
	is_active = false
	training_closed.emit()


static func restore_learned_skills() -> void:
	## Called on game load to re-apply all previously learned skills to class definitions.
	## Since SkillData objects are created fresh each time, we rebuild them from IDs.
	var learned: Array = UnlocksManager.unlocks.get("learned_skills", [])
	if learned.is_empty():
		return
	
	var all_classes: Array = ClassDatabase.get_all_classes()
	for class_data in all_classes:
		var learnable: Array[Dictionary] = SkillTree.get_learnable_skills(class_data.class_name_text)
		for entry in learnable:
			if entry["id"] in learned:
				var skill: SkillData = entry["skill"]
				if skill not in class_data.skills:
					class_data.skills.append(skill)
	
	print("[Training] Restored %d learned skills from save" % learned.size())
