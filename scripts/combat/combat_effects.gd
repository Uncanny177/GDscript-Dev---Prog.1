## CombatEffects — Visual effects for combat actions using _draw() and tweens.
##
## Creates animated shapes (slashes, circles, particles) that play over
## combatants during attacks, skills, and healing. All procedural — no
## sprite assets needed.
##
## USAGE (from combat.gd):
##   combat_effects.play_attack(attacker_pos, target_pos)
##   combat_effects.play_skill(target_pos, "fire")
##   combat_effects.play_heal(target_pos)
##   combat_effects.play_hit_flash(target_pos)

extends Node2D

## Active effects being animated (cleaned up on completion)
var active_effects: Array[Dictionary] = []


func _process(delta: float) -> void:
	## Advance all active effects and redraw.
	var has_active: bool = false
	for effect in active_effects:
		effect["time"] += delta
		has_active = true
	
	# Remove expired effects
	active_effects = active_effects.filter(func(e): return e["time"] < e["duration"])
	
	if has_active or not active_effects.is_empty():
		queue_redraw()


func _draw() -> void:
	for effect in active_effects:
		var t: float = effect["time"] / effect["duration"]  # 0→1 progress
		match effect["type"]:
			"slash": _draw_slash(effect, t)
			"skill_fire": _draw_fire(effect, t)
			"skill_ice": _draw_ice(effect, t)
			"skill_dark": _draw_dark(effect, t)
			"skill_light": _draw_light(effect, t)
			"skill_generic": _draw_generic_skill(effect, t)
			"heal": _draw_heal(effect, t)
			"hit_flash": _draw_hit_flash(effect, t)
			"defend": _draw_defend(effect, t)
			"poison_tick": _draw_poison(effect, t)
			"burn_tick": _draw_burn(effect, t)


## ─── PUBLIC API ─────────────────────────────────────────────────

func play_attack(from_pos: Vector2, target_pos: Vector2) -> void:
	## Slash line from attacker toward target.
	active_effects.append({
		"type": "slash",
		"from": from_pos,
		"pos": target_pos,
		"time": 0.0,
		"duration": 0.3,
	})
	queue_redraw()


func play_skill(target_pos: Vector2, element: String = "none") -> void:
	## Elemental burst at target position.
	var effect_type: String = "skill_generic"
	match element:
		"fire": effect_type = "skill_fire"
		"ice": effect_type = "skill_ice"
		"dark": effect_type = "skill_dark"
		"light": effect_type = "skill_light"
	
	active_effects.append({
		"type": effect_type,
		"pos": target_pos,
		"time": 0.0,
		"duration": 0.5,
	})
	queue_redraw()


func play_heal(target_pos: Vector2) -> void:
	## Green rising particles at target.
	active_effects.append({
		"type": "heal",
		"pos": target_pos,
		"time": 0.0,
		"duration": 0.6,
	})
	queue_redraw()


func play_hit_flash(target_pos: Vector2) -> void:
	## White flash burst on hit.
	active_effects.append({
		"type": "hit_flash",
		"pos": target_pos,
		"time": 0.0,
		"duration": 0.15,
	})
	queue_redraw()


func play_defend(target_pos: Vector2) -> void:
	## Blue shield ripple.
	active_effects.append({
		"type": "defend",
		"pos": target_pos,
		"time": 0.0,
		"duration": 0.4,
	})
	queue_redraw()


func play_status_tick(target_pos: Vector2, status_type: String) -> void:
	## Small effect for DoT/HoT ticks.
	var effect_type: String = "poison_tick"
	if status_type == "burn":
		effect_type = "burn_tick"
	
	active_effects.append({
		"type": effect_type,
		"pos": target_pos,
		"time": 0.0,
		"duration": 0.4,
	})
	queue_redraw()


## ─── DRAW FUNCTIONS ─────────────────────────────────────────────

func _draw_slash(effect: Dictionary, t: float) -> void:
	## Diagonal slash line that appears and fades.
	var pos: Vector2 = effect["pos"]
	var alpha: float = 1.0 - t  # Fade out
	var length: float = 30.0 * t  # Grow
	var offset: Vector2 = Vector2(-length, -length)
	var end_offset: Vector2 = Vector2(length, length)
	
	draw_line(pos + offset, pos + end_offset, Color(1.0, 1.0, 1.0, alpha), 3.0)
	draw_line(pos + Vector2(-length, length), pos + Vector2(length, -length), Color(1.0, 0.9, 0.8, alpha * 0.5), 2.0)


func _draw_fire(effect: Dictionary, t: float) -> void:
	## Expanding orange/red circles.
	var pos: Vector2 = effect["pos"]
	var alpha: float = 1.0 - t
	var radius: float = 10.0 + 25.0 * t
	
	draw_circle(pos, radius, Color(1.0, 0.4, 0.0, alpha * 0.6))
	draw_circle(pos, radius * 0.6, Color(1.0, 0.7, 0.1, alpha * 0.8))
	draw_circle(pos, radius * 0.3, Color(1.0, 1.0, 0.5, alpha))


func _draw_ice(effect: Dictionary, t: float) -> void:
	## Blue crystal shards expanding outward.
	var pos: Vector2 = effect["pos"]
	var alpha: float = 1.0 - t
	var spread: float = 20.0 * t
	
	for i in range(6):
		var angle: float = i * PI / 3.0
		var shard_pos: Vector2 = pos + Vector2(cos(angle), sin(angle)) * spread
		draw_rect(Rect2(shard_pos - Vector2(3, 3), Vector2(6, 6)), Color(0.4, 0.7, 1.0, alpha), true)
	draw_circle(pos, 8.0 * (1.0 - t), Color(0.8, 0.9, 1.0, alpha))


func _draw_dark(effect: Dictionary, t: float) -> void:
	## Purple/black swirl.
	var pos: Vector2 = effect["pos"]
	var alpha: float = 1.0 - t
	var radius: float = 8.0 + 20.0 * t
	
	draw_circle(pos, radius, Color(0.3, 0.0, 0.4, alpha * 0.7))
	draw_circle(pos, radius * 0.5, Color(0.1, 0.0, 0.2, alpha))
	# Swirl particles
	for i in range(4):
		var angle: float = i * PI / 2.0 + t * PI * 4.0
		var p: Vector2 = pos + Vector2(cos(angle), sin(angle)) * radius * 0.7
		draw_circle(p, 3.0, Color(0.6, 0.2, 0.8, alpha))


func _draw_light(effect: Dictionary, t: float) -> void:
	## Golden rays expanding.
	var pos: Vector2 = effect["pos"]
	var alpha: float = 1.0 - t
	var radius: float = 15.0 + 20.0 * t
	
	draw_circle(pos, radius * 0.3, Color(1.0, 0.95, 0.7, alpha))
	for i in range(8):
		var angle: float = i * PI / 4.0
		var ray_end: Vector2 = pos + Vector2(cos(angle), sin(angle)) * radius
		draw_line(pos, ray_end, Color(1.0, 0.9, 0.3, alpha * 0.6), 2.0)


func _draw_generic_skill(effect: Dictionary, t: float) -> void:
	## White burst for untyped skills.
	var pos: Vector2 = effect["pos"]
	var alpha: float = 1.0 - t
	var radius: float = 5.0 + 20.0 * t
	
	draw_circle(pos, radius, Color(0.9, 0.9, 1.0, alpha * 0.5))
	draw_arc(pos, radius, 0, TAU, 16, Color(1.0, 1.0, 1.0, alpha), 2.0)


func _draw_heal(effect: Dictionary, t: float) -> void:
	## Green crosses/particles rising upward.
	var pos: Vector2 = effect["pos"]
	var alpha: float = 1.0 - t
	var rise: float = -20.0 * t  # Float upward
	
	for i in range(3):
		var offset_x: float = (i - 1) * 12.0
		var p: Vector2 = pos + Vector2(offset_x, rise - i * 5.0 * t)
		# Small cross shape
		draw_rect(Rect2(p - Vector2(1, 4), Vector2(3, 8)), Color(0.3, 1.0, 0.4, alpha), true)
		draw_rect(Rect2(p - Vector2(4, 1), Vector2(8, 3)), Color(0.3, 1.0, 0.4, alpha), true)


func _draw_hit_flash(effect: Dictionary, t: float) -> void:
	## Quick white flash expanding and fading instantly.
	var pos: Vector2 = effect["pos"]
	var alpha: float = 1.0 - t * 2.0  # Fades faster
	if alpha <= 0:
		return
	var radius: float = 5.0 + 15.0 * t
	draw_circle(pos, radius, Color(1.0, 1.0, 1.0, alpha))


func _draw_defend(effect: Dictionary, t: float) -> void:
	## Blue shield arc/ripple.
	var pos: Vector2 = effect["pos"]
	var alpha: float = 1.0 - t
	var radius: float = 15.0 + 10.0 * t
	
	draw_arc(pos, radius, -PI * 0.7, PI * 0.7, 12, Color(0.3, 0.6, 1.0, alpha), 3.0)
	draw_arc(pos, radius * 0.7, -PI * 0.5, PI * 0.5, 10, Color(0.5, 0.8, 1.0, alpha * 0.6), 2.0)


func _draw_poison(effect: Dictionary, t: float) -> void:
	## Green bubbles rising.
	var pos: Vector2 = effect["pos"]
	var alpha: float = 1.0 - t
	
	for i in range(3):
		var bx: float = pos.x + (i - 1) * 8.0
		var by: float = pos.y - 10.0 * t * (i + 1)
		draw_circle(Vector2(bx, by), 3.0 - t * 2.0, Color(0.3, 0.8, 0.2, alpha))


func _draw_burn(effect: Dictionary, t: float) -> void:
	## Small flame licks.
	var pos: Vector2 = effect["pos"]
	var alpha: float = 1.0 - t
	
	for i in range(3):
		var fx: float = pos.x + (i - 1) * 7.0
		var fy: float = pos.y - 8.0 * t - i * 3.0
		draw_circle(Vector2(fx, fy), 4.0 - t * 3.0, Color(1.0, 0.5, 0.0, alpha))
		draw_circle(Vector2(fx, fy - 3.0), 2.0, Color(1.0, 0.8, 0.2, alpha * 0.7))
