## Minimap — Shows a small overview of the dungeon floor in the corner.
##
## Draws a scaled-down version of the floor tiles in a CanvasLayer
## so it stays fixed on screen while the camera moves.
## Shows: walls, floor, player position, chests, exit, enemies.
##
## Toggled with TAB key during dungeon exploration.

extends CanvasLayer

var is_visible: bool = true
var generator: FloorGenerator = null
var player_node: Node2D = null

## Minimap rendering settings
const MAP_SIZE: int = 140        # Pixel size of the minimap square
const MAP_MARGIN: int = 10       # Distance from screen edge
const PIXEL_SIZE: int = 2        # How many pixels per tile on minimap
const BG_COLOR := Color(0.0, 0.0, 0.0, 0.6)
const BORDER_COLOR := Color(0.4, 0.4, 0.5, 0.8)

## Tile colors on minimap
const MM_FLOOR := Color(0.2, 0.2, 0.25, 0.8)
const MM_WALL := Color(0.4, 0.35, 0.25, 0.8)
const MM_PLAYER := Color(0.2, 0.6, 1.0, 1.0)
const MM_CHEST := Color(0.95, 0.85, 0.2, 1.0)
const MM_EXIT := Color(0.3, 0.9, 0.3, 1.0)
const MM_ENEMY := Color(0.9, 0.2, 0.2, 0.9)

## Internal draw node (CanvasLayer can't draw directly)
var draw_node: Control = null


func _ready() -> void:
	layer = 50  # Above game, below transition overlay
	_build_ui()


func _build_ui() -> void:
	draw_node = Control.new()
	draw_node.name = "MinimapDraw"
	# Position in top-right corner
	draw_node.anchor_left = 1.0
	draw_node.anchor_right = 1.0
	draw_node.anchor_top = 0.0
	draw_node.anchor_bottom = 0.0
	draw_node.offset_left = -(MAP_SIZE + MAP_MARGIN)
	draw_node.offset_top = MAP_MARGIN
	draw_node.offset_right = -MAP_MARGIN
	draw_node.offset_bottom = MAP_SIZE + MAP_MARGIN
	draw_node.set_script(load("res://scripts/generation/minimap_draw.gd"))
	add_child(draw_node)
	draw_node.minimap = self


func setup(gen: FloorGenerator, player: Node2D) -> void:
	## Call after dungeon generation to provide data.
	generator = gen
	player_node = player
	if draw_node:
		draw_node.queue_redraw()


func _process(_delta: float) -> void:
	## Refresh minimap to track player position.
	if is_visible and draw_node and player_node:
		draw_node.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	## TAB toggles minimap visibility.
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		is_visible = not is_visible
		draw_node.visible = is_visible
