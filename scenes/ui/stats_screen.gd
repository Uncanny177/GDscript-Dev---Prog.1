## StatsScreen — Displays run history and lifetime stats.
## Accessible from the title screen or hub town.

extends CanvasLayer

signal stats_closed

var is_active: bool = false
var panel: PanelContainer = null
var content_label: Label = null
var mode: int = 0  # 0 = lifetime, 1 = history


func _ready() -> void:
	layer = 85  # Below pause menu (90) and settings (95)
	_build_ui()
	panel.hide()


func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.name = "StatsPanel"
	panel.anchor_left = 0.05
	panel.anchor_right = 0.95
	panel.anchor_top = 0.03
	panel.anchor_bottom = 0.97
	add_child(panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	
	content_label = Label.new()
	content_label.name = "ContentLabel"
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(content_label)
	
	panel.hide()


func open_stats() -> void:
	is_active = true
	mode = 0
	_refresh()
	panel.show()


func _refresh() -> void:
	var text: String = ""
	
	if mode == 0:
		text += "═══ LIFETIME STATS ═══\n\n"
		text += StatsTracker.get_lifetime_display()
		text += "\n[TAB] Run History  [ESC] Close"
	else:
		text += "═══ RUN HISTORY ═══\n\n"
		text += StatsTracker.get_history_display()
		text += "\n[TAB] Lifetime Stats  [ESC] Close"
	
	content_label.text = text


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if not event is InputEventKey or not event.pressed:
		return
	
	get_viewport().set_input_as_handled()
	
	match event.keycode:
		KEY_ESCAPE:
			_close()
		KEY_TAB:
			mode = 1 - mode  # Toggle 0↔1
			_refresh()


func _close() -> void:
	panel.hide()
	is_active = false
	stats_closed.emit()
