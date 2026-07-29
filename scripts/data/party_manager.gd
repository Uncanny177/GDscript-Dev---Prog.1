## PartyManager — Manages the player's party (active and reserve characters).
##
## Another autoload that works alongside GameManager.
## GameManager handles game state (gold, floors, runs).
## PartyManager handles party state (who's in the party, their HP, etc.)
##
## WHY SEPARATE FROM GameManager?
## Single Responsibility — each manager handles one domain.
## As the game grows, GameManager would become 1000+ lines if we dumped
## everything in there. Splitting by domain keeps things manageable.

extends Node

## Maximum party size for active combat
const MAX_PARTY_SIZE: int = 4

## The active party (these fight in combat). Max 4.
var active_party: Array[CharacterData] = []

## Reserve characters (stored but not fighting). Swappable in town.
var reserve: Array[CharacterData] = []


func _ready() -> void:
	## Create a default starting party for testing.
	## Later this will be loaded from save data or set during recruitment.
	_create_default_party()


func _create_default_party() -> void:
	## Sets up a starting party with one of each class.
	## This lets us test combat immediately without building recruitment first.
	
	# Wait one frame for all autoloads to fully initialize.
	# ClassDatabase loads before us (listed earlier in project.godot),
	# but awaiting one frame ensures _ready() has completed on all of them.
	await get_tree().process_frame
	
	# Verify ClassDatabase is accessible
	if not ClassDatabase.classes.has("Warrior"):
		push_error("[PartyManager] ClassDatabase not ready — no classes found")
		return
	
	var warrior := CharacterData.new()
	warrior.character_name = "Roland"
	warrior.character_class = ClassDatabase.get_class("Warrior")
	warrior.initialize()
	
	var mage := CharacterData.new()
	mage.character_name = "Elara"
	mage.character_class = ClassDatabase.get_class("Mage")
	mage.initialize()
	
	var rogue := CharacterData.new()
	rogue.character_name = "Shadow"
	rogue.character_class = ClassDatabase.get_class("Rogue")
	rogue.initialize()
	
	active_party = [warrior, mage, rogue]
	
	print("[PartyManager] Default party created:")
	for member in active_party:
		print("  ", member)


func add_to_party(character: CharacterData) -> bool:
	## Add a character to active party. Returns false if party is full.
	if active_party.size() >= MAX_PARTY_SIZE:
		# Party full — add to reserve instead
		reserve.append(character)
		return false
	active_party.append(character)
	return true


func remove_from_party(index: int) -> CharacterData:
	## Remove character at index from active party. Moves to reserve.
	## Returns the removed character. Fails if only 1 member left.
	if active_party.size() <= 1:
		push_warning("[PartyManager] Can't remove last party member")
		return null
	var character: CharacterData = active_party[index]
	active_party.remove_at(index)
	reserve.append(character)
	return character


func swap_member(active_index: int, reserve_index: int) -> void:
	## Swap a party member with a reserve character.
	var temp: CharacterData = active_party[active_index]
	active_party[active_index] = reserve[reserve_index]
	reserve[reserve_index] = temp


func heal_all() -> void:
	## Fully restore all party members. Used when returning to hub.
	for member in active_party:
		member.full_heal()
	for member in reserve:
		member.full_heal()


func is_party_dead() -> bool:
	## Check if all active party members are dead (game over condition).
	for member in active_party:
		if member.is_alive:
			return false
	return true


func get_alive_members() -> Array[CharacterData]:
	## Returns only alive party members (for combat targeting).
	var alive: Array[CharacterData] = []
	for member in active_party:
		if member.is_alive:
			alive.append(member)
	return alive
