## ============================================================
## SANDBOX — Your GDScript playground / scratch pad
## ============================================================
##
## HOW TO USE:
## 1. Write any GDScript you want to test in the functions below
## 2. Run this scene in Godot (right-click sandbox.tscn → "Run This Scene"
##    or set it as main scene temporarily)
## 3. Output appears in Godot's Output panel (bottom of the editor)
##
## TIPS:
## - _ready() runs once when the scene loads — put your test code there
## - Use print() to see results in the Output panel
## - Create helper functions below to organize experiments
## - This file won't affect your main game — it's a separate scene
##
## WHEN YOU'RE DONE:
## - Leave your experiments here as notes, or clear them out
## - The main game scene is test_movement.tscn (set in project.godot)
## ============================================================

extends Node2D


func _ready() -> void:
	print("=== SANDBOX RUNNING ===")
	print("")
	
	# Call your test functions here:
	test_variables()
	test_functions()
	test_loops()
	
	print("")
	print("=== SANDBOX COMPLETE ===")


# ─── YOUR EXPERIMENTS GO BELOW ─────────────────────────────────

func test_variables() -> void:
	print("--- Variables & Types ---")
	
	# GDScript is dynamically typed BUT supports optional static typing
	# Static types catch bugs at write-time (like C++ but optional like Python)
	
	var name: String = "Hero"           # Explicit type
	var health: int = 100               # Integer
	var speed: float = 3.5              # Float
	var alive: bool = true              # Boolean
	var position: Vector2 = Vector2(5, 10)  # Godot's 2D vector
	
	# Type inference with := (lets Godot figure out the type)
	var damage := 25  # Godot infers this as int
	
	print("Name: ", name)
	print("Health: ", health)
	print("Speed: ", speed)
	print("Alive: ", alive)
	print("Position: ", position)
	print("Damage (inferred type): ", damage)
	print("")


func test_functions() -> void:
	print("--- Functions ---")
	
	# Functions use 'func', return types with ->, parameters with : Type
	var result := add_numbers(10, 20)
	print("10 + 20 = ", result)
	
	var greeting := greet("Player")
	print(greeting)
	
	# Try modifying these or adding your own!
	print("")


func add_numbers(a: int, b: int) -> int:
	## A simple function with typed parameters and return value.
	## -> int means "this function returns an int"
	return a + b


func greet(who: String) -> String:
	## String formatting — similar to Python f-strings but using % or +
	return "Hello, %s! Welcome to the dungeon." % who


func test_loops() -> void:
	print("--- Loops & Collections ---")
	
	# Arrays (like Python lists)
	var party: Array[String] = ["Warrior", "Mage", "Rogue"]
	print("Party: ", party)
	
	# For loop (Python-style)
	for member in party:
		print("  - ", member)
	
	# Range loop (like Python's range())
	print("Counting: ")
	for i in range(5):
		print("  ", i)  # 0, 1, 2, 3, 4
	
	# Dictionaries (like Python dicts)
	var stats: Dictionary = {
		"hp": 100,
		"atk": 15,
		"def": 10,
		"spd": 8
	}
	print("Stats: ", stats)
	print("HP: ", stats["hp"])
	
	# Iterating a dictionary
	for key in stats:
		print("  %s: %d" % [key, stats[key]])
	
	print("")


# ─── ADD MORE EXPERIMENTS HERE ──────────────────────────────────

# Example: Uncomment and modify these to try new concepts
#
# func test_classes() -> void:
#     print("--- Classes ---")
#     # Inner classes aren't common in GDScript — usually you make
#     # separate .gd files. But you can test logic here.
#     pass
#
# func test_signals() -> void:
#     print("--- Signals ---")
#     # Signals are Godot's event system — we'll cover these in Task 2
#     pass
#
# func test_match() -> void:
#     print("--- Match (like switch/case) ---")
#     var action := "attack"
#     match action:
#         "attack":
#             print("Swinging sword!")
#         "defend":
#             print("Raising shield!")
#         "heal":
#             print("Casting cure!")
#         _:  # Default case (like else)
#             print("Unknown action: ", action)
