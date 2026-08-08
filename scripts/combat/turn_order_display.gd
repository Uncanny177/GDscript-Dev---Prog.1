## TurnOrderDisplay — Shows the upcoming turn order in combat.
##
## A vertical list on the side of the combat screen showing who goes
## next, color-coded by player/enemy. Highlights the active combatant.
##
## Drawn on a CanvasLayer so it stays fixed regardless of camera.

extends CanvasLayer

var turn_order: Array = []  # Array of Combatant (set by combat.gd)
var current_index: int = 0
var is_visible: bool = true

var draw_node: Control = null

const DISPLAY_X: float = 5.0
const DISPLAY_Y: float = 40.0
const ROW_HEIGHT: float = 18.0
const MAX_SHOWN: int = 8


func _ready() -> void:
	layer = 45  # Below minimap (50) but above game
	_build_ui()


func _build_ui() -> void:
	draw_node = Control.new()
	draw_node.name = "TurnOrderDraw"
	draw_node.anchor_left = 0.0
	draw_node.anchor_top = 0.0
	draw_node.offset_left = DISPLAY_X
	draw_node.offset_top = DISPLAY_Y
	draw_node.offset_right = 140.0
	draw_node.offset_bottom = DISPLAY_Y + MAX_SHOWN * ROW_HEIGHT + 30
	draw_node.set_script(load("res://scripts/combat/turn_order_draw.gd"))
	add_child(draw_node)
	draw_node.display = self


func update_order(order: Array, active_index: int) -> void:
	## Called by combat.gd whenever the turn advances.
	turn_order = order
	current_index = active_index
	if draw_node:
		draw_node.queue_redraw()


func set_display_visible(visible: bool) -> void:
	is_visible = visible
	if draw_node:
		draw_node.visible = visible
