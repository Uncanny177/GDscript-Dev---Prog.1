## VignetteOverlay — A dark, foggy frame around the screen edges.
##
## Adds a full-screen ColorRect with the vignette shader on the top layer.
## Makes the game feel moody and claustrophobic (good for horror).
##
## The look is controlled by shader parameters you can tweak live in the
## Inspector OR change here in code:
##   - vignette_strength: how dark the edges get (0 = none, 1 = pitch black)
##   - vignette_radius:   how far in from the edge the darkness starts
##   - vignette_softness: how blurry/foggy the fade is
##
## It uses mouse_filter = IGNORE so it never blocks clicks/input.

extends CanvasLayer

var rect: ColorRect = null

## Tunable defaults (0..1). Change these to taste.
const STRENGTH: float = 0.55
const RADIUS: float = 0.72
const SOFTNESS: float = 0.45


func _ready() -> void:
	layer = 110  # Above gameplay + menus, below transitions (which are higher)
	_build()


func _build() -> void:
	rect = ColorRect.new()
	rect.name = "VignetteRect"
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # never blocks input

	# Load the shader and wrap it in a ShaderMaterial so we can apply it.
	var shader: Shader = load("res://scripts/ui/vignette.gdshader")
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("vignette_strength", STRENGTH)
	mat.set_shader_parameter("vignette_radius", RADIUS)
	mat.set_shader_parameter("vignette_softness", SOFTNESS)
	rect.material = mat

	add_child(rect)


## Adjust the vignette live from code (e.g. intensify at low sanity later).
func set_strength(value: float) -> void:
	if rect and rect.material:
		(rect.material as ShaderMaterial).set_shader_parameter("vignette_strength", clampf(value, 0.0, 1.0))
