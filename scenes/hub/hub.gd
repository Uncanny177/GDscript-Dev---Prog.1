## Hub Town — The persistent safe zone between dungeon runs.
##
## KEY CONCEPT: INTERACTING WITH AUTOLOADS
## Notice how we just type "GameManager.start_run()" — no imports needed.
## Autoloads are globally accessible by their registered name.
## This is the main way different scenes communicate through shared state.
##
## KEY CONCEPT: INPUT ACTIONS
## Input.is_action_just_pressed("action_name") checks the input map.
## We define "interact" below — in a real project, you'd add this in
## Project Settings → Input Map in the Godot editor.

extends Node2D

@onready var info_label: Label = $CanvasLayer/InfoLabel
@onready var stats_label: Label = $CanvasLayer/StatsLabel


func _ready() -> void:
	_update_ui()
	print("[Hub] Welcome to the Hub Town!")
	print("[Hub] Press ENTER to enter the dungeon")
	print("[Hub] Press Q to quit")


func _process(_delta: float) -> void:
	## _process runs every frame (for non-physics stuff like UI/input).
	## We check for the "enter dungeon" input here.
	
	if Input.is_action_just_pressed("ui_accept"):  # Enter/Space key
		_enter_dungeon()
	
	if Input.is_action_just_pressed("ui_cancel"):  # Escape key
		get_tree().quit()


func _enter_dungeon() -> void:
	## Start a new run and transition to the dungeon scene.
	GameManager.start_run()
	GameManager.change_scene("res://scenes/dungeon/dungeon.tscn")


func _update_ui() -> void:
	## Updates the HUD labels with current game state.
	if info_label:
		info_label.text = "HUB TOWN\n\nPress ENTER to enter dungeon\nPress ESC to quit"
	if stats_label:
		stats_label.text = "Gold: %d | Meta-Crystals: %d | Runs: %d" % [
			GameManager.current_gold,
			GameManager.meta_crystals,
			GameManager.total_runs
		]
