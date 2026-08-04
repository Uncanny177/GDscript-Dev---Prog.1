## StatusManager — Tracks and processes status effects on all combatants.
##
## Sits alongside TurnManager during combat. At the start of each
## combatant's turn, their effects tick and expired ones are removed.
##
## Also provides stat modifiers — ATK_UP and DEF_DOWN adjust the
## combatant's effective stats during combat.

class_name StatusManager
extends RefCounted

## Map of combatant → array of active StatusEffects
var effects: Dictionary = {}  # Combatant → Array[StatusEffect]


func add_effect(target: Combatant, effect: StatusEffect) -> void:
	## Apply a status effect to a combatant.
	## If they already have the same type, refresh duration (don't stack).
	if not effects.has(target):
		effects[target] = []
	
	# Check for existing same-type effect (refresh instead of stacking)
	var existing_effects: Array = effects[target]
	for i in range(existing_effects.size()):
		if existing_effects[i].type == effect.type:
			# Refresh: take the longer duration and higher potency
			existing_effects[i].duration = maxi(existing_effects[i].duration, effect.duration)
			existing_effects[i].potency = maxi(existing_effects[i].potency, effect.potency)
			print("[Status] Refreshed %s on %s (%d turns)" % [effect.get_name(), target.display_name, existing_effects[i].duration])
			return
	
	existing_effects.append(effect)
	print("[Status] Applied %s to %s (%d turns)" % [effect.get_name(), target.display_name, effect.duration])


func process_turn_start(combatant: Combatant) -> Array[Dictionary]:
	## Called at the start of a combatant's turn. Ticks all their effects.
	## Returns array of tick results for UI display.
	var results: Array[Dictionary] = []
	
	if not effects.has(combatant):
		return results
	
	var active_effects: Array = effects[combatant]
	var to_remove: Array[int] = []
	
	for i in range(active_effects.size()):
		var effect: StatusEffect = active_effects[i]
		var result: Dictionary = effect.tick(combatant)
		if result["message"] != "":
			results.append(result)
		if effect.is_expired():
			to_remove.append(i)
	
	# Remove expired (iterate backwards to preserve indices)
	to_remove.reverse()
	for idx in to_remove:
		var expired: StatusEffect = active_effects[idx]
		print("[Status] %s expired on %s" % [expired.get_name(), combatant.display_name])
		active_effects.remove_at(idx)
	
	return results


func is_stunned(combatant: Combatant) -> bool:
	## Check if a combatant is currently stunned (skip their turn).
	if not effects.has(combatant):
		return false
	for effect in effects[combatant]:
		if effect.type == StatusEffect.Type.STUN and not effect.is_expired():
			return true
	return false


func get_atk_modifier(combatant: Combatant) -> float:
	## Returns ATK multiplier from status effects. 1.0 = normal.
	var modifier: float = 1.0
	if not effects.has(combatant):
		return modifier
	for effect in effects[combatant]:
		if effect.type == StatusEffect.Type.ATK_UP:
			modifier += float(effect.potency) / 100.0
	return modifier


func get_def_modifier(combatant: Combatant) -> float:
	## Returns DEF multiplier from status effects. 1.0 = normal.
	var modifier: float = 1.0
	if not effects.has(combatant):
		return modifier
	for effect in effects[combatant]:
		if effect.type == StatusEffect.Type.DEF_DOWN:
			modifier -= float(effect.potency) / 100.0
	return maxf(modifier, 0.1)  # Never reduce below 10%


func get_status_icons(combatant: Combatant) -> String:
	## Returns a compact string of active status icons for UI display.
	if not effects.has(combatant):
		return ""
	var icons: Array[String] = []
	for effect in effects[combatant]:
		icons.append(effect.get_icon())
	return " ".join(icons)


func clear_combatant(combatant: Combatant) -> void:
	## Remove all effects from a combatant (e.g., on death or battle end).
	effects.erase(combatant)


func clear_all() -> void:
	## Remove all effects from all combatants.
	effects.clear()
