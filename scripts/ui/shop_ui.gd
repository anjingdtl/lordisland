class_name ShopUI
extends Control

## 商店 UI：买/卖物品
## 程序化构建

const ITEMS_PATH := "res://data/items.json"

signal closed
signal purchased(item_id: String)
signal sold(item_id: String)

var mode: String = "buy"  # "buy" or "sell"
var shop_items: Array = []  # [{id, price}, ...]
var item_data: Dictionary = {}
var _inventory: Inventory = null
var _buttons: Array[Button] = []
var _item_labels: Array[Label] = []
var _gold_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_data()
	_load_inventory()
	_build_ui()
	_refresh()

func _load_data() -> void:
	var f = FileAccess.open(ITEMS_PATH, FileAccess.READ)
	item_data = JSON.parse_string(f.get_as_text())
	# 默认商店商品：heal_potion, mana_potion, antidote, iron_sword, leather_armor
	for id in ["heal_potion", "mana_potion", "antidote", "iron_sword", "leather_armor"]:
		var d = item_data.get(id, {})
		if not d.is_empty():
			shop_items.append({"id": id, "price": d.get("price", 0)})

func _load_inventory() -> void:
	var globals = _get_globals()
	if globals and globals.inventory:
		_inventory = globals.inventory
	else:
		_inventory = Inventory.new()

func _build_ui() -> void:
	# 半透明背景
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# 标题
	var title = Label.new()
	title.text = TranslationServer.translate("shop_title")
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position.y = 30
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)
	# 金币
	_gold_label = Label.new()
	_gold_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_gold_label.position = Vector2(-260, 50)
	_gold_label.add_theme_font_size_override("font_size", 20)
	add_child(_gold_label)
	# 商品列表
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-200, 0)
	vbox.custom_minimum_size = Vector2(400, 0)
	add_child(vbox)
	for entry in shop_items:
		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(400, 40)
		var name_lbl = Label.new()
		var d = item_data.get(entry.id, {})
		var name_key = d.get("name_key", entry.id)
		name_lbl.text = "%s  %d 金币" % [TranslationServer.translate(name_key), entry.price]
		name_lbl.custom_minimum_size = Vector2(280, 0)
		name_lbl.add_theme_font_size_override("font_size", 18)
		hbox.add_child(name_lbl)
		_item_labels.append(name_lbl)
		var buy_btn = Button.new()
		buy_btn.text = TranslationServer.translate("shop_buy")
		buy_btn.custom_minimum_size = Vector2(100, 40)
		buy_btn.pressed.connect(_on_buy_pressed.bind(entry.id))
		hbox.add_child(buy_btn)
		vbox.add_child(hbox)
		_buttons.append(buy_btn)
	# 离开按钮
	var leave = Button.new()
	leave.text = TranslationServer.translate("shop_leave")
	leave.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	leave.position = Vector2(-150, -60)
	leave.custom_minimum_size = Vector2(120, 40)
	leave.pressed.connect(_on_leave_pressed)
	add_child(leave)

func _refresh() -> void:
	_gold_label.text = TranslationServer.translate("shop_gold") % _inventory.gold

func _on_buy_pressed(item_id: String) -> void:
	var entry = null
	for e in shop_items:
		if e.id == item_id:
			entry = e
			break
	if entry == null:
		return
	if _inventory.spend_gold(entry.price):
		_inventory.add_item(item_id, 1)
		var d = item_data.get(item_id, {})
		var name = TranslationServer.translate(d.get("name_key", item_id))
		print(TranslationServer.translate("shop_purchase_ok") % name)
		purchased.emit(item_id)
		_refresh()
	else:
		print(TranslationServer.translate("shop_purchase_fail"))

func _on_leave_pressed() -> void:
	closed.emit()
	queue_free()

func _get_globals() -> Node:
	for child in get_tree().root.get_children():
		if child.name == "GameGlobals":
			return child
	return null