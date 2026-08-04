## StatusEffect — Defines a status condition applied to a combatant.
##
## Status effects tick at the START of the affected combatant's turn.
## They have a duration (in turns) and expire when it hits 0.
##
## TYPES:
##   POISON — Deals % max HP damage per turn. Doesn't kill (leaves at 1 HP).
##   BURN — Deals flat fire damage per turn. CAN kill.
##   STUN — Skips the combatant's turn entirely.
##   REGEN — Heals a flat amount per turn.
##   ATK_UP — Increases ATK by a percentage for duration.
##   DEF_DOWN — Decreases DEF by a percentage for duration.

class_name StatusEffect
extends RefCounted

enum Type {
	POISON,
	BURN,
	STUN,
	REGEN,
	ATK_UP,
	DEF_DOWN,
}

## What kind of status effect
var type: Type = Type.POISON

## How many turns remaining (decrements at start of affected's turn)
var duration: int = 3

## Strength/potency — meaning depends on type:
##   POISON: percentage of max HP dealt per turn (e.g., 10 = 10%)
##   BURN: flat damage per turn
##   STUN: unused (always skips turn)
##   REGEN: flat HP restored per turn
##   ATK_UP: percentage bonus (e.g., 25 = +25% ATK)
##   DEF_DOWN: percentage reduction (e.g., 30 = -30% DEF)
var potency: int = 10

## Who applied this (for UI display)
var source_name: String = ""


static func create(p_type: Type, p_duration: int, p_potency: int, p_source: String = "") -> StatusEffect:
	var effect := StatusEffect.new()
	effect.type = p_type
	effect.duration = p_duration
	effect.potency = p_potency
	effect.source_name = p_source
	return effect


func get_name() -> String:
	match type:
		Type.POISON: return "Poison"
		Type.BURN: return "Burn"
		Type.STUN: return "Stun"
		Type.REGEN: return "Regen"
		Type.ATK_UP: return "ATK Up"
		Type.DEF_DOWN: return "DEF Down"
		_: return "Unknown"


func get_icon() -> String:
	## Short icon for compact UI display.
	match type:
		Type.POISON: return "PSN"
		Type.BURN: return "BRN"
		Type.STUN: return "STN"
		Type.REGEN: return "RGN"
		Type.ATK_UP: return "ATK+"
		Type.DEF_DOWN: return "DEF-"
		_: return "???"


func get_color() -> Color:
	match type:
		Type.POISON: return Color(0.4, 0.8, 0.2)
		Type.BURN: return Color(1.0, 0.4, 0.1)
		Type.STUN: return Color(0.9, 0.9, 0.2)
		Type.REGEN: return Color(0.3, 1.0, 0.5)
		Type.ATK_UP: return Color(1.0, 0.5, 0.3)
		Type.DEF_DOWN: return Color(0.5, 0.3, 0.8)
		_: return Color.WHITE


func tick(target: Combatant) -> Dictionary:
	## Apply this effect for one turn. Returns result info for UI.
	## {"message": String, "damage": int, "heal": int, "skip_turn": bool}
	var result: Dictionary = {"message": "", "damage": 0, "heal": 0, "skip_turn": false}
	
	match type:
		Type.POISON:
			var dmg: int = maxi(target.get_max_hp() * potency / 100, 1)  # Integer division intentional
			# Poison doesn't kill — leave at 1 HP
			dmg = mini(dmg, target.current_hp - 1)
			if dmg > 0:
				target.current_hp -= dmg
				if target.is_player and target.character_data:
					target.character_data.current_hp = target.current_hp
				result["damage"] = dmg
				result["message"] = "%s takes %d poison damage!" % [target.display_name, dmg]
		
		Type.BURN:
			var dmg: int = potency
			var actual: int = target.take_damage(dmg)
			result["damage"] = actual
			result["message"] = "%s burns for %d damage!" % [target.display_name, actual]
		
		Type.STUN:
			result["skip_turn"] = true
			result["message"] = "%s is stunned and can't move!" % target.display_name
		
		Type.REGEN:
			var heal: int = potency
			var old_hp: int = target.current_hp
			target.current_hp = mini(target.current_hp + heal, target.get_max_hp())
			var actual_heal: int = target.current_hp - old_hp
			if target.is_player and target.character_data:
				target.character_data.current_hp = target.current_hp
			result["heal"] = actual_heal
			result["message"] = "%s regenerates %d HP!" % [target.display_name, actual_heal]
		
		Type.ATK_UP, Type.DEF_DOWN:
			# Stat modifiers don't do anything on tick — they modify stats passively
			result["message"] = ""
	
	duration -= 1
	return result


func is_expired() -> bool:
	return duration <= 0


func _to_string() -> String:
	return "%s (%d turns)" % [get_name(), duration]
