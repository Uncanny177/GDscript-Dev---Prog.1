## DungeonEvent — Defines a random event the player encounters in the dungeon.
##
## Events are risk/reward choices. The player reads a description and picks
## from 2-3 options, each with different outcomes.
##
## EXAMPLE:
##   "You find a mysterious fountain..."
##   [1] Drink from it (70% heal, 30% poison)
##   [2] Toss a coin (lose 10G, gain a blessing)
##   [3] Walk away (nothing happens)

class_name DungeonEvent
extends RefCounted

## Event identity
var event_name: String = ""
var description: String = ""

## Choices available to the player
## Each: {"text": String, "outcomes": Array[Dictionary]}
## Outcome: {"weight": int, "type": String, "value": int/String, "message": String}
var choices: Array[Dictionary] = []


static func create(p_name: String, p_desc: String, p_choices: Array[Dictionary]) -> DungeonEvent:
	var event := DungeonEvent.new()
	event.event_name = p_name
	event.description = p_desc
	event.choices = p_choices
	return event


func resolve_choice(choice_index: int) -> Dictionary:
	## Resolve a player's choice. Rolls weighted outcome and returns result.
	## Returns: {"message": String, "type": String, "value": variant}
	
	if choice_index < 0 or choice_index >= choices.size():
		return {"message": "Nothing happens.", "type": "nothing", "value": 0}
	
	var choice: Dictionary = choices[choice_index]
	var outcomes: Array = choice.get("outcomes", [])
	
	if outcomes.is_empty():
		return {"message": "Nothing happens.", "type": "nothing", "value": 0}
	
	# Weighted random outcome selection
	var total_weight: int = 0
	for outcome in outcomes:
		total_weight += outcome.get("weight", 1)
	
	var roll: int = randi() % total_weight
	var cumulative: int = 0
	
	for outcome in outcomes:
		cumulative += outcome.get("weight", 1)
		if roll < cumulative:
			return outcome
	
	return outcomes[outcomes.size() - 1]
