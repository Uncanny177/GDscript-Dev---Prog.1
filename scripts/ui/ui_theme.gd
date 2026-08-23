## UITheme — Builds a cohesive dark-horror UI theme in code (no art assets).
##
## Applies a consistent look to all panels, labels, and buttons:
##   - Dark, desaturated backgrounds with subtle eerie accent borders
##   - Readable off-white text with a faint glow feel
##   - Rounded panels with shadow for depth
##
## Autoload. Call UITheme.apply_to(control) or use the shared theme resource.
## The horror palette: deep charcoal, blood-red and pale-violet accents.

extends Node

## ─── PALETTE ────────────────────────────────────────────────────

const BG_DEEP: Color = Color(0.06, 0.06, 0.09)       # Near-black charcoal
const BG_PANEL: Color = Color(0.11, 0.10, 0.14)      # Panel background
const BG_PANEL_LIGHT: Color = Color(0.16, 0.15, 0.20) # Raised elements
const ACCENT: Color = Color(0.55, 0.15, 0.25)        # Blood red accent
const ACCENT_DIM: Color = Color(0.30, 0.12, 0.18)    # Dim border
const ACCENT_VIOLET: Color = Color(0.45, 0.35, 0.60) # Eerie violet (sigils)
const TEXT_MAIN: Color = Color(0.88, 0.86, 0.82)     # Warm off-white
const TEXT_DIM: Color = Color(0.55, 0.53, 0.58)      # Muted text
const TEXT_HIGHLIGHT: Color = Color(0.95, 0.80, 0.55) # Amber highlight

## The shared theme resource all UI can use
var theme: Theme = null


func _ready() -> void:
	theme = _build_theme()
	print("[UITheme] Horror UI theme built")


## ─── PUBLIC API ─────────────────────────────────────────────────

func apply_to(control: Control) -> void:
	## Apply the shared theme to a control (and its children via inheritance).
	if control and theme:
		control.theme = theme


func make_panel_style() -> StyleBoxFlat:
	## Returns a styled panel box for menus (dark, bordered, rounded).
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG_PANEL
	sb.border_color = ACCENT_DIM
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(16)
	# Subtle shadow for depth
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	sb.shadow_size = 8
	return sb


func make_overlay_style() -> Color:
	## Dark overlay color for behind modal menus.
	return Color(0.0, 0.0, 0.02, 0.7)


## ─── THEME CONSTRUCTION ─────────────────────────────────────────

func _build_theme() -> Theme:
	## NOTE: This theme is applied SELECTIVELY via apply_to() on specific
	## menu panels only — NOT globally. It does not restyle gameplay UI.
	var t := Theme.new()
	t.default_font_size = 16
	
	# ── Button styling (safe to theme — buttons look better everywhere) ──
	_style_buttons(t)
	
	# ── Progress bars (HP/MP/Sanity) ──
	_style_progress_bars(t)
	
	return t


func _style_buttons(t: Theme) -> void:
	# Normal state
	var normal := StyleBoxFlat.new()
	normal.bg_color = BG_PANEL_LIGHT
	normal.border_color = ACCENT_DIM
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(8)
	t.set_stylebox("normal", "Button", normal)
	
	# Hover state
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.20, 0.16, 0.22)
	hover.border_color = ACCENT
	t.set_stylebox("hover", "Button", hover)
	
	# Pressed state
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = ACCENT_DIM
	pressed.border_color = ACCENT
	t.set_stylebox("pressed", "Button", pressed)
	
	# Focus state (keyboard navigation)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = TEXT_HIGHLIGHT
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(4)
	t.set_stylebox("focus", "Button", focus)
	
	t.set_color("font_color", "Button", TEXT_MAIN)
	t.set_color("font_hover_color", "Button", TEXT_HIGHLIGHT)
	t.set_color("font_pressed_color", "Button", TEXT_HIGHLIGHT)
	t.set_font_size("font_size", "Button", 16)


func _style_progress_bars(t: Theme) -> void:
	# Background track
	var bg := StyleBoxFlat.new()
	bg.bg_color = BG_DEEP
	bg.set_corner_radius_all(3)
	bg.border_color = ACCENT_DIM
	bg.set_border_width_all(1)
	t.set_stylebox("background", "ProgressBar", bg)
	
	# Fill
	var fill := StyleBoxFlat.new()
	fill.bg_color = ACCENT
	fill.set_corner_radius_all(3)
	t.set_stylebox("fill", "ProgressBar", fill)
	
	t.set_color("font_color", "ProgressBar", TEXT_MAIN)
