## Combat Scene — Placeholder for turn-based battles.
##
## For now this just shows "you're in combat" and lets you win or flee.
## Task 5 will build the real combat system here.
##
## KEY CONCEPT: go_back()
## GameManager.go_back() returns to whatever scene we came FROM.
## This means combat doesn't need to know if it was triggered from
## floor 1 or floor 5 — it just returns to wherever it was called from.
## This is the decoupling benefit of a scene manager.

extends Node2D

@onready var info_label: Label = $CanvasLayer/InfoLabel


func _ready() -> void:
	print("[Combat] Battle started!")
	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W:
				_win_battle()
			KEY_F:
				_flee_battle()


func _win_battle() -> void:
	## Simulate winning — earn gold, return to dungeon.
	var gold_reward: int = randi_range(5, 20)  # Random int between 5-20
	GameManager.add_gold(gold_reward)
	GameManager.current_state = GameManager.GameState.DUNGEON
	print("[Combat] Victory! Earned %d gold" % gold_reward)
	GameManager.go_back()


func _flee_battle() -> void:
	## Run away — no reward, but return safely.
	GameManager.current_state = GameManager.GameState.DUNGEON
	print("[Combat] Fled from battle!")
	GameManager.go_back()


func _update_ui() -> void:
	if info_label:
		info_label.text = "COMBAT!\n\nW = Win battle (earn gold)\nF = Flee (no reward)"
