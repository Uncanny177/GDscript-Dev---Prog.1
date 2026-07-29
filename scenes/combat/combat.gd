## Combat Scene — Turn-based battle with real damage formulas.
##
## This is the CONTROLLER for combat. It:
##   1. Sets up combatants from PartyManager + random enemies
##   2. Runs the TurnManager to cycle through turns
##   3. Shows a text-based UI for player decisions
##   4. Handles enemy AI turns automatically
##   5. Resolves win/lose and returns to dungeon/hub
##
## KEY CONCEPT: ASYNC COMBAT FLOW
## Combat isn't instant — we need to show each action, pause for readability,
## then continue. We use await + signals + timers to create pacing.
## Without this, combat would resolve in a single frame (unreadable).
##
## KEY CONCEPT: SEPARATION OF CONCERNS
## - TurnManager: handles turn order and game rules
## - DamageCalculator: handles math
## - Combatant: handles individual state
## - This script: handles UI, input, and orchestration
## Each piece can be tested and changed independently.

extends Node2D

## UI references from the scene tree
@onready var info_label: Label = $CanvasLayer/InfoLabel
@onready var log_label: Label = $CanvasLayer/LogLabel

## Visual renderer for sprites, HP bars, damage numbers
var battle_renderer: Node2D = null

## The turn manager — drives the battle
var turn_manager: TurnManager = null

## All combatants for UI rendering
var player_combatants: Array[Combatant] = []
var enemy_combatants: Array[Combatant] = []

## State for player input
var awaiting_player_input: bool = false
var target_select_mode: bool = false
var skill_select_mode: bool = false
var ally_target_mode: bool = false
var selected_target_index: int = 0
var selected_skill_index: int = 0
var pending_skill: SkillData = null  # Skill chosen, waiting for target

## Combat log (last N messages shown on screen)
var combat_log: Array[String] = []
const MAX_LOG_LINES: int = 6

## Pause between actions for readability (seconds)
const ACTION_DELAY: float = 0.8


func _ready() -> void:
	_setup_battle()


func _setup_battle() -> void:
	## Initialize combatants and start the battle.
	
	# Create player combatants from party
	player_combatants.clear()
	for member in PartyManager.active_party:
		player_combatants.append(Combatant.from_character(member))
	
	# Create enemy combatants (random for current floor)
	enemy_combatants.clear()
	var enemy_pool: Array = EnemyDatabase.get_enemies_for_floor(GameManager.current_floor)
	var enemy_count: int = randi_range(1, 3)  # 1-3 enemies
	
	for i in range(enemy_count):
		if enemy_pool.is_empty():
			break
		var enemy_data: EnemyData = enemy_pool[randi() % enemy_pool.size()]
		var combatant: Combatant = Combatant.from_enemy(enemy_data)
		# Append letter to name if duplicate (Slime A, Slime B)
		if enemy_count > 1:
			combatant.display_name += " " + char(65 + i)  # A, B, C
		enemy_combatants.append(combatant)
	
	# Set up turn manager
	turn_manager = TurnManager.new()
	turn_manager.battle_won.connect(_on_battle_won)
	turn_manager.battle_lost.connect(_on_battle_lost)
	turn_manager.action_executed.connect(_on_action_executed)
	turn_manager.setup_battle(player_combatants, enemy_combatants)
	
	# Set up visual renderer
	var renderer_script: Script = load("res://scripts/combat/battle_renderer.gd")
	if renderer_script:
		battle_renderer = Node2D.new()
		battle_renderer.name = "BattleRenderer"
		battle_renderer.set_script(renderer_script)
		battle_renderer.player_combatants = player_combatants
		battle_renderer.enemy_combatants = enemy_combatants
		add_child(battle_renderer)
	
	_add_log("Battle start!")
	_update_ui()
	
	# Start first turn after a brief pause
	await get_tree().create_timer(0.5).timeout
	_start_next_turn()


func _start_next_turn() -> void:
	## Advance to the next turn. If it's a player, wait for input.
	## If it's an enemy, auto-execute AI after a delay.
	
	if not turn_manager.is_battle_active:
		return
	
	turn_manager.start_next_turn()
	var active: Combatant = turn_manager.current_combatant
	
	if not active:
		return
	
	_update_ui()
	
	if active.is_player:
		# Player's turn — show menu and wait for input
		awaiting_player_input = true
		target_select_mode = false
		_show_player_menu(active)
	else:
		# Enemy's turn — execute AI after delay
		awaiting_player_input = false
		await get_tree().create_timer(ACTION_DELAY).timeout
		if not turn_manager.is_battle_active:
			return  # Battle ended during the wait (e.g., scene changing)
		turn_manager.execute_enemy_turn(active)
		_update_ui()
		if not turn_manager.is_battle_active:
			return  # Battle ended from this attack
		await get_tree().create_timer(ACTION_DELAY).timeout
		_start_next_turn()


func _show_player_menu(combatant: Combatant) -> void:
	## Display the action menu for a player combatant.
	# Clear target highlight
	if battle_renderer:
		battle_renderer.highlighted_target = -1
		battle_renderer.refresh()
	
	if info_label:
		info_label.text = "%s's turn!  (MP: %d/%d)\n\n[1] Attack\n[2] Skill\n[3] Defend\n[4] Flee" % [combatant.display_name, combatant.current_mp, combatant.get_max_mp()]


func _show_target_select() -> void:
	## Show target selection for attack.
	var enemies: Array[Combatant] = turn_manager.get_alive_enemies()
	if enemies.is_empty():
		return
	
	# Only enter target mode (and reset index) if not already in it
	if not target_select_mode:
		selected_target_index = 0
		target_select_mode = true
	
	# Clamp index in case enemies died since last shown
	selected_target_index = clampi(selected_target_index, 0, enemies.size() - 1)
	
	# Update visual highlight
	if battle_renderer:
		battle_renderer.highlighted_target = selected_target_index
		battle_renderer.refresh()
	
	var text: String = "Select target:\n\n"
	for i in range(enemies.size()):
		var marker: String = "> " if i == selected_target_index else "  "
		text += "%s[%d] %s (HP: %d/%d)\n" % [marker, i + 1, enemies[i].display_name, enemies[i].current_hp, enemies[i].get_max_hp()]
	text += "\n[ENTER] Confirm  [ESC] Back"
	
	if info_label:
		info_label.text = text


func _unhandled_input(event: InputEvent) -> void:
	## Handle player combat input.
	
	if not event is InputEventKey or not event.pressed:
		return
	
	if not awaiting_player_input:
		return
	
	if target_select_mode:
		_handle_target_input(event)
	elif skill_select_mode:
		_handle_skill_input(event)
	elif ally_target_mode:
		_handle_ally_target_input(event)
	else:
		_handle_menu_input(event)


func _handle_menu_input(event: InputEventKey) -> void:
	## Handle action menu input (1=Attack, 2=Skill, 3=Defend, 4=Flee).
	
	match event.keycode:
		KEY_1:
			# Attack — go to target selection
			pending_skill = null
			_show_target_select()
		KEY_2:
			# Skill — show skill submenu
			_show_skill_menu()
		KEY_3:
			# Defend
			awaiting_player_input = false
			turn_manager.execute_defend(turn_manager.current_combatant)
			_add_log("%s defends!" % turn_manager.current_combatant.display_name)
			_update_ui()
			_continue_after_action()
		KEY_4:
			# Flee
			awaiting_player_input = false
			_add_log("Fled from battle!")
			GameManager.current_state = GameManager.GameState.DUNGEON
			GameManager.go_back()


func _handle_target_input(event: InputEventKey) -> void:
	## Handle target selection input.
	var enemies: Array[Combatant] = turn_manager.get_alive_enemies()
	if enemies.is_empty():
		target_select_mode = false
		_show_player_menu(turn_manager.current_combatant)
		return
	
	match event.keycode:
		KEY_UP, KEY_W:
			selected_target_index -= 1
			if selected_target_index < 0:
				selected_target_index = enemies.size() - 1
			_show_target_select()
		KEY_DOWN, KEY_S:
			selected_target_index += 1
			if selected_target_index >= enemies.size():
				selected_target_index = 0
			_show_target_select()
		KEY_ENTER, KEY_SPACE:
			# Confirm attack/skill on selected target
			target_select_mode = false
			awaiting_player_input = false
			var target: Combatant = enemies[selected_target_index]
			if pending_skill:
				_execute_skill_on_target(target)
			else:
				turn_manager.execute_attack(turn_manager.current_combatant, target)
			_update_ui()
			_continue_after_action()
		KEY_ESCAPE:
			# Go back to action menu
			target_select_mode = false
			pending_skill = null
			_show_player_menu(turn_manager.current_combatant)
		_:
			# Number keys for direct target selection
			var num: int = event.keycode - KEY_1  # KEY_1=0, KEY_2=1, etc.
			if num >= 0 and num < enemies.size():
				target_select_mode = false
				awaiting_player_input = false
				var target2: Combatant = enemies[num]
				if pending_skill:
					_execute_skill_on_target(target2)
				else:
					turn_manager.execute_attack(turn_manager.current_combatant, target2)
				_update_ui()
				_continue_after_action()


func _show_skill_menu() -> void:
	## Display the skill submenu listing all available skills.
	var combatant: Combatant = turn_manager.current_combatant
	var skills: Array = _get_combatant_skills(combatant)
	
	if skills.is_empty():
		if info_label:
			info_label.text = "No skills available!\n\n[ESC] Back"
		skill_select_mode = true
		return
	
	skill_select_mode = true
	selected_skill_index = 0
	
	var text: String = "SKILLS (MP: %d/%d):\n\n" % [combatant.current_mp, combatant.get_max_mp()]
	for i in range(skills.size()):
		var skill: SkillData = skills[i]
		var can_use: String = "" if skill.can_afford(combatant.current_mp) else " (no MP)"
		text += "[%d] %s  MP:%d%s\n" % [i + 1, skill.skill_name, skill.mp_cost, can_use]
	text += "\n[ESC] Back"
	
	if info_label:
		info_label.text = text


func _handle_skill_input(event: InputEventKey) -> void:
	## Handle input in the skill submenu.
	var combatant: Combatant = turn_manager.current_combatant
	var skills: Array = _get_combatant_skills(combatant)
	
	if event.keycode == KEY_ESCAPE:
		skill_select_mode = false
		_show_player_menu(combatant)
		return
	
	# Number key selects a skill
	var num: int = event.keycode - KEY_1
	if num >= 0 and num < skills.size():
		var skill: SkillData = skills[num]
		
		# Check MP
		if not skill.can_afford(combatant.current_mp):
			_add_log("Not enough MP!")
			return
		
		pending_skill = skill
		skill_select_mode = false
		
		# Determine what targeting to show based on skill target type
		match skill.target_type:
			SkillData.TargetType.SINGLE_ENEMY:
				_show_target_select()
			SkillData.TargetType.ALL_ENEMIES:
				# No target selection needed — hits all
				_execute_skill_aoe_enemies()
			SkillData.TargetType.SINGLE_ALLY:
				_show_ally_target_select()
			SkillData.TargetType.ALL_ALLIES:
				_execute_skill_aoe_allies()
			SkillData.TargetType.SELF:
				_execute_skill_on_self()


func _show_ally_target_select() -> void:
	## Show target selection for ally-targeting skills (heals, buffs).
	var allies: Array[Combatant] = turn_manager.get_alive_players()
	if allies.is_empty():
		return
	
	ally_target_mode = true
	selected_target_index = 0
	
	var text: String = "Select ally (%s):\n\n" % pending_skill.skill_name
	for i in range(allies.size()):
		var marker: String = "> " if i == selected_target_index else "  "
		text += "%s[%d] %s (HP: %d/%d)\n" % [marker, i + 1, allies[i].display_name, allies[i].current_hp, allies[i].get_max_hp()]
	text += "\n[ENTER] Confirm  [ESC] Back"
	
	if info_label:
		info_label.text = text


func _handle_ally_target_input(event: InputEventKey) -> void:
	## Handle input when selecting an ally target for heal/buff skills.
	var allies: Array[Combatant] = turn_manager.get_alive_players()
	if allies.is_empty():
		ally_target_mode = false
		_show_player_menu(turn_manager.current_combatant)
		return
	
	match event.keycode:
		KEY_UP, KEY_W:
			selected_target_index -= 1
			if selected_target_index < 0:
				selected_target_index = allies.size() - 1
			_show_ally_target_select()
		KEY_DOWN, KEY_S:
			selected_target_index += 1
			if selected_target_index >= allies.size():
				selected_target_index = 0
			_show_ally_target_select()
		KEY_ENTER, KEY_SPACE:
			ally_target_mode = false
			awaiting_player_input = false
			var target: Combatant = allies[selected_target_index]
			_execute_skill_on_ally(target)
			_update_ui()
			_continue_after_action()
		KEY_ESCAPE:
			ally_target_mode = false
			pending_skill = null
			_show_player_menu(turn_manager.current_combatant)
		_:
			var num: int = event.keycode - KEY_1
			if num >= 0 and num < allies.size():
				ally_target_mode = false
				awaiting_player_input = false
				var target: Combatant = allies[num]
				_execute_skill_on_ally(target)
				_update_ui()
				_continue_after_action()


func _execute_skill_on_target(target: Combatant) -> void:
	## Execute the pending skill on a single enemy target.
	var caster: Combatant = turn_manager.current_combatant
	if not pending_skill:
		return
	
	# Spend MP
	caster.current_mp -= pending_skill.mp_cost
	if caster.is_player and caster.character_data:
		caster.character_data.current_mp = caster.current_mp
	
	# Calculate and apply damage
	var damage: int = DamageCalculator.calculate_skill_damage(caster, target, pending_skill)
	var actual: int = target.take_damage(damage)
	
	_add_log("%s uses %s → %s: %d dmg" % [caster.display_name, pending_skill.skill_name, target.display_name, actual])
	
	if battle_renderer:
		var idx: int = enemy_combatants.find(target)
		battle_renderer.show_damage_on_enemy(idx, actual)
	
	if not target.is_alive:
		turn_manager.combatant_died.emit(target)
	
	turn_manager._check_battle_end()
	if turn_manager.is_battle_active:
		turn_manager._advance_index()
	
	pending_skill = null


func _execute_skill_aoe_enemies() -> void:
	## Execute the pending skill on ALL alive enemies.
	var caster: Combatant = turn_manager.current_combatant
	if not pending_skill:
		return
	
	awaiting_player_input = false
	
	# Spend MP
	caster.current_mp -= pending_skill.mp_cost
	if caster.is_player and caster.character_data:
		caster.character_data.current_mp = caster.current_mp
	
	var enemies: Array[Combatant] = turn_manager.get_alive_enemies()
	_add_log("%s uses %s on all enemies!" % [caster.display_name, pending_skill.skill_name])
	
	for enemy in enemies:
		var damage: int = DamageCalculator.calculate_skill_damage(caster, enemy, pending_skill)
		var actual: int = enemy.take_damage(damage)
		
		if battle_renderer:
			var idx: int = enemy_combatants.find(enemy)
			battle_renderer.show_damage_on_enemy(idx, actual)
		
		if not enemy.is_alive:
			turn_manager.combatant_died.emit(enemy)
	
	turn_manager._check_battle_end()
	if turn_manager.is_battle_active:
		turn_manager._advance_index()
	
	pending_skill = null
	_update_ui()
	_continue_after_action()


func _execute_skill_on_ally(target: Combatant) -> void:
	## Execute a healing/buff skill on an ally.
	var caster: Combatant = turn_manager.current_combatant
	if not pending_skill:
		return
	
	# Spend MP
	caster.current_mp -= pending_skill.mp_cost
	if caster.is_player and caster.character_data:
		caster.character_data.current_mp = caster.current_mp
	
	# Calculate heal amount
	var heal_amount: int = DamageCalculator.calculate_healing(caster, pending_skill.power_multiplier)
	
	# Apply heal (cap at max HP)
	var old_hp: int = target.current_hp
	target.current_hp = mini(target.current_hp + heal_amount, target.get_max_hp())
	var actual_heal: int = target.current_hp - old_hp
	
	# Sync to character data
	if target.is_player and target.character_data:
		target.character_data.current_hp = target.current_hp
	
	_add_log("%s uses %s → %s: +%d HP" % [caster.display_name, pending_skill.skill_name, target.display_name, actual_heal])
	
	if battle_renderer:
		var idx: int = player_combatants.find(target)
		battle_renderer.show_heal_on_player(idx, actual_heal)
	
	turn_manager._advance_index()
	pending_skill = null


func _execute_skill_aoe_allies() -> void:
	## Execute a healing/buff skill on ALL alive allies.
	var caster: Combatant = turn_manager.current_combatant
	if not pending_skill:
		return
	
	awaiting_player_input = false
	
	# Spend MP
	caster.current_mp -= pending_skill.mp_cost
	if caster.is_player and caster.character_data:
		caster.character_data.current_mp = caster.current_mp
	
	var allies: Array[Combatant] = turn_manager.get_alive_players()
	_add_log("%s uses %s on all allies!" % [caster.display_name, pending_skill.skill_name])
	
	for ally in allies:
		var heal_amount: int = DamageCalculator.calculate_healing(caster, pending_skill.power_multiplier)
		var old_hp: int = ally.current_hp
		ally.current_hp = mini(ally.current_hp + heal_amount, ally.get_max_hp())
		var actual_heal: int = ally.current_hp - old_hp
		
		if ally.is_player and ally.character_data:
			ally.character_data.current_hp = ally.current_hp
		
		if battle_renderer:
			var idx: int = player_combatants.find(ally)
			battle_renderer.show_heal_on_player(idx, actual_heal)
	
	turn_manager._advance_index()
	pending_skill = null
	_update_ui()
	_continue_after_action()


func _execute_skill_on_self() -> void:
	## Execute a self-targeting skill.
	var caster: Combatant = turn_manager.current_combatant
	_execute_skill_on_ally(caster)
	_update_ui()
	_continue_after_action()


func _get_combatant_skills(combatant: Combatant) -> Array:
	## Get the skill list for a combatant from their class data.
	if combatant.is_player and combatant.character_data and combatant.character_data.character_class:
		return combatant.character_data.character_class.skills
	return []


func _continue_after_action() -> void:
	## Wait a beat after an action, then start next turn.
	await get_tree().create_timer(ACTION_DELAY).timeout
	if not turn_manager.is_battle_active:
		return  # Battle ended — don't continue cycling turns
	_start_next_turn()


## ─── SIGNAL HANDLERS ────────────────────────────────────────────

func _on_action_executed(_attacker: Combatant, target: Combatant, damage: int, action_name: String) -> void:
	## Called when any action resolves. Updates the combat log and visuals.
	if action_name == "Attack":
		_add_log("%s → %s: %d dmg" % [_attacker.display_name, target.display_name, damage])
		
		# Show damage number on the target
		if battle_renderer and damage > 0:
			if target.is_player:
				var idx: int = player_combatants.find(target)
				battle_renderer.show_damage_on_player(idx, damage)
			else:
				var idx: int = enemy_combatants.find(target)
				battle_renderer.show_damage_on_enemy(idx, damage)
	elif action_name == "Defend":
		_add_log("%s defends" % _attacker.display_name)
	
	# Refresh visuals (HP bars, death states)
	if battle_renderer:
		battle_renderer.refresh()


func _on_battle_won() -> void:
	## All enemies defeated! Calculate rewards and return.
	var gold_earned: int = 0
	for enemy in enemy_combatants:
		if enemy.enemy_data:
			gold_earned += enemy.enemy_data.gold_reward
	
	GameManager.add_gold(gold_earned)
	_add_log("VICTORY! +%d gold" % gold_earned)
	_update_ui()
	
	if info_label:
		info_label.text = "VICTORY!\n\n+%d gold earned\n\n[ENTER] Continue" % gold_earned
	
	# Wait for player to press enter
	awaiting_player_input = false
	await _wait_for_confirm()
	GameManager.current_state = GameManager.GameState.DUNGEON
	GameManager.go_back()


func _on_battle_lost() -> void:
	## All party members dead. End the run.
	_add_log("DEFEAT...")
	_update_ui()
	
	if info_label:
		info_label.text = "DEFEAT...\n\nYour party has fallen.\n\n[ENTER] Return to Hub"
	
	awaiting_player_input = false
	await _wait_for_confirm()
	GameManager.end_run(false)
	GameManager.change_scene("res://scenes/hub/hub.tscn")


func _wait_for_confirm() -> void:
	## Utility: pause execution until player presses ENTER or SPACE.
	## This uses a simple polling approach with await.
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_accept"):
			break


## ─── UI ─────────────────────────────────────────────────────────

func _update_ui() -> void:
	## Refresh the combat log display and status.
	
	# Refresh visual renderer
	if battle_renderer:
		battle_renderer.refresh()
	
	if log_label:
		var party_status: String = "── PARTY ──\n"
		for pc in player_combatants:
			var status: String = "DEAD" if not pc.is_alive else ("DEF" if pc.is_defending else "")
			party_status += "  %s: %d/%d HP %s\n" % [pc.display_name, pc.current_hp, pc.get_max_hp(), status]
		
		party_status += "\n── ENEMIES ──\n"
		for enemy in enemy_combatants:
			var status: String = "DEAD" if not enemy.is_alive else ""
			party_status += "  %s: %d/%d HP %s\n" % [enemy.display_name, enemy.current_hp, enemy.get_max_hp(), status]
		
		party_status += "\n── LOG ──\n"
		for line in combat_log:
			party_status += "  " + line + "\n"
		
		log_label.text = party_status


func _add_log(message: String) -> void:
	## Add a message to the combat log. Trims old entries.
	combat_log.append(message)
	if combat_log.size() > MAX_LOG_LINES:
		combat_log.pop_front()
