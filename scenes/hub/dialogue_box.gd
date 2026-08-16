## DialogueBox — A simple UI panel that displays NPC dialogue line by line.
##
## KEY CONCEPTS:
## - CanvasLayer: Makes UI stay fixed on screen (doesn't scroll with camera).
## - Control nodes: Godot's UI system. PanelContainer, Label, MarginContainer.
## - Visibility: show() / hide() to toggle UI elements on and off.
## - Input capture: When dialogue is showing, we consume input so the player
##   can't move while reading text.
##
## HOW IT WORKS:
## 1. Another script calls dialogue_box.start_dialogue(name, lines)
## 2. The box appears with the first line
## 3. Player presses SPACE/ENTER to advance
## 4. After the last line, the box hides and emits "dialogue_finished"
## 5. The player can move again

extends CanvasLayer

## Emitted when all dialogue lines have been shown and dismissed.
## Other scripts connect to this to know when dialogue is done.
signal dialogue_finished

## UI node references — set in _build_ui() since we construct programmatically
var panel: PanelContainer = null
var name_label: Label = null
var text_label: Label = null
var continue_label: Label = null

## The lines of dialogue to display
var lines: Array = []

## Parallel to `lines`: per-line speaker names for multi-speaker banter.
## Empty means single-speaker mode (name is set once in start_dialogue).
var speakers: Array = []

## Which line we're currently showing
var current_line: int = 0

## Is the dialogue box currently active?
var is_active: bool = false


func _ready() -> void:
	## Build the UI first, then hide it. It only appears when triggered.
	_build_ui()
	panel.hide()


func _build_ui() -> void:
	## Constructs the dialogue box UI from code.
	## In a real project, you'd build this visually in the editor.
	##
	## Structure:
	##   CanvasLayer (this node — keeps UI on screen)
	##     └── PanelContainer (the dark box at the bottom)
	##           └── MarginContainer (padding inside the box)
	##                 └── VBoxContainer (stacks name, text, continue vertically)
	##                       ├── NameLabel ("Shopkeeper")
	##                       ├── TextLabel ("Welcome to my shop!")
	##                       └── ContinueLabel ("[SPACE to continue]")
	
	# Create panel
	panel = PanelContainer.new()
	panel.name = "PanelContainer"
	# Position at bottom of screen
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 20.0
	panel.offset_right = -20.0
	panel.offset_top = -140.0
	panel.offset_bottom = -10.0
	add_child(panel)
	
	# Margin container for padding
	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	panel.add_child(margin)
	
	# Vertical layout
	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	margin.add_child(vbox)
	
	# NPC name
	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(name_label)
	
	# Dialogue text
	text_label = Label.new()
	text_label.name = "TextLabel"
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(text_label)
	
	# Continue prompt
	continue_label = Label.new()
	continue_label.name = "ContinueLabel"
	continue_label.text = "[SPACE to continue]"
	continue_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(continue_label)


func start_dialogue(npc_name: String, dialogue_lines: Array) -> void:
	## Call this to show the dialogue box with an NPC's lines.
	## The box takes over input until all lines are dismissed.
	
	lines = dialogue_lines
	speakers = []          # single-speaker mode
	current_line = 0
	is_active = true
	
	name_label.text = npc_name
	_show_current_line()
	panel.show()


func start_conversation(entries: Array) -> void:
	## Show a multi-speaker exchange (party banter). Each entry is a Dictionary
	## {"speaker": display_name, "text": line}. The name label updates per line.
	## Pairs with BanterSystem.format_lines(convo).
	lines = []
	speakers = []
	for entry in entries:
		lines.append(entry.get("text", ""))
		speakers.append(entry.get("speaker", ""))
	current_line = 0
	is_active = true
	
	_show_current_line()
	panel.show()


func _show_current_line() -> void:
	## Display the current line of dialogue.
	if current_line < lines.size():
		text_label.text = lines[current_line]
		
		# Multi-speaker mode: swap the name label to the current speaker.
		if current_line < speakers.size() and speakers[current_line] != "":
			name_label.text = speakers[current_line]
		
		# Show "continue" or "close" depending on if there are more lines
		if current_line < lines.size() - 1:
			continue_label.text = "[SPACE to continue]"
		else:
			continue_label.text = "[SPACE to close]"


func _unhandled_input(event: InputEvent) -> void:
	## When dialogue is active, intercept SPACE/ENTER to advance.
	## get_viewport().set_input_as_handled() prevents the input from
	## reaching other nodes (so the player doesn't move while reading).
	
	if not is_active:
		return
	
	if not event is InputEventKey:
		return
	
	if not event.pressed:
		return
	
	if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
		# Consume the input so nothing else reacts to it
		var viewport: Viewport = get_viewport()
		if viewport:
			viewport.set_input_as_handled()
		_advance_dialogue()


func _advance_dialogue() -> void:
	## Move to next line, or close if we're at the end.
	current_line += 1
	
	if current_line >= lines.size():
		# All lines shown — close the box
		_close()
	else:
		_show_current_line()


func _close() -> void:
	## Hide the dialogue box and let the player move again.
	panel.hide()
	is_active = false
	lines = []
	speakers = []
	current_line = 0
	dialogue_finished.emit()
