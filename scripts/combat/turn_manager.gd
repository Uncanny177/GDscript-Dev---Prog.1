## TurnManager — Controls the flow of turn-based combat.
##
## KEY CONCEPT: STATE MACHINE
## Combat has distinct phases that flow in order:
##   START → TURN_START → WAITING_FOR_ACTION → EXECUTING → TURN_END → (next turn)
##
## A state machine ensures we only do one thing at a time and transitions
## are explicit. No "what state are we in?" confusion.
##
## KEY CONCEPT: SIGNALS FOR ASYNC FLOW
## Combat is async — we show an attack animation, wait, show damage, wait.
## Signals let us say "do this, then when it's done, continue."
## This avoids blocking the game loop while waiting for animations.
##
## HOW TURNS WORK:
## 1. All combatants sorted by SPD (highest goes first)
## 2. Active combatant takes an action (player chooses, AI decides)
## 3. Action executes (damage applied, effects shown)
## 4. Check win/lose conditions
## 5. Next combatant's turn

class_name TurnManager
extends RefCounted

## Signals the combat scene listens to for UI updates
signal turn_started(combatant: Combatant)
signal action_executed(attacker: Combatant, target: Combatant, damage: int, action_name: String)
signal combatant_died(combatant: Combatant)
signal battle_won
signal battle_lost

## All combatants in this battle (players + enemies), sorted by SPD
var turn_order: Array[Combatant] = []

## Index of whose turn it is in turn_order
var current_turn_index: int = 0

## The combatant whose turn it currently is
var current_combatant: Combatant = null

## Is the battle still going?
var is_battle_active: bool = false


func setup_battle(party: Array[Combatant], enemies: Array[Combatant]) -> void:
	## Initialize a battle with the given parties.
	## Sorts everyone by SPD to determine turn order.
	
	turn_order.clear()
	turn_order.append_array(party)
	turn_order.append_array(enemies)
	
	# Sort by SPD descending (fastest goes first)
	# sort_custom takes a comparison function
	turn_order.sort_custom(_compare_by_speed)
	
	current_turn_index = 0
	is_battle_active = true
	
	print("[TurnManager] Battle started! Turn order:")
	for i in range(turn_order.size()):
		print("  %d. %s (SPD: %d)" % [i + 1, turn_order[i].display_name, turn_order[i].get_spd()])


func start_next_turn() -> void:
	## Advance to the next living combatant's turn.
	## Skips dead combatants. Emits turn_started when found.
	
	if not is_battle_active:
		return
	
	# Find next alive combatant
	var attempts: int = 0
	while attempts < turn_order.size():
		current_combatant = turn_order[current_turn_index]
		
		if current_combatant.is_alive:
			# Clear defend from previous round
			current_combatant.clear_defend()
			turn_started.emit(current_combatant)
			return
		
		# Skip dead combatants
		advance_index()
		attempts += 1
	
	# If we get here, everyone is dead (shouldn't happen — win/lose checks first)
	push_error("[TurnManager] No living combatants found")


func execute_attack(attacker: Combatant, target: Combatant) -> void:
	## Execute a basic physical attack. Apply damage formula.
	
	var damage: int = DamageCalculator.calculate_physical(attacker, target)
	var actual: int = target.take_damage(damage)
	
	action_executed.emit(attacker, target, actual, "Attack")
	print("[Combat] %s attacks %s for %d damage!" % [attacker.display_name, target.display_name, actual])
	
	if not target.is_alive:
		combatant_died.emit(target)
		print("[Combat] %s was defeated!" % target.display_name)
	
	check_battle_end()
	
	if is_battle_active:
		advance_index()


func execute_defend(combatant: Combatant) -> void:
	## Combatant defends — halves incoming damage until their next turn.
	
	combatant.defend()
	action_executed.emit(combatant, combatant, 0, "Defend")
	print("[Combat] %s is defending!" % combatant.display_name)
	
	advance_index()


func execute_enemy_turn(enemy: Combatant) -> void:
	## AI decides what to do for an enemy combatant.
	## For now: always attacks a random alive player character.
	
	var targets: Array[Combatant] = get_alive_players()
	
	if targets.is_empty():
		check_battle_end()
		return
	
	# Pick a random target
	var target: Combatant = targets[randi() % targets.size()]
	
	execute_attack(enemy, target)


## ─── QUERIES ────────────────────────────────────────────────────

func get_alive_players() -> Array[Combatant]:
	## Returns all living player combatants.
	var result: Array[Combatant] = []
	for c in turn_order:
		if c.is_player and c.is_alive:
			result.append(c)
	return result


func get_alive_enemies() -> Array[Combatant]:
	## Returns all living enemy combatants.
	var result: Array[Combatant] = []
	for c in turn_order:
		if not c.is_player and c.is_alive:
			result.append(c)
	return result


## ─── INTERNAL ───────────────────────────────────────────────────

func advance_index() -> void:
	## Move to next position in turn order (wraps around).
	current_turn_index = (current_turn_index + 1) % turn_order.size()


func check_battle_end() -> void:
	## Check if all players or all enemies are dead.
	
	var players_alive: bool = false
	var enemies_alive: bool = false
	
	for c in turn_order:
		if c.is_alive:
			if c.is_player:
				players_alive = true
			else:
				enemies_alive = true
	
	if not enemies_alive:
		is_battle_active = false
		battle_won.emit()
		print("[TurnManager] VICTORY!")
	elif not players_alive:
		is_battle_active = false
		battle_lost.emit()
		print("[TurnManager] DEFEAT...")


static func _compare_by_speed(a: Combatant, b: Combatant) -> bool:
	## Sort comparator: higher SPD goes first (descending order).
	## Returning true means a comes before b.
	return a.get_spd() > b.get_spd()
