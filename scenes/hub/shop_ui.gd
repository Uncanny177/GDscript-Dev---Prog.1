## ShopUI — Handles the shop interface (buy/sell items with gold).
##
## KEY CONCEPT: MENU STATE
## The shop has two modes: BUY and SELL. Player toggles between them.
## Each mode shows a list of items with prices, and number keys select.
##
## This is created programmatically and attached to the hub scene
## when the player talks to the Shopkeeper NPC.

extends CanvasLayer

signal shop_closed

## Shop data (stock, transactions)
var shop: ShopData = ShopData.new()

## UI state
var is_active: bool = false
var mode: int = 0  # 0 = main menu, 1 = buy, 2 = sell

## UI nodes
var panel: PanelContainer = null
var content_label: Label = null


func _ready() -> void:
	_build_ui()
	panel.hide()


func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.name = "ShopPanel"
	panel.anchor_left = 0.05
	panel.anchor_right = 0.95
	panel.anchor_top = 0.05
	panel.anchor_bottom = 0.95
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_top = 0
	panel.offset_bottom = 0
	add_child(panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)
	
	content_label = Label.new()
	content_label.name = "ContentLabel"
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(content_label)
	
	panel.hide()


func open_shop() -> void:
	## Open the shop interface.
	shop.refresh_stock()
	is_active = true
	mode = 0
	_show_main_menu()
	panel.show()


func _show_main_menu() -> void:
	mode = 0
	var text: String = "═══ SHOP ═══\n"
	text += "Gold: %d\n\n" % GameManager.current_gold
	text += "[1] Buy\n"
	text += "[2] Sell\n"
	text += "[ESC] Leave\n"
	content_label.text = text


func _show_buy_menu() -> void:
	mode = 1
	var text: String = "═══ BUY ═══\n"
	text += "Gold: %d\n\n" % GameManager.current_gold
	
	var stock_display: Array[Dictionary] = shop.get_stock_display()
	if stock_display.is_empty():
		text += "Nothing for sale!\n"
	else:
		for i in range(stock_display.size()):
			var entry: Dictionary = stock_display[i]
			var item: ItemData = entry["item"]
			var afford: String = "" if entry["can_afford"] else " (can't afford)"
			text += "[%d] %s — %dG%s\n" % [i + 1, item.item_name, item.buy_price, afford]
	
	text += "\n[ESC] Back"
	content_label.text = text


func _show_sell_menu() -> void:
	mode = 2
	var text: String = "═══ SELL ═══\n"
	text += "Gold: %d\n\n" % GameManager.current_gold
	
	var items: Array = GameManager.inventory.get_all_items()
	if items.is_empty():
		text += "Nothing to sell!\n"
	else:
		for i in range(items.size()):
			var entry: Dictionary = items[i]
			var item: ItemData = entry["item"]
			var sell_price: int = item.get_sell_price()
			var sellable: String = "" if item.sellable else " (can't sell)"
			text += "[%d] %s x%d — %dG each%s\n" % [i + 1, item.item_name, entry["count"], sell_price, sellable]
	
	text += "\n[ESC] Back"
	content_label.text = text


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if not event is InputEventKey or not event.pressed:
		return
	
	get_viewport().set_input_as_handled()
	
	match mode:
		0: _handle_main_input(event)
		1: _handle_buy_input(event)
		2: _handle_sell_input(event)


func _handle_main_input(event: InputEventKey) -> void:
	match event.keycode:
		KEY_1:
			_show_buy_menu()
		KEY_2:
			_show_sell_menu()
		KEY_ESCAPE:
			_close()


func _handle_buy_input(event: InputEventKey) -> void:
	if event.keycode == KEY_ESCAPE:
		_show_main_menu()
		return
	
	var num: int = event.keycode - KEY_1
	var stock_display: Array[Dictionary] = shop.get_stock_display()
	if num >= 0 and num < stock_display.size():
		var item: ItemData = stock_display[num]["item"]
		if shop.buy_item(item):
			print("[Shop] Bought %s for %d gold" % [item.item_name, item.buy_price])
		else:
			print("[Shop] Can't afford %s" % item.item_name)
		_show_buy_menu()  # Refresh display


func _handle_sell_input(event: InputEventKey) -> void:
	if event.keycode == KEY_ESCAPE:
		_show_main_menu()
		return
	
	var num: int = event.keycode - KEY_1
	var items: Array = GameManager.inventory.get_all_items()
	if num >= 0 and num < items.size():
		var item: ItemData = items[num]["item"]
		if shop.sell_item(item):
			print("[Shop] Sold %s for %d gold" % [item.item_name, item.get_sell_price()])
		else:
			print("[Shop] Can't sell %s" % item.item_name)
		_show_sell_menu()  # Refresh display


func _close() -> void:
	panel.hide()
	is_active = false
	shop_closed.emit()
