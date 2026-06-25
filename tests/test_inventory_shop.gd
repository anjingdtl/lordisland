extends SceneTree

## 库存 + 商店系统测试

const Inventory = preload("res://scripts/core/inventory.gd")

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	var zh = ResourceLoader.load("res://locale/zh.po", "Translation")
	if zh is Translation:
		TranslationServer.add_translation(zh)
	TranslationServer.set_locale("zh")
	test_inventory_add_remove()
	test_inventory_gold()
	test_inventory_save_load()
	test_items_json()
	test_shop_logic()
	print("\n=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)

func assert_eq(value, expected, msg: String) -> void:
	if value == expected:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		print("FAIL: %s (got %s, expected %s)" % [msg, str(value), str(expected)])

func assert_true(value: bool, msg: String) -> void:
	assert_eq(value, true, msg)

func test_inventory_add_remove() -> void:
	var inv = Inventory.new()
	inv.add_item("heal_potion", 3)
	assert_eq(inv.count_item("heal_potion"), 3, "add 3 potions")
	inv.add_item("heal_potion", 2)
	assert_eq(inv.count_item("heal_potion"), 5, "add 2 more = 5")
	assert_true(inv.remove_item("heal_potion", 2), "remove 2 ok")
	assert_eq(inv.count_item("heal_potion"), 3, "3 left")
	assert_true(not inv.remove_item("heal_potion", 10), "remove too many fails")
	assert_eq(inv.count_item("heal_potion"), 3, "still 3 after failed remove")
	inv.remove_item("heal_potion", 3)
	assert_eq(inv.count_item("heal_potion"), 0, "all removed")
	assert_true(not inv.has_item("heal_potion"), "no more potions")

func test_inventory_gold() -> void:
	var inv = Inventory.new()
	assert_eq(inv.gold, 100, "default 100 gold")
	inv.add_gold(50)
	assert_eq(inv.gold, 150, "+50 = 150")
	assert_true(inv.spend_gold(30), "spend 30 ok")
	assert_eq(inv.gold, 120, "after spend 30 = 120")
	assert_true(not inv.spend_gold(500), "spend too much fails")
	assert_eq(inv.gold, 120, "gold unchanged after fail")

func test_inventory_save_load() -> void:
	var inv = Inventory.new()
	inv.add_item("heal_potion", 5)
	inv.add_gold(200)
	var data = inv.to_dict()
	var inv2 = Inventory.new()
	inv2.restore(data)
	assert_eq(inv2.count_item("heal_potion"), 5, "heal_potion restored")
	assert_eq(inv2.gold, 300, "gold restored")
	inv2.reset()
	assert_eq(inv2.gold, 100, "reset to 100")

func test_items_json() -> void:
	var f = FileAccess.open("res://data/items.json", FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	assert_true(data.has("heal_potion"), "heal_potion in items")
	assert_eq(data.heal_potion.price, 50, "heal_potion price 50")
	assert_true(data.has("iron_sword"), "iron_sword in items")
	assert_eq(data.iron_sword.amount, 5, "iron_sword STR +5")
	assert_eq(data.leather_armor.price, 250, "leather_armor price 250")

func test_shop_logic() -> void:
	# 模拟买/卖流程
	var inv = Inventory.new()
	# 初始 100 金币
	var potion_price = 50
	assert_true(inv.spend_gold(potion_price), "buy potion ok")
	inv.add_item("heal_potion", 1)
	assert_eq(inv.count_item("heal_potion"), 1, "bought 1 potion")
	assert_eq(inv.gold, 50, "50 gold left")
	# 卖 potion (半价)
	var sell_price = potion_price / 2
	inv.remove_item("heal_potion", 1)
	inv.add_gold(sell_price)
	assert_eq(inv.gold, 75, "sold potion +25 = 75")
	assert_eq(inv.count_item("heal_potion"), 0, "no potion left")
