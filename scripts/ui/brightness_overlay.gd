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
	
	if brightness == 100:
		overlay.color = Color(0, 0, 0, 0)  # Fully transparent
	elif brightness < 100:
		# Darken: black overlay, alpha scales with how far below 100
		var darkness: float = float(100 - brightness) / 100.0  # 0.0 .. 0.5
		overlay.color = Color(0, 0, 0, darkness)
	else:
		# Brighten: white overlay, alpha scales with how far above 100
		var lightness: float = float(brightness - 100) / 100.0  # 0.0 .. 0.5
		overlay.color = Color(1, 1, 1, lightness)
