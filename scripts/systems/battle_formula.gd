class_name BattleFormula
extends RefCounted

## 战斗伤害公式（静态工具类）
## 设计文档 § 4.6：
##   物理伤害 = max(1, (力量 - 防御 * 0.5) * 随机(0.9, 1.1) * 暴击系数)
##   魔法伤害 = max(1, (智力 * 技能系数 - 抗性) * 随机(0.9, 1.1))

static func physical_damage(attack: int, defense: int, crit_mult: float, variance: float) -> int:
	var base := float(attack) - float(defense) * 0.5
	var result := base * variance * crit_mult
	return int(max(1.0, result))

static func magical_damage(intelligence: int, skill_coeff: float, resistance: int, variance: float) -> int:
	var base := float(intelligence) * skill_coeff - float(resistance)
	var result := base * variance
	return int(max(1.0, result))

## 暴击判定（按命中率，1.0 = 100%）
static func roll_critical(crit_rate: float, rng: RandomNumberGenerator = null) -> float:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	if rng.randf() < crit_rate:
		return 1.5  # 暴击系数
	return 1.0

## 随机方差（0.9 - 1.1）
static func roll_variance(rng: RandomNumberGenerator = null) -> float:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	return rng.randf_range(0.9, 1.1)

## 物理伤害快捷调用（带随机）
static func physical_attack(attack: int, defense: int, crit_rate: float = 0.05) -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return physical_damage(attack, defense, roll_critical(crit_rate, rng), roll_variance(rng))

## 魔法伤害快捷调用
static func magical_attack(intelligence: int, skill_coeff: float, resistance: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return magical_damage(intelligence, skill_coeff, resistance, roll_variance(rng))
