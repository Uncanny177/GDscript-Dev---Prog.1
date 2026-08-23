## BrightnessOverlay — Global screen brightness + F11 fullscreen toggle.
##
## Full-screen ColorRect on the top layer. At 100 (default) it's fully
## transparent (no effect). Below 100 it darkens; above 100 it brightens
## using additive blend.

extends CanvasLayer

var overlay: ColorRect = null

## Current brightness (100 = neutral). Range 50-150.
var brightness: int = 100


func _ready() -> void:
	layer = 120
	_build_overlay()
	set_brightness(brightness)


func _build_overlay() -> void:
	overlay = ColorRect.new()
	overlay.name = "BrightnessRect"
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color(0, 0, 0, 0)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
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
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func set_brightness(value: int) -> void:
	## value: 50 (dark) .. 100 (neutral) .. 150 (bright)
	brightness = clampi(value, 50, 150)
	if not overlay:
		return
	var mat := overlay.material as CanvasItemMaterial
	if brightness <= 100:
		# Darken (or neutral): black film with MIX blend
		if mat:
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
		var darkness: float = float(100 - brightness) / 50.0 * 0.5
		overlay.color = Color(0, 0, 0, clampf(darkness, 0.0, 0.5))
	else:
		# Brighten: additive white
		if mat:
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		var lightness: float = float(brightness - 100) / 50.0 * 0.4
		overlay.color = Color(0.7, 0.7, 0.7, clampf(lightness, 0.0, 0.4))
