## BattleRenderer — Draws combatant sprites, HP bars, and damage numbers.
##
## KEY CONCEPT: VISUAL LAYER SEPARATION
## The combat LOGIC lives in combat.gd + turn_manager.gd (decides what happens).
## The combat VISUALS live here (decides what it looks like).
## This separation means you can change the look without breaking the logic.
##
## KEY CONCEPT: TWEENS FOR ANIMATION
## A Tween smoothly changes a value over time. We use them for:
## - Damage numbers floating up and fading out
## - HP bars smoothly draining (not instant jumps)
## - Combatant sprites flashing when hit
##
## This script is attached to a Node2D in the combat scene.
## It uses _draw() for the static elements (sprites, bars)
## and creates child nodes for animated elements (damage numbers).

extends Node2D

## References set by combat.gd after creating the renderer
var player_combatants: Array = []
var enemy_combatants: Array = []
var status_manager: StatusManager = null  # Set by combat.gd for status icon display

## Which enemy is currently targeted? -1 = none
var highlighted_target: int = -1

## Layout constants — positioned to fill the 1280x720 screen without
## overlapping the text panels (InfoLabel left-bottom, LogLabel right).
const PARTY_X: float = 180.0     # X position for party column
const ENEMY_X: float = 400.0     # X position for enemy column
const START_Y: float = 80.0      # Y start for first combatant
const SPACING_Y: float = 90.0    # Y gap between combatants
const SPRITE_SIZE: float = 40.0  # Size of placeholder sprite squares
const BAR_WIDTH: float = 80.0    # HP/MP bar width
const BAR_HEIGHT: float = 8.0    # HP/MP bar height
const BAR_OFFSET_Y: float = 30.0 # Distance below sprite center


func _draw() -> void:
	## Draw all combatant sprites, HP bars, and names.
	## Called every frame when queue_redraw() is active, or once on ready.
	
	_draw_party()
	_draw_enemies()


func _draw_party() -> void:
	## Draw party members on the left side with improved visuals.
	for i in range(player_combatants.size()):
		var combatant: Combatant = player_combatants[i]
		var pos := Vector2(PARTY_X, START_Y + i * SPACING_Y)
		
		# Shadow
		draw_rect(Rect2(pos + Vector2(-12, 18), Vector2(24, 8)), Color(0.0, 0.0, 0.0, 0.25), true)
		
		# Body (colored square with border)
		var sprite_rect := Rect2(pos - Vector2(SPRITE_SIZE / 2.0, SPRITE_SIZE / 2.0), Vector2(SPRITE_SIZE, SPRITE_SIZE))
		var color: Color = combatant.sprite_color
		if not combatant.is_alive:
			color = Color(0.3, 0.3, 0.3, 0.4)
		draw_rect(sprite_rect, color, true)
		draw_rect(sprite_rect, color.lightened(0.3), false, 1.5)  # Light border
		
		# Defend indicator
		if combatant.is_defending and combatant.is_alive:
			draw_rect(sprite_rect.grow(4), Color(0.3, 0.6, 1.0, 0.6), false, 2.0)
			draw_rect(sprite_rect.grow(6), Color(0.3, 0.6, 1.0, 0.3), false, 1.0)
		
		# Name above
		var font: Font = ThemeDB.fallback_font
		draw_string(font, pos + Vector2(-SPRITE_SIZE / 2.0, -SPRITE_SIZE / 2.0 - 6), combatant.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.9, 0.9))
		
		# HP bar
		var bar_pos := pos + Vector2(-BAR_WIDTH / 2.0, BAR_OFFSET_Y)
		_draw_bar(bar_pos, combatant.current_hp, combatant.get_max_hp(), Color(0.15, 0.75, 0.25), Color(0.6, 0.12, 0.12))
		
		# HP text
		var hp_text: String = "%d/%d" % [combatant.current_hp, combatant.get_max_hp()]
		draw_string(font, bar_pos + Vector2(0, BAR_HEIGHT + 12), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.75, 0.75, 0.75))
		
		# MP bar (smaller, below HP)
		var mp_pos := bar_pos + Vector2(0, BAR_HEIGHT + 16)
		_draw_bar(mp_pos, combatant.current_mp, combatant.get_max_mp(), Color(0.25, 0.4, 0.9), Color(0.1, 0.1, 0.25))
		
		# Status effect icons
		if status_manager:
			var icons: String = status_manager.get_status_icons(combatant)
			if icons != "":
				draw_string(font, mp_pos + Vector2(0, BAR_HEIGHT + 12), icons, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.9, 0.8, 0.3))


func _draw_enemies() -> void:
	## Draw enemies on the right side with improved visuals.
	for i in range(enemy_combatants.size()):
		var combatant: Combatant = enemy_combatants[i]
		var pos := Vector2(ENEMY_X, START_Y + i * SPACING_Y)
		
		# Shadow
		draw_rect(Rect2(pos + Vector2(-14, 18), Vector2(28, 8)), Color(0.0, 0.0, 0.0, 0.25), true)
		
		# Sprite (colored square with dark border)
		var sprite_rect := Rect2(pos - Vector2(SPRITE_SIZE / 2.0, SPRITE_SIZE / 2.0), Vector2(SPRITE_SIZE, SPRITE_SIZE))
		var color: Color = combatant.sprite_color
		if not combatant.is_alive:
			color = Color(0.25, 0.25, 0.25, 0.3)
		draw_rect(sprite_rect, color, true)
		draw_rect(sprite_rect, color.darkened(0.3), false, 1.5)  # Dark border
		
		# Highlight selected target
		if i == highlighted_target and combatant.is_alive:
			draw_rect(sprite_rect.grow(5), Color(1.0, 0.9, 0.2, 0.8), false, 2.5)
			draw_rect(sprite_rect.grow(8), Color(1.0, 0.9, 0.2, 0.3), false, 1.0)
			# Arrow
			var font: Font = ThemeDB.fallback_font
			var arrow_pos := pos + Vector2(-SPRITE_SIZE / 2.0 - 14, 4)
			draw_string(font, arrow_pos, ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.9, 0.2))
		
		# Name above
		var font: Font = ThemeDB.fallback_font
		draw_string(font, pos + Vector2(-SPRITE_SIZE / 2.0, -SPRITE_SIZE / 2.0 - 6), combatant.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.9, 0.9))
		
		# HP bar
		var bar_pos := pos + Vector2(-BAR_WIDTH / 2.0, BAR_OFFSET_Y)
		_draw_bar(bar_pos, combatant.current_hp, combatant.get_max_hp(), Color(0.8, 0.2, 0.15), Color(0.25, 0.08, 0.08))
		
		# HP text or DEFEATED
		if combatant.is_alive:
			var hp_text: String = "%d/%d" % [combatant.current_hp, combatant.get_max_hp()]
			draw_string(font, bar_pos + Vector2(0, BAR_HEIGHT + 12), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.75, 0.75, 0.75))
		else:
			draw_string(font, bar_pos + Vector2(0, BAR_HEIGHT + 12), "DEFEATED", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.5, 0.25, 0.25))


func _draw_bar(pos: Vector2, current: int, maximum: int, fill_color: Color, bg_color: Color) -> void:
	## Draw an HP/MP bar at the given position.
	## Background = full bar in dark color, foreground = fill based on ratio.
	
	var bg_rect := Rect2(pos, Vector2(BAR_WIDTH, BAR_HEIGHT))
	draw_rect(bg_rect, bg_color, true)
	
	if maximum > 0:
		var ratio: float = float(current) / float(maximum)
		ratio = clampf(ratio, 0.0, 1.0)
		var fill_rect := Rect2(pos, Vector2(BAR_WIDTH * ratio, BAR_HEIGHT))
		draw_rect(fill_rect, fill_color, true)
	
	# Border
	draw_rect(bg_rect, Color(0.5, 0.5, 0.5, 0.5), false, 1.0)


func show_damage_number(position_offset: Vector2, amount: int, is_heal: bool = false) -> void:
	## Spawn a floating damage number that rises and fades out.
	##
	## KEY CONCEPT: TWEEN ANIMATION
	## We create a Label, then use a Tween to:
	## 1. Move it upward (position.y decreases over time)
	## 2. Fade it out (modulate.a goes from 1 → 0)
	## 3. Delete it when done (queue_free)
	
	var label := Label.new()
	label.text = str(amount) if not is_heal else "+" + str(amount)
	label.position = position_offset
	label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3) if is_heal else Color(1.0, 0.3, 0.2))
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)
	
	# Animate: float up and fade out over 1 second
	var tween: Tween = create_tween()
	tween.set_parallel(true)  # Run both animations simultaneously
	tween.tween_property(label, "position:y", label.position.y - 30, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	
	# Delete the label after animation finishes
	tween.chain().tween_callback(label.queue_free)


func show_damage_on_enemy(enemy_index: int, amount: int) -> void:
	## Show damage number on a specific enemy.
	if enemy_index < 0 or enemy_index >= enemy_combatants.size():
		return
	var pos := Vector2(ENEMY_X + 20, START_Y + enemy_index * SPACING_Y - 20)
	show_damage_number(pos, amount, false)


func show_damage_on_player(player_index: int, amount: int) -> void:
	## Show damage number on a specific party member.
	if player_index < 0 or player_index >= player_combatants.size():
		return
	var pos := Vector2(PARTY_X + 20, START_Y + player_index * SPACING_Y - 20)
	show_damage_number(pos, amount, false)


func show_heal_on_player(player_index: int, amount: int) -> void:
	## Show heal number on a specific party member.
	if player_index < 0 or player_index >= player_combatants.size():
		return
	var pos := Vector2(PARTY_X + 20, START_Y + player_index * SPACING_Y - 20)
	show_damage_number(pos, amount, true)


func refresh() -> void:
	## Call this after any state change to redraw.
	queue_redraw()
