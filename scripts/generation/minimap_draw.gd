## MinimapDraw — The Control node that actually draws the minimap.
## Separated from the CanvasLayer because CanvasLayer can't _draw().

extends Control

var minimap = null  # Reference to parent Minimap script


func _draw() -> void:
	if not minimap or not minimap.generator:
		return
	
	var gen: FloorGenerator = minimap.generator
	var map_size: int = minimap.MAP_SIZE
	
	# Background
	draw_rect(Rect2(Vector2.ZERO, Vector2(map_size, map_size)), minimap.BG_COLOR, true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(map_size, map_size)), minimap.BORDER_COLOR, false, 1.0)
	
	# Calculate scale — fit the entire floor into the minimap square
	var scale_x: float = float(map_size) / float(gen.floor_width)
	var scale_y: float = float(map_size) / float(gen.floor_height)
	var tile_scale: float = minf(scale_x, scale_y)
	
	# Center the map if it doesn't fill the whole square
	var offset_x: float = (map_size - gen.floor_width * tile_scale) / 2.0
	var offset_y: float = (map_size - gen.floor_height * tile_scale) / 2.0
	
	# Draw tiles
	var px: float = maxf(tile_scale, 1.0)
	
	for y in range(gen.floor_height):
		for x in range(gen.floor_width):
			var tile: int = gen.get_tile(x, y)
			if tile == RoomTemplate.WALL:
				continue  # Skip walls (background is already dark)
			
			var pos := Vector2(offset_x + x * tile_scale, offset_y + y * tile_scale)
			var rect := Rect2(pos, Vector2(px, px))
			
			if tile == RoomTemplate.FLOOR or tile == RoomTemplate.DOOR:
				draw_rect(rect, minimap.MM_FLOOR, true)
	
	# Draw chests
	for chest_pos in gen.chest_spawn_points:
		var pos := Vector2(offset_x + chest_pos.x * tile_scale, offset_y + chest_pos.y * tile_scale)
		draw_rect(Rect2(pos, Vector2(px + 1, px + 1)), minimap.MM_CHEST, true)
	
	# Draw exit
	if gen.exit_position != Vector2i.ZERO:
		var pos := Vector2(offset_x + gen.exit_position.x * tile_scale, offset_y + gen.exit_position.y * tile_scale)
		draw_rect(Rect2(pos, Vector2(px + 1, px + 1)), minimap.MM_EXIT, true)
	
	# Draw enemies (from dungeon scene's enemy_markers)
	# We access these through the scene tree
	var dungeon: Node = get_tree().current_scene
	if dungeon and dungeon.has_method("_add_message"):  # Quick check it's dungeon scene
		if "enemy_markers" in dungeon:
			for marker in dungeon.enemy_markers:
				if is_instance_valid(marker):
					var tile_pos: Vector2i = marker.get_meta("tile_pos")
					var pos := Vector2(offset_x + tile_pos.x * tile_scale, offset_y + tile_pos.y * tile_scale)
					draw_rect(Rect2(pos, Vector2(px + 1, px + 1)), minimap.MM_ENEMY, true)
	
	# Draw player position (larger, bright blue)
	if minimap.player_node:
		var player_tile := Vector2i(
			floori(minimap.player_node.position.x / 32.0),
			floori(minimap.player_node.position.y / 32.0)
		)
		var pos := Vector2(offset_x + player_tile.x * tile_scale, offset_y + player_tile.y * tile_scale)
		draw_rect(Rect2(pos - Vector2(1, 1), Vector2(px + 2, px + 2)), minimap.MM_PLAYER, true)
