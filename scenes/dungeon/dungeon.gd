## Dungeon Scene — Where the player explores procedural floors.
##
## For now this is a placeholder that lets you:
## - Simulate "exploring" by pressing SPACE to trigger a combat encounter
## - Press E to go to next floor
## - Die (press D) to test the death → hub flow
##
## Later this will have the real procedural generation from Task 9.

extends Node2D

@onready var info_label: Label = $CanvasLayer/InfoLabel
@onready var floor_label: Label = $CanvasLayer/FloorLabel


func _ready() -> void:
	_update_ui()
	print("[Dungeon] Entered floor %d" % GameManager.current_floor)


func _process(_delta: float) -> void:
	# SPACE = enter combat (simulated encounter)
	if Input.is_action_just_pressed("ui_accept"):
		_enter_combat()
	
	# E key = next floor (we'll check for this input action)
	if Input.is_key_pressed(KEY_E):
		# Small hack: only trigger once by checking if we just pressed
		# In a real game, stairs would be a physical trigger area
		if Input.is_action_just_pressed("ui_text_indent"):  # Tab key as stand-in
			pass
		_next_floor()
	
	# D key = simulate death (testing meta-progression on death)
	if Input.is_key_pressed(KEY_D) and Input.is_action_just_pressed("ui_end"):
		pass  # Handled below with a simpler check


func _unhandled_input(event: InputEvent) -> void:
	## _unhandled_input catches input that no other node consumed.
	## We use it here for our placeholder keys to avoid conflicts.
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_E:
				_next_floor()
			KEY_D:
				_simulate_death()
			KEY_B:
				_simulate_boss()


func _enter_combat() -> void:
	## Transition to combat. GameManager remembers we came from dungeon.
	GameManager.current_state = GameManager.GameState.COMBAT
	GameManager.add_gold(10)  # Simulate finding gold
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
