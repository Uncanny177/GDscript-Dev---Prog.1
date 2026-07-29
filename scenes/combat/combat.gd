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
var selected_target_index: int = 0

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
		info_label.text = "%s's turn!\n\n[1] Attack\n[2] Defend\n[3] Flee" % combatant.display_name


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
	else:
		_handle_menu_input(event)


func _handle_menu_input(event: InputEventKey) -> void:
	## Handle action menu input (1=Attack, 2=Defend, 3=Flee).
	
	match event.keycode:
		KEY_1:
			# Attack — go to target selection
			_show_target_select()
		KEY_2:
			# Defend
			awaiting_player_input = false
			turn_manager.execute_defend(turn_manager.current_combatant)
			_add_log("%s defends!" % turn_manager.current_combatant.display_name)
			_update_ui()
			_continue_after_action()
		KEY_3:
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
			# Confirm attack on selected target
			target_select_mode = false
			awaiting_player_input = false
			var target: Combatant = enemies[selected_target_index]
			turn_manager.execute_attack(turn_manager.current_combatant, target)
			_update_ui()
			_continue_after_action()
		KEY_ESCAPE:
			# Go back to action menu
			target_select_mode = false
			_show_player_menu(turn_manager.current_combatant)
		_:
			# Number keys for direct target selection
			var num: int = event.keycode - KEY_1  # KEY_1=0, KEY_2=1, etc.
			if num >= 0 and num < enemies.size():
				target_select_mode = false
				awaiting_player_input = false
				var target: Combatant = enemies[num]
				turn_manager.execute_attack(turn_manager.current_combatant, target)
				_update_ui()
				_continue_after_action()


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
