## TransitionManager — Handles screen fade transitions between scenes.
##
## Provides a smooth black fade-out → scene change → fade-in effect.
## Sits on a CanvasLayer at the highest layer so it draws over everything.
##
## USAGE (from other scripts):
##   TransitionManager.transition_to("res://scenes/hub/hub.tscn")
##
## This replaces direct calls to GameManager.change_scene() for
## smoother visual transitions. GameManager.change_scene still works
## for instant transitions (combat entry where speed matters).

extends CanvasLayer

## The black overlay rectangle
var overlay: ColorRect = null

## Animation state
var is_transitioning: bool = false

## Transition speed (seconds per fade)
const FADE_DURATION: float = 0.4

## Pending scene to load after fade-out completes
var pending_scene: String = ""


func _ready() -> void:
	# Set to highest layer so it draws over everything
	layer = 100
	
	# Create full-screen black overlay
	overlay = ColorRect.new()
	overlay.name = "TransitionOverlay"
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)  # Start fully transparent
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block clicks
	add_child(overlay)
	
	print("[TransitionManager] Initialized")


func transition_to(scene_path: String) -> void:
	## Fade out → change scene → fade in. Non-blocking from caller's perspective.
	if is_transitioning:
		return  # Don't stack transitions
	
	is_transitioning = true
	pending_scene = scene_path
	
	# Fade to black
	var tween: Tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(_on_fade_out_complete)


func fade_in() -> void:
	## Just fade in from black (used on scene _ready after a transition).
	## Called automatically after scene change, but can be called manually.
	var tween: Tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, FADE_DURATION)
	tween.tween_callback(_on_fade_in_complete)


func flash_white(duration: float = 0.15) -> void:
	## Quick white flash (for impacts, level ups, etc.)
	overlay.color = Color(1.0, 1.0, 1.0, 0.6)
	var tween: Tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, duration)


func _on_fade_out_complete() -> void:
	## Screen is fully black. Now change the scene.
	if pending_scene != "":
		# Store previous scene path in GameManager
		if get_tree().current_scene:
			GameManager.previous_scene_path = get_tree().current_scene.scene_file_path
		
		get_tree().change_scene_to_file(pending_scene)
		pending_scene = ""
	
	# Wait one frame for new scene to load, then fade in
	await get_tree().process_frame
	fade_in()


func _on_fade_in_complete() -> void:
	## Transition fully complete. Unlock.
	is_transitioning = false
