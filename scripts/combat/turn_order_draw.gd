## TurnOrderDraw — Renders the turn order list.

extends Control

var display = null  # Reference to TurnOrderDisplay


func _draw() -> void:
	if not display or display.turn_order.is_empty():
		return
	if not display.is_visible:
		return
	
	var font: Font = ThemeDB.fallback_font
	var y: float = 0.0
	
	# Header
	draw_string(font, Vector2(0, y + 12), "TURN ORDER", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.7))
	y += 18.0
	
	# Draw separator line
	draw_rect(Rect2(0, y, 120, 1), Color(0.4, 0.4, 0.5, 0.5), true)
	y += 4.0
	
	# Show upcoming turns (from current_index forward, wrapping)
	var order: Array = display.turn_order
	var shown: int = 0
	var idx: int = display.current_index
	
	while shown < display.MAX_SHOWN and shown < order.size():
		var combatant = order[idx]
		
		# Skip dead combatants
		if not combatant.is_alive:
			idx = (idx + 1) % order.size()
			# Safety: prevent infinite loop if all dead
			shown += 1
			continue
		
		var is_active: bool = (shown == 0)  # First shown = currently acting
		var is_player: bool = combatant.is_player
		
		# Background highlight for active combatant
		if is_active:
			draw_rect(Rect2(0, y - 2, 125, display.ROW_HEIGHT), Color(0.3, 0.3, 0.4, 0.4), true)
		
		# Indicator dot (blue = player, red = enemy)
		var dot_color: Color = Color(0.3, 0.6, 1.0) if is_player else Color(0.9, 0.3, 0.2)
		draw_rect(Rect2(2, y + 3, 6, 6), dot_color, true)
		
		# Name (truncated to fit)
		var name_text: String = combatant.display_name
		if name_text.length() > 12:
			name_text = name_text.left(11) + "."
		
		var text_color: Color = Color(0.9, 0.9, 0.9) if is_active else Color(0.65, 0.65, 0.7)
		draw_string(font, Vector2(12, y + 12), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, text_color)
		
		# SPD value on the right
		var spd_text: String = str(combatant.get_spd())
		draw_string(font, Vector2(105, y + 12), spd_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.5, 0.5, 0.6))
		
		y += display.ROW_HEIGHT
		shown += 1
		idx = (idx + 1) % order.size()
