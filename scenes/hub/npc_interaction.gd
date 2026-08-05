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

## Reference to the shop UI (set by hub scene after spawning)
var shop_ui: Node = null

## Reference to the guild UI (set by hub scene after spawning)
var guild_ui: Node = null

## Reference to the town hall UI (set by hub scene after spawning)
var town_hall_ui: Node = null

## The NPC we're currently close enough to talk to (or null)
var nearby_npc: Area2D = null

## How close (in pixels) the player must be to interact
const INTERACT_DISTANCE: float = 48.0

## Reference to our parent (the player node)
@onready var player: Node2D = get_parent()


func _process(_delta: float) -> void:
	## Every frame, find the closest NPC within range.
	## If dialogue or shop is active, skip.
	
	if dialogue_box and dialogue_box.is_active:
		return
	if shop_ui and shop_ui.is_active:
		return
	if guild_ui and guild_ui.is_active:
		return
	if town_hall_ui and town_hall_ui.is_active:
		return
	
	_find_nearby_npc()


func _unhandled_input(event: InputEvent) -> void:
	## Listen for the interact key (E or ENTER) when near an NPC.
	
	if dialogue_box and dialogue_box.is_active:
		return
	if shop_ui and shop_ui.is_active:
		return
	if guild_ui and guild_ui.is_active:
		return
	if town_hall_ui and town_hall_ui.is_active:
		return
	
	if not event is InputEventKey and not event is InputEventJoypadButton:
		return
	if not event.is_pressed():
		return
	
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
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
	## Trigger interaction based on NPC type.
	
	var npc_name: String = npc.get_meta("npc_name", "???")
	var dialogue: Array = npc.get_meta("dialogue", ["..."])
	var is_entrance: bool = npc.get_meta("is_dungeon_entrance", false)
	var is_shop: bool = npc.get_meta("is_shop", false)
	var is_guild: bool = npc.get_meta("is_guild", false)
	var is_town_hall: bool = npc.get_meta("is_town_hall", false)
	
	if is_entrance:
		# Check if resuming a saved run
		if SaveManager.has_run_save():
			SaveManager.load_run()
		else:
			GameManager.start_run()
		TransitionManager.transition_to("res://scenes/dungeon/dungeon.tscn")
		return
	
	if is_shop and shop_ui:
		shop_ui.open_shop()
		return
	
	if is_guild and guild_ui:
		guild_ui.open_guild()
		return
	
	if is_town_hall and town_hall_ui:
		town_hall_ui.open_town_hall()
		return
	
	# Default: normal dialogue
	if dialogue_box:
		dialogue_box.start_dialogue(npc_name, dialogue)
