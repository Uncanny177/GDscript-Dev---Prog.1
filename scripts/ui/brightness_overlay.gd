## BrightnessOverlay — Global screen brightness control.
##
## Draws a full-screen overlay on the topmost layer that lightens or
## darkens everything. Controlled by a 0-200 brightness setting where:
##   100 = neutral (no overlay)
##   > 100 = brighter (white overlay, additive-ish via low alpha)
##   < 100 = darker (black overlay)
##
## The setting is stored/loaded by SettingsMenu and applied here.

extends CanvasLayer

var overlay: ColorRect = null

## Current brightness (100 = neutral). Range 50-150.
var brightness: int = 100


func _ready() -> void:
	layer = 128  # Absolute top — above everything including transitions
	_build_overlay()
	set_brightness(brightness)


func _build_overlay() -> void:
	overlay = ColorRect.new()
	overlay.name = "BrightnessRect"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Never blocks clicks
	overlay.color = Color(0, 0, 0, 0)  # Start transparent
	
	# Use additive/multiply blend so brightness looks natural, not foggy.
	# A CanvasItemMaterial with ADD blend brightens without washing to gray.
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	overlay.material = mat
	
	add_child(overlay)


func _input(event: InputEvent) -> void:
	## Global F11 fullscreen toggle — works from any screen.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()


func _toggle_fullscreen() -> void:
	var mode: int = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		print("[Brightness] Fullscreen OFF")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		print("[Brightness] Fullscreen ON")


func set_brightness(value: int) -> void:
	## value: 50 (dark) .. 100 (neutral) .. 150 (bright)
	brightness = clampi(value, 50, 150)
	if not overlay:
		return
	
	var mat := overlay.material as CanvasItemMaterial
	
	if brightness == 100:
		overlay.color = Color(0, 0, 0, 0)  # Neutral — no effect
	elif brightness < 100:
		# Darken with a normal black film (MIX blend)
		if mat:
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
		var darkness: float = float(100 - brightness) / 50.0 * 0.6  # up to 0.6 alpha
		overlay.color = Color(0, 0, 0, clampf(darkness, 0.0, 0.6))
	else:
		# Brighten with ADDITIVE blend — adds light instead of a gray film
		if mat:
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		var lightness: float = float(brightness - 100) / 50.0 * 0.25  # subtle add
		overlay.color = Color(0.5, 0.5, 0.5, clampf(lightness, 0.0, 0.25))
