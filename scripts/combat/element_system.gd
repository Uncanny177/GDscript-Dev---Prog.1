## ElementSystem — Calculates elemental damage multipliers.
##
## ELEMENTS:
##   none (physical/untyped), fire, ice, dark, light
##
## WEAKNESS TABLE:
##   fire → strong against ice, weak against fire (resistant)
##   ice → strong against fire, weak against ice
##   dark → strong against light, weak against dark
##   light → strong against dark, weak against light
##   none → neutral against everything
##
## MULTIPLIERS:
##   Weak to (takes more): x1.5 damage
##   Resistant (takes less): x0.5 damage
##   Neutral: x1.0
##
## USAGE:
##   var mult: float = ElementSystem.get_multiplier("fire", "ice")  # → 1.5
##   var mult: float = ElementSystem.get_multiplier("fire", "fire") # → 0.5

class_name ElementSystem
extends RefCounted

## Elements strong against → weak against mapping
## Key attacks value for bonus damage
const STRONG_AGAINST: Dictionary = {
	"fire": "ice",
	"ice": "fire",
	"dark": "light",
	"light": "dark",
}

## Damage multiplier when attacker element is strong against target element
const WEAKNESS_MULTIPLIER: float = 1.5

## Damage multiplier when attacker element matches target element (resistance)
const RESISTANCE_MULTIPLIER: float = 0.5

## Normal (no elemental interaction)
const NEUTRAL_MULTIPLIER: float = 1.0


static func get_multiplier(attack_element: String, target_element: String) -> float:
	## Returns the damage multiplier based on elemental matchup.
	## attack_element: element of the skill/attack being used
	## target_element: elemental affinity of the target

	if attack_element == "none" or target_element == "none":
		return NEUTRAL_MULTIPLIER
	
	# Check if attacker is strong against target
	if STRONG_AGAINST.has(attack_element):
		if STRONG_AGAINST[attack_element] == target_element:
			return WEAKNESS_MULTIPLIER
	
	# Check if target resists this element (same element = resistant)
	if attack_element == target_element:
		return RESISTANCE_MULTIPLIER
	
	return NEUTRAL_MULTIPLIER


static func get_effectiveness_text(multiplier: float) -> String:
	## Returns a display string for the combat log.
	if multiplier > 1.0:
		return "It's super effective!"
	elif multiplier < 1.0:
		return "Not very effective..."
	return ""


static func get_effectiveness_color(multiplier: float) -> Color:
	## Color for UI display of effectiveness.
	if multiplier > 1.0:
		return Color(1.0, 0.4, 0.2)  # Orange/red for strong
	elif multiplier < 1.0:
		return Color(0.5, 0.5, 0.7)  # Gray/blue for weak
	return Color.WHITE
