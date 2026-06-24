extends SceneTree

## 极简测试 runner：作为主场景跑，每个 assert 失败立即打印并退出
## 用法：godot --headless --quit-after 1 -s test_damage_formula.gd
## 或者放到 main scene 然后 --quit-after 1

const BattleFormula = preload("res://scripts/systems/battle_formula.gd")

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	run_all()
	print("\n=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)

func run_all() -> void:
	test_physical_damage_basic()
	test_magical_damage_basic()
	test_physical_damage_minimum_1()
	test_critical_multiplier()
	test_magical_resistance_caps_damage()

func assert_between(value: float, low: float, high: float, msg: String) -> void:
	if value >= low and value <= high:
		_passed += 1
		print("PASS: %s (got %s, range [%s, %s])" % [msg, value, low, high])
	else:
		_failed += 1
		print("FAIL: %s (got %s, expected [%s, %s])" % [msg, value, low, high])

func assert_eq(value, expected, msg: String) -> void:
	if value == expected:
		_passed += 1
		print("PASS: %s (got %s)" % [msg, value])
	else:
		_failed += 1
		print("FAIL: %s (got %s, expected %s)" % [msg, value, expected])

func assert_gt(a, b, msg: String) -> void:
	if a > b:
		_passed += 1
		print("PASS: %s (got %s > %s)" % [msg, a, b])
	else:
		_failed += 1
		print("FAIL: %s (got %s, expected > %s)" % [msg, a, b])

func test_physical_damage_basic() -> void:
	# 力量 20 - 防御 5*0.5 = 17.5，乘随机 0.9-1.1，暴击 1.0
	# 范围 15.75 - 19.25, int 截断 15-19
	var dmg = BattleFormula.physical_damage(20, 5, 1.0, 1.0)
	assert_between(float(dmg), 15.0, 19.0, "test_physical_damage_basic")

func test_magical_damage_basic() -> void:
	# 智力 30 * 系数 2.0 - 抗性 10 = 50，乘随机 0.9-1.1
	# 范围 45 - 55
	var dmg = BattleFormula.magical_damage(30, 2.0, 10, 1.0)
	assert_between(float(dmg), 45.0, 55.0, "test_magical_damage_basic")

func test_physical_damage_minimum_1() -> void:
	# 防御很高
	var dmg = BattleFormula.physical_damage(0, 100, 1.0, 1.0)
	assert_eq(dmg, 1, "test_physical_damage_minimum_1")

func test_critical_multiplier() -> void:
	# 暴击系数 1.5 vs 1.0
	var normal = BattleFormula.physical_damage(20, 5, 1.0, 1.0)
	var crit = BattleFormula.physical_damage(20, 5, 1.5, 1.0)
	assert_gt(crit, normal, "test_critical_multiplier")

func test_magical_resistance_caps_damage() -> void:
	# 抗性很高，伤害至少 1
	var dmg = BattleFormula.magical_damage(5, 1.0, 100, 1.0)
	assert_eq(dmg, 1, "test_magical_resistance_caps_damage")
