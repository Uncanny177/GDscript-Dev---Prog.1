## NPCInteraction — Detects nearby NPCs and triggers dialogue.
##
## This script goes on the PLAYER (attached in hub_town.gd after spawning).
## It checks which NPCs the player is overlapping with and lets them
## press a key to talk.
##
## KEY CONCEPT: AREA2D OVERLAP DETECTION
## Area2D nodes can detect when other physics bodies enter their zone.
## But since we're doing grid-based movement, we use a simpler approach:
## check distance to NPCs each frame and track the nearest one.
##
## WHY NOT body_entered/body_exited SIGNALS?
## Those work for continuous movement but are finicky with grid teleporting
## (the player snaps between tiles). Distance-based is more reliable here.

extends Node

## Reference to the dialogue box (set by hub scene after spawning)
var dialogue_box: Node = null

## The NPC we're currently close enough to talk to (or null)
var nearby_npc: Area2D = null

## How close (in pixels) the player must be to interact
const INTERACT_DISTANCE: float = 48.0

## Reference to our parent (the player node)
@onready var player: Node2D = get_parent()


func _process(_delta: float) -> void:
	## Every frame, find the closest NPC within range.
	## If dialogue is active, skip (don't change targets mid-conversation).
	
	if dialogue_box and dialogue_box.is_active:
		return
	
	_find_nearby_npc()


func _unhandled_input(event: InputEvent) -> void:
	## Listen for the interact key (E or ENTER) when near an NPC.
	
	if dialogue_box and dialogue_box.is_active:
		return  # Dialogue box handles its own input
	
	if not event is InputEventKey or not event.pressed:
		return
	
	if event.keycode == KEY_E or event.keycode == KEY_ENTER:
		if nearby_npc:
			_interact_with_npc(nearby_npc)


func _find_nearby_npc() -> void:
	## Scan all Area2D nodes in the "npcs" group to find the closest one.
	## If it's within INTERACT_DISTANCE, mark it as interactable.
	
	var closest: Area2D = null
	var closest_dist: float = INTERACT_DISTANCE
	
	# get_tree().get_nodes_in_group() returns all nodes added to a group.
	# Groups are like tags — you can add any node to any named group.
	var npcs: Array = get_tree().get_nodes_in_group("npcs")
	
	for npc in npcs:
		var dist: float = player.position.distance_to(npc.position)
		if dist < closest_dist:
			closest = npc
			closest_dist = dist
	
	nearby_npc = closest


func _interact_with_npc(npc: Area2D) -> void:
	## Trigger dialogue with the given NPC.
	## Reads the NPC's name and dialogue from its metadata.
	
	var npc_name: String = npc.get_meta("npc_name", "???")
	var dialogue: Array = npc.get_meta("dialogue", ["..."])
	var is_entrance: bool = npc.get_meta("is_dungeon_entrance", false)
	
	if is_entrance:
		# Special case: dungeon entrance triggers a run
		GameManager.start_run()
		GameManager.change_scene("res://scenes/dungeon/dungeon.tscn")
		return
	
	# Start normal dialogue
	if dialogue_box:
		dialogue_box.start_dialogue(npc_name, dialogue)
