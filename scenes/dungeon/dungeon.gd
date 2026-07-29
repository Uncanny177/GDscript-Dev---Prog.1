## Dungeon Scene — Where the player explores procedural floors.
##
## For now this is a placeholder that lets you:
## - Press SPACE to trigger a combat encounter
## - Press E to go to next floor
## - Press D to simulate death (test death → hub flow)
## - Press B to simulate beating the boss
##
## Later this will have the real procedural generation from Task 9.

extends Node2D

@onready var info_label: Label = $CanvasLayer/InfoLabel
@onready var floor_label: Label = $CanvasLayer/FloorLabel


func _ready() -> void:
	_update_ui()
	print("[Dungeon] Entered floor %d" % GameManager.current_floor)


func _unhandled_input(event: InputEvent) -> void:
	## _unhandled_input catches keypresses that no other node consumed.
	## We use this single function for all our placeholder controls.
	
	if not event is InputEventKey:
		return
	if not event.pressed:
		return
	
	match event.keycode:
		KEY_SPACE:
			_enter_combat()
		KEY_E:
			_next_floor()
		KEY_D:
			_simulate_death()
		KEY_B:
			_simulate_boss()


func _enter_combat() -> void:
	## Transition to combat. GameManager remembers we came from dungeon.
	GameManager.current_state = GameManager.GameState.COMBAT
	GameManager.change_scene("res://scenes/combat/combat.tscn")


func _next_floor() -> void:
	## Advance to next floor. In the real game, this regenerates the dungeon.
	GameManager.current_floor += 1
	print("[Dungeon] Advanced to floor %d" % GameManager.current_floor)
	_update_ui()


func _simulate_death() -> void:
	## Player dies — end the run, return to hub.
	print("[Dungeon] Player defeated!")
	GameManager.end_run(false)
	GameManager.change_scene("res://scenes/hub/hub.tscn")


func _simulate_boss() -> void:
	## Beat the boss — end the run victoriously.
	print("[Dungeon] Boss defeated!")
	GameManager.end_run(true)
	GameManager.change_scene("res://scenes/hub/hub.tscn")


func _update_ui() -> void:
	if info_label:
		info_label.text = "DUNGEON\n\nSPACE = Combat encounter\nE = Next floor\nD = Simulate death\nB = Beat boss"
	if floor_label:
		floor_label.text = "Floor: %d | Gold: %d" % [GameManager.current_floor, GameManager.current_gold]
