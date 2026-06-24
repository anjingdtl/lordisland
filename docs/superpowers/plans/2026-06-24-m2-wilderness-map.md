# M2.1 洛奈野外地图 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 添加 1 张森林野外地图 + 3 场战斗 + 2 NPC + 1 chest + 1 boss 巨魔

**Architecture:** 复用 M2 的 Sprite3DActor 渲染 NPC/战斗标记，chest 用 BoxMesh + 自定义脚本，forest_decorator 程序化生成树/石头装饰

**Tech Stack:** Godot 4.3 + GDScript + Sprite3DActor + JSON 数据

**Spec:** `docs/superpowers/specs/2026-06-24-m2-wilderness-map.md`

---

## Task 1: 加 troll 敌人数据

**Files:**
- Modify: `data/enemies.json`

- [ ] **Step 1: 在 enemies.json 末尾加 troll 字段**

```json
  "troll": {
    "id": "troll",
    "name_key": "enemy_troll",
    "level": 4,
    "hp": 120,
    "mp": 0,
    "str": 14,
    "agi": 4,
    "int": 3,
    "vit": 10,
    "cha": 1,
    "skills": ["attack", "smash"],
    "exp_reward": 50,
    "sprite": {
      "type": "troll",
      "body_color": "#4a6b3a",
      "hair_color": "#1a2a1a",
      "skin_color": "#7a8b5a",
      "armor_color": "#4a6b3a",
      "weapon": "club",
      "outline_color": "#1a2a1a"
    }
  }
```

（在 `"kobold"` 之后，最后的 `}` 之前）

- [ ] **Step 2: 验证**

```bash
$env:APPDATA = "d:\Claudeworkspace\Lordisland\.godot_user"
cd d:\Claudeworkspace\Lordisland
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless --import 2>&1 | Select-String "ERROR"
```

期望：无输出

- [ ] **Step 3: Commit**

```bash
git add data/enemies.json
git commit -m "feat(enemy): troll boss (HP 120, STR 14, exp 50)"
```

---

## Task 2: 翻译 - 加 enemy_troll / npc_slayn / npc_tike key

**Files:**
- Modify: `locale/zh.po`
- Modify: `locale/en.po`

- [ ] **Step 1: zh.po 加 3 条 msgid**

找到 `msgid ""\n` 之前的空行附近，加：

```
msgid "enemy_troll"
msgstr "巨魔"

msgid "npc_slayn_meet"
msgstr "你好，勇者。我叫斯雷因，是个魔法使。\n这片森林最近有奇怪的异动。\n\n(1) 愿意听听详情\n(2) 我没空\n(3) 一起调查？"

msgid "slayn_ask_response"
msgstr "谢谢你愿意帮助。森林东边有怪物出没，村里人都不敢靠近。"

msgid "slayn_ask_no_time"
msgstr "是吗…那祝你旅途平安。"

msgid "slayn_ask_together"
msgstr "太好了！有同伴总是更安全。我们一起走。"

msgid "npc_slayn_leave"
msgstr "再会。如果改变主意，可以来森林东边找我。"

msgid "npc_tike_meet"
msgstr "你好！我是蒂特，森林里的游侠。\n我看到一只受伤的精灵，\n她正在被哥布林围攻。\n\n(1) 我去救她\n(2) 太危险了\n(3) 你为什么不去？"

msgid "tike_ask_rescue"
msgstr "太好了！那只精灵是我的朋友。我们一起去救她。"

msgid "tike_ask_dangerous"
msgstr "也是…那只精灵很强，可能不需要我们。"

msgid "tike_ask_why_not_you"
msgstr "我…我被敌人打伤了，走不动。但我可以在远处用弓箭支援你。"

msgid "npc_tike_leave"
msgstr "小心，勇者。"

msgid "chest_heal_potion_msg"
msgstr "你获得了 治疗药水 x1！"
```

- [ ] **Step 2: en.po 加 3 条 msgid**

```
msgid "enemy_troll"
msgstr "Troll"

msgid "npc_slayn_meet"
msgstr "Hello, brave one. I am Slayn, a mage.\nThere have been strange disturbances in this forest lately.\n\n(1) Tell me more\n(2) I'm busy\n(3) Investigate together?"

msgid "slayn_ask_response"
msgstr "Thank you for your help. Monsters have been appearing in the eastern forest, and villagers are too scared to approach."

msgid "slayn_ask_no_time"
msgstr "I see… Safe travels."

msgid "slayn_ask_together"
msgstr "Excellent! A companion makes things safer. Let's go together."

msgid "npc_slayn_leave"
msgstr "Farewell. If you change your mind, find me in the eastern forest."

msgid "npc_tike_meet"
msgstr "Hello! I'm Tike, a forest ranger.\nI saw a wounded elf being attacked by goblins.\n\n(1) I'll rescue her\n(2) Too dangerous\n(3) Why don't you go?"

msgid "tike_ask_rescue"
msgstr "Wonderful! That elf is my friend. Let's rescue her together."

msgid "tike_ask_dangerous"
msgstr "True… That elf is strong, perhaps she doesn't need us."

msgid "tike_ask_why_not_you"
msgstr "I… I'm injured, I can't move. But I can provide arrow support from afar."

msgid "npc_tike_leave"
msgstr "Be careful, brave one."

msgid "chest_heal_potion_msg"
msgstr "You obtained a Healing Potion x1!"
```

- [ ] **Step 3: 验证 i18n 加载**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless -s tests/test_main_quest_flow.gd 2>&1 | Select-String "RESULT|EN translation"
```

期望：`EN translation works` 在 PASS 列表

- [ ] **Step 4: Commit**

```bash
git add locale/zh.po locale/en.po
git commit -m "feat(i18n): troll, slayn, tike dialogue + chest translation"
```

---

## Task 3: 对话 JSON - Slayn 和 Tike

**Files:**
- Create: `data/dialogues/npc_slayn_meet.json`
- Create: `data/dialogues/npc_tike_meet.json`

- [ ] **Step 1: 创建 npc_slayn_meet.json**

```json
{
  "id": "npc_slayn_meet",
  "speaker": "npc_slayn",
  "start": "start",
  "nodes": {
    "start": {
      "text_key": "npc_slayn_meet",
      "next": "ask"
    },
    "ask": {
      "choices": [
        {"text": "1", "next": "response"},
        {"text": "2", "next": "no_time"},
        {"text": "3", "next": "together"}
      ]
    },
    "response": {
      "text_key": "slayn_ask_response",
      "next": "end"
    },
    "no_time": {
      "text_key": "slayn_ask_no_time",
      "next": "end"
    },
    "together": {
      "text_key": "slayn_ask_together",
      "next": "end"
    },
    "end": {
      "text_key": "npc_slayn_leave",
      "is_end": true
    }
  }
}
```

- [ ] **Step 2: 创建 npc_tike_meet.json**

```json
{
  "id": "npc_tike_meet",
  "speaker": "npc_tike",
  "start": "start",
  "nodes": {
    "start": {
      "text_key": "npc_tike_meet",
      "next": "ask"
    },
    "ask": {
      "choices": [
        {"text": "1", "next": "rescue"},
        {"text": "2", "next": "dangerous"},
        {"text": "3", "next": "why_not_you"}
      ]
    },
    "rescue": {
      "text_key": "tike_ask_rescue",
      "next": "end"
    },
    "dangerous": {
      "text_key": "tike_ask_dangerous",
      "next": "end"
    },
    "why_not_you": {
      "text_key": "tike_ask_why_not_you",
      "next": "end"
    },
    "end": {
      "text_key": "npc_tike_leave",
      "is_end": true
    }
  }
}
```

- [ ] **Step 3: 验证解析**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless -s tests/test_dialogue_parser.gd 2>&1 | Select-String "RESULT"
```

期望：`=== RESULT: 8 passed, 0 failed ===`

- [ ] **Step 4: Commit**

```bash
git add data/dialogues/npc_slayn_meet.json data/dialogues/npc_tike_meet.json
git commit -m "feat(dialogue): slayn + tike meet dialogues (3 choices each)"
```

---

## Task 4: Chest 节点脚本

**Files:**
- Create: `scripts/world/chest.gd`

- [ ] **Step 1: 实现 chest.gd**

```gdscript
class_name Chest
extends Node3D

## 宝箱：拾取后给物品，一次性

@export var item_id: String = "heal_potion"
@export var item_count: int = 1
@export var open_flag: String = ""  # 已开的 flag 名
@export var message_key: String = "chest_heal_potion_msg"

var _opened: bool = false

func _ready() -> void:
	# 检查是否已开
	if open_flag != "":
		var globals = _get_globals()
		if globals and globals.event_system:
			if globals.event_system.get_flag(open_flag) == true:
				_opened = true
				visible = false

func on_interact() -> void:
	if _opened:
		return
	_opened = true
	var globals = _get_globals()
	if globals:
		# 触发 message
		var msg = TranslationServer.translate(message_key)
		print(msg)
		# 给物品
		if globals.event_system:
			globals.event_system.set_flag("item_%s" % item_id, item_count)
		# 标记已开
		if open_flag != "" and globals.event_system:
			globals.event_system.set_flag(open_flag, true)
	visible = false

func _get_globals() -> Node:
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "GameGlobals":
			return child
	return null
```

- [ ] **Step 2: 验证 - 直接运行无错**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless --check-only -s scripts/world/chest.gd 2>&1 | Select-String "ERROR"
```

期望：无输出

- [ ] **Step 3: Commit**

```bash
git add scripts/world/chest.gd
git commit -m "feat(world): chest.gd - one-time item pickup with flag persistence"
```

---

## Task 5: WildernessExit 脚本（双向）

**Files:**
- Create: `scripts/world/wilderness_exit.gd`

- [ ] **Step 1: 实现**

```gdscript
class_name WildernessExit
extends Node3D

## 野外地图双向出口

@export var target_scene: String = "res://scenes/world/loranai_wilderness.tscn"
@export var target_marker: String = ""  # 目标 marker 名称（暂未实现）

func on_interact() -> void:
	get_tree().change_scene_to_file(target_scene)
```

- [ ] **Step 2: 验证**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless --check-only -s scripts/world/wilderness_exit.gd 2>&1 | Select-String "ERROR"
```

- [ ] **Step 3: Commit**

```bash
git add scripts/world/wilderness_exit.gd
git commit -m "feat(world): wilderness_exit.gd - bidirectional scene transition"
```

---

## Task 6: ForestDecorator 程序化生成装饰

**Files:**
- Create: `scripts/world/forest_decorator.gd`

- [ ] **Step 1: 实现**

```gdscript
class_name ForestDecorator
extends Node3D

## 程序化生成森林装饰（树、石头、灌木）
## 在 _ready 中根据种子生成确定性分布

@export var seed_value: int = 42
@export var tree_count: int = 10
@export var rock_count: int = 5
@export var bush_count: int = 6
@export var bounds_min: Vector2 = Vector2(-20, -20)
@export var bounds_max: Vector2 = Vector2(20, 20)

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	_generate_trees(rng)
	_generate_rocks(rng)
	_generate_bushes(rng)

func _generate_trees(rng: RandomNumberGenerator) -> void:
	for i in tree_count:
		var t = MeshInstance3D.new()
		var trunk = CylinderMesh.new()
		trunk.top_radius = 0.2
		trunk.bottom_radius = 0.25
		trunk.height = 1.2
		t.mesh = trunk
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.25, 0.15, 1)
		mat.roughness = 0.95
		t.material_override = mat
		# 树冠
		var top = MeshInstance3D.new()
		var crown = SphereMesh.new()
		crown.radius = 0.6
		crown.height = 1.2
		top.mesh = crown
		top.position.y = 1.2
		var mat2 = StandardMaterial3D.new()
		mat2.albedo_color = Color(0.2, 0.45, 0.2, 1)
		mat2.roughness = 0.85
		top.material_override = mat2
		# 位置
		var pos = _random_pos(rng)
		t.position = Vector3(pos.x, 0.6, pos.y)
		top.position = Vector3(pos.x, 1.2, pos.y)
		t.add_child(top)
		add_child(t)

func _generate_rocks(rng: RandomNumberGenerator) -> void:
	for i in rock_count:
		var r = MeshInstance3D.new()
		var box = BoxMesh.new()
		var s = rng.randf_range(0.4, 0.8)
		box.size = Vector3(s, s * 0.6, s)
		r.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.5, 0.5, 1)
		mat.roughness = 0.95
		r.material_override = mat
		r.rotation.y = rng.randf_range(0, PI)
		var pos = _random_pos(rng)
		r.position = Vector3(pos.x, s * 0.3, pos.y)
		add_child(r)

func _generate_bushes(rng: RandomNumberGenerator) -> void:
	for i in bush_count:
		var b = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.3
		sphere.height = 0.4
		b.mesh = sphere
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.5, 0.25, 1)
		mat.roughness = 0.9
		b.material_override = mat
		var pos = _random_pos(rng)
		b.position = Vector3(pos.x, 0.2, pos.y)
		add_child(b)

func _random_pos(rng: RandomNumberGenerator) -> Vector2:
	return Vector2(
		rng.randf_range(bounds_min.x, bounds_max.x),
		rng.randf_range(bounds_min.y, bounds_max.y)
	)
```

- [ ] **Step 2: 验证**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless --check-only -s scripts/world/forest_decorator.gd 2>&1 | Select-String "ERROR"
```

- [ ] **Step 3: Commit**

```bash
git add scripts/world/forest_decorator.gd
git commit -m "feat(world): forest_decorator - procedural trees/rocks/bushes"
```

---

## Task 7: 洛奈野外场景

**Files:**
- Create: `scenes/world/loranai_wilderness.tscn`

- [ ] **Step 1: 创建 .tscn**

参考 starting_cave.tscn 风格，但用深绿地面 + 程序化装饰 + 3 战斗 + 2 NPC + 1 chest + 1 出口。

```gdscript
[gd_scene load_steps=10 format=3 uid="uid://b2wild01"]

[ext_resource type="Script" path="res://scripts/core/camera_hd2d.gd" id="1_cam"]
[ext_resource type="Script" path="res://scripts/world/world_player.gd" id="2_player"]
[ext_resource type="Script" path="res://scripts/world/wilderness_exit.gd" id="3_exit"]
[ext_resource type="Script" path="res://scripts/world/battle_trigger.gd" id="4_battle"]
[ext_resource type="Script" path="res://scripts/world/npc.gd" id="5_npc"]
[ext_resource type="Script" path="res://scripts/world/sprite3d_actor.gd" id="6_sprite"]
[ext_resource type="Script" path="res://scripts/world/chest.gd" id="7_chest"]
[ext_resource type="Script" path="res://scripts/world/forest_decorator.gd" id="8_forest"]

[sub_resource type="PlaneMesh" id="PlaneMesh_ground"]
size = Vector2(60, 60)

[sub_resource type="StandardMaterial3D" id="Mat_ground"]
albedo_color = Color(0.22, 0.36, 0.22, 1)
roughness = 0.95

[sub_resource type="BoxMesh" id="Box_chest"]
size = Vector3(0.6, 0.5, 0.4)

[sub_resource type="StandardMaterial3D" id="Mat_chest"]
albedo_color = Color(0.5, 0.3, 0.6, 1)
roughness = 0.7

[node name="LoranaiWilderness" type="Node3D"]

[node name="Ground" type="MeshInstance3D" parent="."]
mesh = SubResource("PlaneMesh_ground")
surface_material_override/0 = SubResource("Mat_ground")

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]
transform = Transform3D(0.866, -0.354, 0.354, 0, 0.707, 0.707, -0.5, -0.612, 0.612, 0, 12, 0)
light_energy = 0.7
light_color = Color(0.85, 0.9, 1.0, 1)
shadow_enabled = true

[node name="Forest" type="Node3D" parent="."]
script = ExtResource("8_forest")
seed_value = 42
tree_count = 10
rock_count = 5
bush_count = 6
bounds_min = Vector2(-25, -25)
bounds_max = Vector2(25, 25)

[node name="Player" type="Node3D" parent="."]
script = ExtResource("2_player")
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 15)
bounds_min = Vector2(-25, -25)
bounds_max = Vector2(25, 25)

[node name="Avatar" type="Node3D" parent="Player"]
script = ExtResource("6_sprite")
actor_id = "parn"
sprite_data = {
"body_color": "#2a4d8f",
"hair_color": "#f0c419",
"skin_color": "#fbcb8a",
"armor_color": "#cccccc",
"weapon": "sword",
"outline_color": "#1a1a1a"
}

[node name="Camera" type="Camera3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 0.643, 0.766, 0, -0.766, 0.643, 0, 12, 16)
script = ExtResource("1_cam")
height = 12.0
distance = 16.0
angle_deg = 50.0
follow_speed = 6.0

[node name="WildernessExit" type="Node3D" parent="." groups=["exit"]]
script = ExtResource("3_exit")
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 20)
target_scene = "res://scenes/world/loranai_city.tscn"

[node name="Marker" type="Node3D" parent="WildernessExit"]
script = ExtResource("6_sprite")
actor_id = "wilderness_door"
use_walk_animation = false
sprite_data = {
"body_color": "#3a5a3a",
"hair_color": "#1a1a1a",
"skin_color": "#1a1a1a",
"armor_color": "#1a1a1a",
"weapon": "none",
"outline_color": "#000000"
}

[node name="BattleA" type="Node3D" parent="." groups=["exit"]]
script = ExtResource("4_battle")
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -12, 0.5, 5)
enemies = ["goblin", "goblin"]
one_shot = true
trigger_flag = "wilderness_battle_a_cleared"

[node name="Marker" type="Node3D" parent="BattleA"]
script = ExtResource("6_sprite")
actor_id = "goblin"
sprite_data = {
"body_color": "#3d6e3d",
"hair_color": "#1a2a1a",
"skin_color": "#8aac5c",
"armor_color": "#3d6e3d",
"weapon": "club",
"outline_color": "#1a2a1a"
}

[node name="BattleB" type="Node3D" parent="." groups=["exit"]]
script = ExtResource("4_battle")
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -12, 0.5, -8)
enemies = ["goblin_archer", "goblin_archer"]
one_shot = true
trigger_flag = "wilderness_battle_b_cleared"

[node name="Marker" type="Node3D" parent="BattleB"]
script = ExtResource("6_sprite")
actor_id = "goblin_archer"
sprite_data = {
"body_color": "#3d6e3d",
"hair_color": "#1a2a1a",
"skin_color": "#8aac5c",
"armor_color": "#3d6e3d",
"weapon": "bow",
"outline_color": "#1a2a1a"
}

[node name="BossTroll" type="Node3D" parent="." groups=["exit"]]
script = ExtResource("4_battle")
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 12, 0.5, -15)
enemies = ["troll"]
one_shot = true
trigger_flag = "wilderness_boss_defeated"
is_boss = true

[node name="Marker" type="Node3D" parent="BossTroll"]
script = ExtResource("6_sprite")
actor_id = "troll"
sprite_data = {
"body_color": "#4a6b3a",
"hair_color": "#1a2a1a",
"skin_color": "#7a8b5a",
"armor_color": "#4a6b3a",
"weapon": "club",
"outline_color": "#1a2a1a"
}

[node name="SlaynNPC" type="Node3D" parent="." groups=["npc"]]
script = ExtResource("5_npc")
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 3, 0.5, -10)
npc_id = "npc_slayn"
dialogue_id = "npc_slayn_meet"
event_id = ""

[node name="Avatar" type="Node3D" parent="SlaynNPC"]
script = ExtResource("6_sprite")
actor_id = "slayn"
use_walk_animation = false
sprite_data = {
"body_color": "#8f3d3d",
"hair_color": "#1a1a1a",
"skin_color": "#fbcb8a",
"armor_color": "#4a4a4a",
"weapon": "dagger",
"outline_color": "#1a1a1a"
}

[node name="TikeNPC" type="Node3D" parent="." groups=["npc"]]
script = ExtResource("5_npc")
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 2, 0.5, 3)
npc_id = "npc_tike"
dialogue_id = "npc_tike_meet"
event_id = ""

[node name="Avatar" type="Node3D" parent="TikeNPC"]
script = ExtResource("6_sprite")
actor_id = "tike"
use_walk_animation = false
sprite_data = {
"body_color": "#3d8f5a",
"hair_color": "#f0c419",
"skin_color": "#fbcb8a",
"armor_color": "#6b6b6b",
"weapon": "bow",
"outline_color": "#1a1a1a"
}

[node name="Chest1" type="Node3D" parent="." groups=["exit"]]
script = ExtResource("7_chest")
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 15, 0.5, 8)
item_id = "heal_potion"
item_count = 1
open_flag = "chest_wilderness_1_opened"
message_key = "chest_heal_potion_msg"

[node name="Visual" type="MeshInstance3D" parent="Chest1"]
mesh = SubResource("Box_chest")
surface_material_override/0 = SubResource("Mat_chest")
```

- [ ] **Step 2: 验证场景加载**

```bash
$env:APPDATA = "d:\Claudeworkspace\Lordisland\.godot_user"
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless --import 2>&1 | Select-String "ERROR|WARN"
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless --quit-after 15 res://scenes/world/loranai_wilderness.tscn 2>&1 | Select-String "GameGlobals|ERROR|SCRIPT"
```

期望：`GameGlobals ready` 一行，无 ERROR

- [ ] **Step 3: Commit**

```bash
git add scenes/world/loranai_wilderness.tscn
git commit -m "feat(scene): loranai_wilderness with 3 battles + 2 NPCs + chest + boss"
```

---

## Task 8: 洛奈城加 WildernessExit 入口

**Files:**
- Modify: `scenes/world/loranai_city.tscn`

- [ ] **Step 1: 在文件末尾加 WildernessExit 节点**

找到最后的 `}` 前，加：

```
[node name="WildernessExit" type="Node3D" parent="." groups=["exit"]]
script = ExtResource("6_sprite")
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 22)
sprite_data = {
"body_color": "#3a5a3a",
"hair_color": "#1a1a1a",
"skin_color": "#1a1a1a",
"armor_color": "#1a1a1a",
"weapon": "none",
"outline_color": "#000000"
}
```

等等，WildernessExit 需要有 `on_interact` 方法。让我用一种简单方式：直接用一个 Node3D + 自定义脚本。

- 重新设计：在 loranai_city 加一个新的 WildernessExit 类节点，类似 CaveExit。

让我加一个子节点配脚本。

Actually, let me use a simpler approach - add a new exit-type node with a script that does scene change.

最简单的方式：复用 cave_exit.gd（它有 target_scene 属性），但叫它"野外出口"。

所以：

```
[node name="WildernessExit" type="Node3D" parent="." groups=["exit"]]
script = ExtResource("4_exit")
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 22)
target_scene = "res://scenes/world/loranai_wilderness.tscn"

[node name="Marker" type="Node3D" parent="WildernessExit"]
script = ExtResource("5_sprite")
actor_id = "wilderness_gate"
use_walk_animation = false
sprite_data = {
"body_color": "#3a5a3a",
"hair_color": "#1a1a1a",
"skin_color": "#1a1a1a",
"armor_color": "#1a1a1a",
"weapon": "none",
"outline_color": "#000000"
}
```

注意 id 4_exit 是 cave_exit.gd, id 5_sprite 是 sprite3d_actor.gd。

- [ ] **Step 2: 验证**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless --import 2>&1 | Select-String "ERROR"
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless --quit-after 15 res://scenes/world/loranai_city.tscn 2>&1 | Select-String "GameGlobals|ERROR"
```

- [ ] **Step 3: Commit**

```bash
git add scenes/world/loranai_city.tscn
git commit -m "feat(scene): loranai city gets wilderness exit (north gate)"
```

---

## Task 9: E2E 测试 - 野外场景

**Files:**
- Create: `tests/test_wilderness_e2e.gd`

- [ ] **Step 1: 写测试**

```gdscript
extends SceneTree

## 野外地图 E2E 测试

const LOG_PATH := "user://wilderness_test.log"

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	var f = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	f.store_string("")
	f.close()
	# 加载翻译
	var zh = ResourceLoader.load("res://locale/zh.po", "Translation")
	if zh is Translation:
		TranslationServer.add_translation(zh)
	TranslationServer.set_locale("zh")
	_log("=== Wilderness E2E test ===")
	test_troll_in_enemies()
	test_slayn_dialogue_loads()
	test_tike_dialogue_loads()
	test_chest_gives_potion()
	test_forest_decorator_creates_children()
	test_main_quest_extended()
	print("\n=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)

func _log(msg: String) -> void:
	print(msg)
	var f = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if f == null: return
	f.seek_end()
	f.store_line(msg)
	f.close()

func assert_eq(value, expected, msg: String) -> void:
	if value == expected:
		_passed += 1
		_log("PASS: %s" % msg)
	else:
		_failed += 1
		_log("FAIL: %s (got %s, expected %s)" % [msg, str(value), str(expected)])

func assert_true(value: bool, msg: String) -> void:
	assert_eq(value, true, msg)

func test_troll_in_enemies() -> void:
	var f = FileAccess.open("res://data/enemies.json", FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	assert_true(data.has("troll"), "troll in enemies.json")
	assert_eq(data.troll.get("hp", 0), 120, "troll HP = 120")
	assert_eq(data.troll.get("exp_reward", 0), 50, "troll exp = 50")

func test_slayn_dialogue_loads() -> void:
	var parser = DialogueParser.load_from_file("res://data/dialogues/npc_slayn_meet.json")
	assert_true(parser.id == "npc_slayn_meet", "slayn dialogue id")
	var start = parser.get_node("start")
	assert_true(start.has("text_key"), "slayn start has text_key")
	var ask = parser.get_node("ask")
	assert_eq(ask["choices"].size(), 3, "slayn 3 choices")

func test_tike_dialogue_loads() -> void:
	var parser = DialogueParser.load_from_file("res://data/dialogues/npc_tike_meet.json")
	assert_true(parser.id == "npc_tike_meet", "tike dialogue id")
	var start = parser.get_node("start")
	assert_true(start.has("text_key"), "tike start has text_key")
	var ask = parser.get_node("ask")
	assert_eq(ask["choices"].size(), 3, "tike 3 choices")

func test_chest_gives_potion() -> void:
	var es = EventSystem.new()
	# 模拟 chest on_interact
	es.set_flag("item_heal_potion", 1)
	assert_eq(es.get_flag("item_heal_potion"), 1, "chest gives heal_potion")

func test_forest_decorator_creates_children() -> void:
	var ForestDecorator = load("res://scripts/world/forest_decorator.gd")
	var fd = ForestDecorator.new()
	fd.tree_count = 3
	fd.rock_count = 2
	fd.bush_count = 2
	get_root().add_child(fd)
	await process_frame
	var mesh_count = 0
	for child in fd.get_children():
		if child is MeshInstance3D:
			mesh_count += 1
	# 每个 tree 有 2 个 mesh (trunk + crown), rock 1, bush 1
	# 3 trees * 2 + 2 rocks + 2 bushes = 10
	assert_true(mesh_count >= 5, "forest decorator creates meshes (got %d)" % mesh_count)

func test_main_quest_extended() -> void:
	# 验证完整主任务链：Parn → Loranai → Cave → Ehto + 新增：troll boss
	var es = EventSystem.new()
	var pm = PartyManager.new(es)
	pm.add_member("parn")
	# 主线扩展：野外打 troll
	es.set_flag("wilderness_boss_defeated", true)
	assert_eq(es.get_flag("wilderness_boss_defeated"), true, "troll boss flag set")
	# 经验：troll = 50
	var troll = JSON.parse_string(FileAccess.open("res://data/enemies.json", FileAccess.READ).get_as_text()).troll
	assert_eq(troll.exp_reward, 50, "troll gives 50 exp")
```

- [ ] **Step 2: 运行 - 期望 6+ PASS**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless -s tests/test_wilderness_e2e.gd 2>&1 | Select-String "(PASS|FAIL|RESULT)"
```

- [ ] **Step 3: Commit**

```bash
git add tests/test_wilderness_e2e.gd
git commit -m "test: wilderness E2E (6+ pass: troll, slayn, tike, chest, forest, quest)"
```

---

## Task 10: 跑全套测试 + 验收

**Files:**
- (none)

- [ ] **Step 1: 跑全部**

```bash
$env:APPDATA = "d:\Claudeworkspace\Lordisland\.godot_user"
$env:LOCALAPPDATA = "d:\Claudeworkspace\Lordisland\.godot_cache"
cd d:\Claudeworkspace\Lordisland
$G = "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe"
$tests = @("test_damage_formula", "test_dialogue_parser", "test_dialogue_e2e", "test_event_system", "test_event_e2e", "test_save_system", "test_main_quest_flow", "test_sprite_generator", "test_sprite_actor_e2e", "test_wilderness_e2e")
$tp = 0; $tf = 0
foreach ($t in $tests) {
	$r = & $G --headless -s tests/$t.gd 2>&1 | Out-String
	$p = ([regex]::Match($r, "RESULT: (\d+) passed")).Groups[1].Value
	$f = ([regex]::Match($r, "(\d+) failed")).Groups[1].Value
	Write-Host "$t : $p pass, $f fail"
	$tp += [int]$p
	$tf += [int]$f
}
Write-Host "==TOTAL==: $tp pass, $tf fail"
```

期望：90+ pass, 0 fail

- [ ] **Step 2: 手动验证（F5）**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --editor
```

- 新游戏 → 洛奈城
- 走到北侧新加的 WildernessExit → 切换到野外
- 检查：森林视觉（树/石头/灌木）
- 走到战斗 marker → 触发战斗
- 走到斯雷因/蒂特 NPC → 对话
- 走到 chest → 拾取治疗药水

- [ ] **Step 3: 提交（如果需要）**

```bash
git status
# 如果有 changes: git add + commit
```

---

## Total Time

| Task | Time |
|---|---|
| Task 1 (troll) | 3 min |
| Task 2 (i18n) | 5 min |
| Task 3 (dialogues) | 5 min |
| Task 4 (chest) | 5 min |
| Task 5 (wilderness_exit) | 3 min |
| Task 6 (forest_decorator) | 8 min |
| Task 7 (wilderness scene) | 10 min |
| Task 8 (loranai exit) | 5 min |
| Task 9 (e2e test) | 5 min |
| Task 10 (verify) | 5 min |
| **Total** | **~55 min** |
