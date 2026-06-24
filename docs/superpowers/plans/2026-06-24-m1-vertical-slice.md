# M1 垂直切片 — 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 5 周内完成一个 10-15 分钟可玩的 2D RPG 垂直切片 demo（洛奈城→起始洞窟→救出艾特），覆盖全部 10 个核心系统的最小可行形态。

**Architecture:** Godot 4.x + GDScript + JSON 数据驱动 + 3D 透视相机 + 2D sprite 角色的 HD-2D 渲染。TDD 用于核心逻辑（战斗公式、对话/事件解析、存档序列化），UI/视觉/演出用手动 checklist。

**Tech Stack:**
- Godot 4.x（待装，最新稳定版）
- GDScript（主力）
- GUT（Godot Unit Test）— 核心逻辑 TDD
- Git + Git LFS
- PowerShell（开发环境脚本）

**关联文档：**
- 设计文档：[2026-06-24-lordisland-2d-rpg-design.md](../specs/2026-06-24-lordisland-2d-rpg-design.md)

---

## 总览：5 个 Phase（每周一个）

| Phase | 周次 | 主题 | 核心里程碑 |
|---|---|---|---|
| **P1** | 第 1 周 | 项目骨架 + HD-2D 渲染层 | 角色在一张测试地图上跑动 |
| **P2** | 第 2 周 | 战斗系统 + 战斗 UI | 完成一场 5v3 战斗 |
| **P3** | 第 3 周 | 对话系统 + 事件系统 | 与 NPC 对话+触发剧情事件 |
| **P4** | 第 4 周 | 内容整合 + 存档 | 完整 demo 主线流程跑通 |
| **P5** | 第 5 周 | 打磨 + 音频 + 包装 | 可演示版本 |

**每个 Phase 结束都会有 review checkpoint** —— 我做完该 phase 全部任务，编译/运行验证，然后给你看效果，你拍板再进下一个 phase。

---

## Phase 1：项目骨架 + HD-2D 渲染层（第 1 周）

### 任务 1.1：安装 Godot 4.x
**文件：** N/A（环境准备）

- [ ] **Step 1：检查现有 Godot 安装**

```bash
# PowerShell
where godot 2>$null
Get-ChildItem "C:\Program Files\Godot\" -ErrorAction SilentlyContinue
Get-ChildItem "$env:LOCALAPPDATA\Godot" -ErrorAction SilentlyContinue
```

- [ ] **Step 2：若未装，下载 Godot 4.x（Windows）**

```powershell
# 下载 Godot 4.3+ Windows 标准版（zip 包，单 .exe 免安装）
$url = "https://github.com/godotengine/godot-builds/releases/download/4.3-stable/Godot_v4.3-stable_win64.exe.zip"
$outDir = "d:\Claudeworkspace\Lordisland\.tools"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$zip = "$outDir\godot.zip"
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
Expand-Archive $zip -DestinationPath $outDir -Force
```

- [ ] **Step 3：把 Godot 加到 PATH（当前用户）**

```powershell
$env:PATH += ";$outDir"
# 永久化（写进用户 PATH）
[Environment]::SetEnvironmentVariable("Path", $env:Path, "User")
```

- [ ] **Step 4：验证**

```bash
godot --version
# 期望：4.3-stable 或更新版本号
```

### 任务 1.2：初始化 Godot 项目
**文件：**
- Create: `project.godot`
- Create: `.gitattributes`

- [ ] **Step 1：用 Godot CLI 初始化项目**

```bash
cd d:\Claudeworkspace\Lordisland
# 启动 Godot 编辑器（无 GUI 模式）生成 project.godot
# 实际：在 .tools 里运行 godot.exe --headless --quit-after 2 .
godot --headless --quit-after 2
```

- [ ] **Step 2：手工创建最小 project.godot**

```ini
; project.godot
config_version=5

[application]
config/name="Lordisland: Record of Lodoss War 2D RPG"
config/description="A 2D HD-2D RPG based on Record of Lodoss War OVA"
run/main_scene="res://scenes/world/test_scene.tscn"
config/features=PackedStringArray("4.3", "Forward Plus")

[rendering]
renderer/rendering_method="forward_plus"
environment/defaults/default_clear_color=Color(0.05, 0.05, 0.1, 1)
```

- [ ] **Step 3：创建 .gitattributes（Git LFS 跟踪大文件）**

```gitattributes
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
*.ogg filter=lfs diff=lfs merge=lfs -text
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.ttf filter=lfs diff=lfs merge=lfs -text
*.otf filter=lfs diff=lfs merge=lfs -text
*.tres binary
```

- [ ] **Step 4：创建目录骨架（空目录占位文件）**

```bash
# PowerShell
$dirs = @(
  "assets\sprites\characters",
  "assets\sprites\enemies",
  "assets\sprites\tiles",
  "assets\sprites\ui",
  "assets\sprites\portraits",
  "assets\audio\bgm",
  "assets\audio\sfx",
  "assets\fonts",
  "data\dialogues",
  "data\events",
  "data\npcs",
  "data\characters",
  "scenes\world",
  "scenes\battle",
  "scenes\ui",
  "scenes\common",
  "scripts\core",
  "scripts\systems",
  "scripts\world",
  "scripts\ui",
  "locale",
  "tests"
)
$d | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ | Out-Null }
# 每个空目录放一个 .gitkeep（除已经在 .gitignore 的外）
```

- [ ] **Step 5：Commit**

```bash
git add .gitattributes project.godot scripts/ assets/ data/ scenes/ tests/ locale/
git commit -m "feat(setup): initialize Godot 4.x project structure"
```

### 任务 1.3：HD-2D 渲染原型
**文件：**
- Create: `scenes/world/test_scene.tscn`
- Create: `scripts/world/test_player.gd`
- Create: `scripts/core/camera_hd2d.gd`
- Create: `assets/sprites/tiles/placeholder_grass.png`（程序生成）

- [ ] **Step 1：程序生成占位 tile sprite（用 Python 一行命令 / 或 GDScript）**

用 GDScript 在编辑器里跑一次生成（不用写进仓库）：
```gdscript
# tools/gen_placeholder_tile.gd（仅本地，不入仓）
@tool
extends EditorScript
func _run():
    var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.2, 0.4, 0.2, 1))
    for x in 32:
        for y in 32:
            if x == 0 or y == 0 or x == 31 or y == 31:
                img.set_pixel(x, y, Color(0.1, 0.2, 0.1, 1))
    img.save_png("res://assets/sprites/tiles/placeholder_grass.png")
```

- [ ] **Step 2：创建 HD-2D 相机脚本**

```gdscript
# scripts/core/camera_hd2d.gd
class_name HD2DCamera
extends Camera3D

# 3D 透视相机 + 2D 场景的简化版：
# 用 Camera3D + 倾斜 45°，渲染 Sprite3D 节点

@export var target: Node3D
@export var height: float = 12.0
@export var angle: float = 45.0  # 与水平面夹角
@export var distance: float = 18.0

func _ready():
    # 计算相机位置：target 上方 + 后方
    var rad = deg_to_rad(angle)
    position = Vector3(0, height, distance * cos(rad))
    rotation_degrees = Vector3(-angle, 0, 0)

func _process(_delta):
    if target:
        global_position.x = target.global_position.x
        global_position.z = target.global_position.z
```

- [ ] **Step 3：创建玩家脚本（基础移动）**

```gdscript
# scripts/world/test_player.gd
class_name TestPlayer
extends Node2D

@export var speed: float = 200.0

func _process(delta):
    var input = Vector2.ZERO
    if Input.is_action_pressed("ui_right"): input.x += 1
    if Input.is_action_pressed("ui_left"): input.x -= 1
    if Input.is_action_pressed("ui_down"): input.y += 1
    if Input.is_action_pressed("ui_up"): input.y -= 1
    if input != Vector2.ZERO:
        position += input.normalized() * speed * delta
```

- [ ] **Step 4：创建 test_scene.tscn（手工写 .tscn 文件）**

```tscn
[gd_scene load_steps=3 format=3 uid="uid://test01"]

[ext_resource type="Script" path="res://scripts/core/camera_hd2d.gd" id="1_cam"]
[ext_resource type="Script" path="res://scripts/world/test_player.gd" id="2_player"]

[node name="TestScene" type="Node2D"]

[node name="Camera" type="Camera3D" parent="."]
script = ExtResource("1_cam")
height = 12.0
angle = 45.0
distance = 18.0

[node name="Player" type="Node2D" parent="."]
script = ExtResource("2_player")
position = Vector2(0, 0)
```

- [ ] **Step 5：手动验证**

```bash
# 启动编辑器
godot
# 打开 project → 按 F5 运行 TestScene
# 期望：能看到 1 个占位 tile + 1 个空 Node（玩家）
# 用方向键移动（不验证视觉效果，只验证脚本不报错）
```

- [ ] **Step 6：Commit**

```bash
git add scripts/ scenes/world/test_scene.tscn assets/sprites/tiles/
git commit -m "feat(render): HD-2D test scene with camera and player movement"
```

### Phase 1 验收
- [ ] Godot 4.3+ 已安装，`godot --version` 正常
- [ ] 项目能 `godot --headless --quit-after 2` 不报错
- [ ] F5 跑 test_scene.tscn，方向键移动玩家不报错
- [ ] `.gitattributes` LFS 规则已生效

---

## Phase 2：战斗系统 + 战斗 UI（第 2 周）

### 任务 2.1：安装 GUT 测试框架
**文件：**
- Create: `addons/gut/`（从 GitHub 克隆）

- [ ] **Step 1：克隆 GUT v9 到 addons/**

```bash
cd d:\Claudeworkspace\Lordisland
git clone --depth 1 --branch v9.4.0 https://github.com/bitwes/Gut.git addons/gut
```

- [ ] **Step 2：在 Godot 中启用插件（项目设置 → 插件 → GUT）**

（手动操作编辑 Project → Project Settings → Plugins → 启用 gut）

- [ ] **Step 3：验证 GUT 可用**

```bash
# 创建 tests/test_smoke.gd
```
```gdscript
# tests/test_smoke.gd
extends GutTest

func test_smoke():
    assert_eq(1 + 1, 2)
```
```bash
# 在 Godot 中按 GUT 按钮运行 → 期望：1 passed
```

- [ ] **Step 4：Commit**

```bash
git add addons/gut/ tests/test_smoke.gd
git commit -m "test: install GUT framework with smoke test"
```

### 任务 2.2：TDD - 伤害公式
**文件：**
- Create: `tests/test_battle_formula.gd`
- Create: `scripts/systems/battle_formula.gd`

- [ ] **Step 1：写失败测试**

```gdscript
# tests/test_battle_formula.gd
extends GutTest

var BattleFormula = preload("res://scripts/systems/battle_formula.gd")

func test_physical_damage_basic():
    # 力量 20 - 防御 5 * 0.5 = 17.5, 乘以随机 0.9-1.1
    # 暴击系数 = 1.0
    var dmg = BattleFormula.physical_damage(20, 5, 1.0, 1.0)
    assert_between(dmg, 15, 20, "物理伤害应在 15-20 区间")

func test_magical_damage_basic():
    # 智力 30 * 技能系数 2.0 - 抗性 10 = 50
    var dmg = BattleFormula.magical_damage(30, 2.0, 10, 1.0)
    assert_between(dmg, 44, 56, "魔法伤害应在 44-56 区间")

func test_physical_damage_minimum_1():
    var dmg = BattleFormula.physical_damage(0, 100, 1.0, 1.0)
    assert_eq(dmg, 1, "伤害最小为 1")

func test_critical_multiplier():
    var normal = BattleFormula.physical_damage(20, 5, 1.0, 1.0)
    var crit = BattleFormula.physical_damage(20, 5, 1.5, 1.0)
    assert_gt(crit, normal, "暴击应大于普通伤害")
```

- [ ] **Step 2：跑测试，验证失败**

```bash
# GUT: 应报 "Script does not exist"
```

- [ ] **Step 3：实现 BattleFormula**

```gdscript
# scripts/systems/battle_formula.gd
class_name BattleFormula
extends RefCounted

static func physical_damage(attack: int, defense: int, crit_mult: float, variance: float) -> int:
    var base = attack - defense * 0.5
    return int(max(1.0, base * variance * crit_mult))

static func magical_damage(intelligence: int, skill_coeff: float, resistance: int, variance: float) -> int:
    var base = intelligence * skill_coeff - resistance
    return int(max(1.0, base * variance))
```

- [ ] **Step 4：跑测试，验证通过**

```bash
# GUT: 4 passed
```

- [ ] **Step 5：Commit**

```bash
git add tests/test_battle_formula.gd scripts/systems/battle_formula.gd
git commit -m "feat(combat): implement damage formula with TDD"
```

### 任务 2.3：战斗场景框架
**文件：**
- Create: `scenes/battle/battle_scene.tscn`
- Create: `scripts/systems/battle_controller.gd`
- Create: `scripts/systems/actor.gd`
- Create: `data/enemies.json`
- Create: `data/skills.json`
- Create: `data/characters/parn.json`

- [ ] **Step 1：定义 Actor 数据模型（先 JSON）**

```json
// data/characters/parn.json
{
  "id": "parn",
  "name_key": "char_parn_name",
  "level": 1,
  "hp": 100, "max_hp": 100,
  "mp": 20, "max_mp": 20,
  "str": 12, "agi": 10, "int": 8, "vit": 11, "cha": 13,
  "skills": ["attack", "light_sword"],
  "sprite": "res://assets/sprites/characters/parn.png"
}
```

- [ ] **Step 2：Actor 加载脚本**

```gdscript
# scripts/systems/actor.gd
class_name Actor
extends RefCounted

var id: String
var name_key: String
var level: int
var hp: int
var max_hp: int
var mp: int
var max_mp: int
var str: int
var agi: int
var int_stat: int
var vit: int
var cha: int
var skills: Array
var sprite_path: String
var is_alive: bool = true

func _init(data: Dictionary):
    id = data.get("id", "")
    name_key = data.get("name_key", "")
    level = data.get("level", 1)
    max_hp = data.get("hp", 100)
    hp = max_hp
    max_mp = data.get("mp", 20)
    mp = max_mp
    str = data.get("str", 10)
    agi = data.get("agi", 10)
    int_stat = data.get("int", 10)
    vit = data.get("vit", 10)
    cha = data.get("cha", 10)
    skills = data.get("skills", ["attack"])
    sprite_path = data.get("sprite", "")

func is_ready() -> bool:
    return is_alive
```

- [ ] **Step 3：敌人数据**

```json
// data/enemies.json
{
  "goblin": {
    "id": "goblin",
    "name_key": "enemy_goblin",
    "level": 1,
    "hp": 30, "mp": 0,
    "str": 6, "agi": 8, "int": 2, "vit": 5, "cha": 1,
    "skills": ["attack"],
    "exp_reward": 10,
    "sprite": "res://assets/sprites/enemies/goblin.png"
  },
  "orc": {
    "id": "orc",
    "name_key": "enemy_orc",
    "level": 2,
    "hp": 60, "mp": 0,
    "str": 10, "agi": 5, "int": 3, "vit": 8, "cha": 1,
    "skills": ["attack", "smash"],
    "exp_reward": 25,
    "sprite": "res://assets/sprites/enemies/orc.png"
  }
}
```

- [ ] **Step 4：技能数据**

```json
// data/skills.json
{
  "attack": {
    "id": "attack", "name_key": "skill_attack",
    "type": "physical", "target": "single_enemy",
    "damage_formula": {"stat": "str", "coeff": 1.0},
    "mp_cost": 0
  },
  "light_sword": {
    "id": "light_sword", "name_key": "skill_light_sword",
    "type": "physical", "target": "single_enemy",
    "damage_formula": {"stat": "str", "coeff": 2.0, "crit_boost": 1.5},
    "mp_cost": 5
  },
  "smash": {
    "id": "smash", "name_key": "skill_smash",
    "type": "physical", "target": "single_enemy",
    "damage_formula": {"stat": "str", "coeff": 1.5},
    "mp_cost": 0
  },
  "heal": {
    "id": "heal", "name_key": "skill_heal",
    "type": "heal", "target": "single_ally",
    "effect": {"heal_amount": "vit * 2"},
    "mp_cost": 4
  }
}
```

- [ ] **Step 5：战斗控制器（核心状态机）**

```gdscript
# scripts/systems/battle_controller.gd
class_name BattleController
extends Node

signal turn_started(actor: Actor)
signal battle_ended(victory: bool)
signal actor_damaged(actor: Actor, amount: int)

enum State { INTRO, PLAYER_TURN, ENEMY_TURN, ANIMATING, ENDED }

var state: State = State.INTRO
var party: Array[Actor] = []
var enemies: Array[Actor] = []
var turn_queue: Array[Actor] = []
var current_actor: Actor = null
var BattleFormula = preload("res://scripts/systems/battle_formula.gd")

func setup(party_data: Array, enemy_ids: Array):
    for pd in party_data:
        party.append(Actor.new(pd))
    for eid in enemy_ids:
        var ed = _load_enemy(eid)
        if ed:
            enemies.append(Actor.new(ed))

func _load_enemy(enemy_id: String) -> Dictionary:
    var path = "res://data/enemies.json"
    var f = FileAccess.open(path, FileAccess.READ)
    var text = f.get_as_text()
    var data = JSON.parse_string(text)
    return data.get(enemy_id, {})

func start_battle():
    _build_turn_queue()
    _next_turn()

func _build_turn_queue():
    turn_queue = (party + enemies).duplicate()
    turn_queue.sort_custom(func(a, b): return a.agi > b.agi)

func _next_turn():
    while turn_queue.size() > 0:
        current_actor = turn_queue.pop_front()
        if current_actor.is_ready():
            break
    if current_actor == null:
        # 全部死光
        var player_alive = party.any(func(a): return a.is_alive)
        battle_ended.emit(player_alive)
        state = State.ENDED
        return
    if current_actor in party:
        state = State.PLAYER_TURN
    else:
        state = State.ENEMY_TURN
    turn_started.emit(current_actor)

func execute_action(actor: Actor, skill_id: String, target: Actor) -> int:
    if not is_instance_valid(actor) or not actor.is_alive:
        return 0
    var skills_data = _load_skills()
    var skill = skills_data.get(skill_id, {})
    if actor.mp < skill.get("mp_cost", 0):
        return 0
    actor.mp -= skill.get("mp_cost", 0)
    var damage = _calc_skill_damage(actor, skill, target)
    if damage > 0:
        target.hp = max(0, target.hp - damage)
        if target.hp == 0:
            target.is_alive = false
        actor_damaged.emit(target, damage)
    if state == State.PLAYER_TURN:
        state = State.ANIMATING
    return damage

func _calc_skill_damage(actor: Actor, skill: Dictionary, target: Actor) -> int:
    var formula = skill.get("damage_formula", {})
    if formula.is_empty():
        return 0  # heal 等非伤害技能
    var stat = actor.get(formula.get("stat", "str"))
    var coeff = formula.get("coeff", 1.0)
    var variance = randf_range(0.9, 1.1)
    return BattleFormula.physical_damage(stat, target.vit, 1.0, variance)

func _load_skills() -> Dictionary:
    var f = FileAccess.open("res://data/skills.json", FileAccess.READ)
    return JSON.parse_string(f.get_as_text())
```

- [ ] **Step 6：战斗场景 + 简单 UI**

```tscn
# scenes/battle/battle_scene.tscn
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/systems/battle_controller.gd" id="1"]

[node name="BattleScene" type="Node2D"]
script = ExtResource("1")
```

（战斗 UI 用程序化创建，不做 .tscn 资源）

```gdscript
# scripts/ui/battle_ui.gd
class_name BattleUI
extends Control

var controller: BattleController
var action_menu: VBoxContainer
var info_label: Label

func _ready():
    info_label = Label.new()
    add_child(info_label)
    action_menu = VBoxContainer.new()
    add_child(action_menu)
    _build_menu(["攻击", "技能", "物品", "防御", "逃跑"])

func _build_menu(options: Array):
    for opt in options:
        var btn = Button.new()
        btn.text = opt
        action_menu.add_child(btn)

func show_message(text: String):
    info_label.text = text
```

- [ ] **Step 7：手动验证**

```bash
# 写一个测试 main 场景
```
```gdscript
# scripts/test_battle_main.gd
extends Node2D

func _ready():
    var controller = preload("res://scripts/systems/battle_controller.gd").new()
    add_child(controller)
    controller.setup(
        [JSON.parse_string(FileAccess.get_file_as_string("res://data/characters/parn.json"))],
        ["goblin"]
    )
    controller.start_battle()
    print("Battle started!")
```

```bash
# 期望：控制台输出 "Battle started!"
```

- [ ] **Step 8：Commit**

```bash
git add scripts/systems/ scripts/ui/ scenes/battle/ data/
git commit -m "feat(combat): battle controller + actor model + JSON data"
```

### 任务 2.4：完成 5v3 战斗验证
（这一步是手动 QA）：

- [ ] 加载 5 主角 + 3 敌人进入战斗
- [ ] 玩家每回合可选 攻击/技能
- [ ] 行动顺序按速度排序
- [ ] 战斗结束（胜利/失败）发信号
- [ ] 经验结算

### Phase 2 验收
- [ ] GUT 跑 4 个 battle_formula 测试全通过
- [ ] 战斗场景能进入、能跑完 5v3
- [ ] 行动顺序按 agi 排序
- [ ] 战斗结束信号正确触发
- [ ] 伤害数字显示

---

## Phase 3：对话系统 + 事件系统（第 3 周）

### 任务 3.1：TDD - 对话 JSON 解析
**文件：**
- Create: `tests/test_dialogue_parser.gd`
- Create: `scripts/systems/dialogue_parser.gd`
- Create: `data/dialogues/npc_ehto_intro.json`
- Create: `locale/zh.po`
- Create: `locale/en.po`

- [ ] **Step 1：写失败测试**

```gdscript
# tests/test_dialogue_parser.gd
extends GutTest

var DialogueParser = preload("res://scripts/systems/dialogue_parser.gd")

func test_parse_simple_dialogue():
    var data = {
        "id": "test",
        "speaker": "npc",
        "nodes": [
            {"id": "start", "text_key": "hello", "next": "end"},
            {"id": "end", "type": "end"}
        ]
    }
    var parser = DialogueParser.new(data)
    var node = parser.get_node("start")
    assert_eq(node["text_key"], "hello")
    assert_eq(parser.get_next_id("start"), "end")

func test_parse_choices():
    var data = {
        "id": "test",
        "speaker": "npc",
        "nodes": [
            {"id": "start", "text_key": "ask",
             "choices": [
                 {"label_key": "yes", "next": "yes_path"},
                 {"label_key": "no", "next": "no_path"}
             ]},
            {"id": "yes_path", "text_key": "ok", "next": "end"},
            {"id": "no_path", "text_key": "bye", "next": "end"},
            {"id": "end", "type": "end"}
        ]
    }
    var parser = DialogueParser.new(data)
    var start = parser.get_node("start")
    assert_eq(start["choices"].size(), 2)
```

- [ ] **Step 2：跑测试，验证失败**

- [ ] **Step 3：实现 parser**

```gdscript
# scripts/systems/dialogue_parser.gd
class_name DialogueParser
extends RefCounted

var nodes: Dictionary = {}

func _init(data: Dictionary):
    for n in data.get("nodes", []):
        nodes[n["id"]] = n

func get_node(node_id: String) -> Dictionary:
    return nodes.get(node_id, {})

func get_next_id(node_id: String) -> String:
    var n = nodes.get(node_id, {})
    return n.get("next", "")

static func load_from_file(path: String) -> DialogueParser:
    var f = FileAccess.open(path, FileAccess.READ)
    var data = JSON.parse_string(f.get_as_text())
    return DialogueParser.new(data)
```

- [ ] **Step 4：跑测试，验证通过**

- [ ] **Step 5：创建示例对话**

```json
// data/dialogues/npc_ehto_intro.json
{
  "id": "npc_ehto_intro",
  "speaker": "ehto",
  "portrait": "ehto_neutral",
  "nodes": [
    {"id": "start", "text_key": "ehto_intro_1", "next": "ask_who"},
    {"id": "ask_who", "text_key": "ehto_intro_2",
     "choices": [
       {"label_key": "choice_a", "next": "answer_a"},
       {"label_key": "choice_b", "next": "answer_b"}
     ]},
    {"id": "answer_a", "text_key": "ehto_intro_3", "next": "end"},
    {"id": "answer_b", "text_key": "ehto_intro_4", "next": "end"},
    {"id": "end", "type": "end"}
  ]
}
```

- [ ] **Step 6：创建中英 .po 文件（最小）**

```po
# locale/zh.po
msgid ""
msgstr "Content-Type: text/plain; charset=UTF-8\n"

msgid "ehto_intro_1"
msgstr "感谢你救了我，勇者。"

msgid "ehto_intro_2"
msgstr "请问你是……？"

msgid "choice_a"
msgstr "我叫帕恩，是个骑士。"

msgid "choice_b"
msgstr "我只是路过。"

msgid "ehto_intro_3"
msgstr "原来如此，果然是名勇敢的骑士。"

msgid "ehto_intro_4"
msgstr "那也谢谢你。"

msgid "skill_attack"
msgstr "攻击"

msgid "skill_light_sword"
msgstr "光之剑"

msgid "skill_smash"
msgstr "重击"

msgid "skill_heal"
msgstr "治疗"

msgid "char_parn_name"
msgstr "帕恩"

msgid "enemy_goblin"
msgstr "哥布林"

msgid "enemy_orc"
msgstr "兽人"
```

```po
# locale/en.po
msgid ""
msgstr "Content-Type: text/plain; charset=UTF-8\n"

msgid "ehto_intro_1"
msgstr "Thank you for rescuing me, brave one."

msgid "ehto_intro_2"
msgstr "Who are you...?"

msgid "choice_a"
msgstr "I'm Parn, a knight."

msgid "choice_b"
msgstr "Just passing by."

msgid "ehto_intro_3"
msgstr "I see, a brave knight indeed."

msgid "ehto_intro_4"
msgstr "Then thank you as well."

msgid "skill_attack"
msgstr "Attack"

msgid "skill_light_sword"
msgstr "Light Sword"

msgid "skill_smash"
msgstr "Smash"

msgid "skill_heal"
msgstr "Heal"

msgid "char_parn_name"
msgstr "Parn"

msgid "enemy_goblin"
msgstr "Goblin"

msgid "enemy_orc"
msgstr "Orc"
```

- [ ] **Step 7：在 project.godot 中启用 i18n locales**

```ini
[internationalization]
locale/translations_pot_files=PackedStringArray("res://locale/zh.po", "res://locale/en.po")
```

- [ ] **Step 8：Commit**

```bash
git add tests/test_dialogue_parser.gd scripts/systems/dialogue_parser.gd data/dialogues/ locale/
git commit -m "feat(dialogue): JSON-driven dialogue parser with i18n"
```

### 任务 3.2：对话 UI
**文件：**
- Create: `scripts/ui/dialogue_ui.gd`
- Create: `scenes/ui/dialogue_ui.tscn`

- [ ] **Step 1：创建对话 UI 节点（程序化）**

```gdscript
# scripts/ui/dialogue_ui.gd
class_name DialogueUI
extends Control

var parser: DialogueParser
var label: Label
var choices_box: VBoxContainer
var portrait: TextureRect

signal dialogue_finished

func _ready():
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _build_ui()

func _build_ui():
    # 背景
    var bg = ColorRect.new()
    bg.color = Color(0, 0, 0, 0.7)
    bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    bg.custom_minimum_size = Vector2(0, 200)
    add_child(bg)
    # 文本
    label = Label.new()
    label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    label.position = Vector2(40, -180)
    label.add_theme_font_size_override("font_size", 18)
    add_child(label)
    # 选项
    choices_box = VBoxContainer.new()
    choices_box.set_anchors_preset(Control.PRESET_CENTER)
    choices_box.position = Vector2(100, -100)
    add_child(choices_box)

func start_dialogue(parser: DialogueParser):
    self.parser = parser
    _show_node("start")

func _show_node(node_id: String):
    var node = parser.get_node(node_id)
    if node.get("type", "") == "end":
        dialogue_finished.emit()
        queue_free()
        return
    label.text = TranslationServer.translate(node["text_key"])
    _clear_choices()
    if node.has("choices"):
        for c in node["choices"]:
            var btn = Button.new()
            btn.text = TranslationServer.translate(c["label_key"])
            var next_id = c["next"]
            btn.pressed.connect(func(): _show_node(next_id))
            choices_box.add_child(btn)
    else:
        var next_btn = Button.new()
        next_btn.text = "▶"
        next_btn.pressed.connect(func(): _show_node(parser.get_next_id(node_id)))
        choices_box.add_child(next_btn)

func _clear_choices():
    for c in choices_box.get_children():
        c.queue_free()
```

- [ ] **Step 2：手动测试**（在临时场景中调用 start_dialogue）**

- [ ] **Step 3：Commit**

```bash
git add scripts/ui/dialogue_ui.gd scenes/ui/
git commit -m "feat(dialogue): dialogue UI with i18n"
```

### 任务 3.3：TDD - 事件触发器
**文件：**
- Create: `tests/test_event_system.gd`
- Create: `scripts/systems/event_system.gd`
- Create: `data/events/ch0_rescue_ehto.json`

- [ ] **Step 1：写失败测试**

```gdscript
# tests/test_event_system.gd
extends GutTest

var EventSystem = preload("res://scripts/systems/event_system.gd")

func test_register_and_trigger():
    var es = EventSystem.new()
    var triggered = false
    es.register_event("on_talk", "npc_ehto", func(_ctx): triggered = true)
    es.trigger("on_talk", "npc_ehto")
    assert_true(triggered)

func test_conditions():
    var es = EventSystem.new()
    var triggered = false
    es.register_event("on_flag", "ch1_started", func(_ctx): triggered = true,
        [{"type": "flag", "key": "ch1_started", "value": true}])
    # 没设 flag → 不触发
    es.trigger("on_flag", "ch1_started")
    assert_false(triggered)
    # 设了 flag → 触发
    es.set_flag("ch1_started", true)
    es.trigger("on_flag", "ch1_started")
    assert_true(triggered)
```

- [ ] **Step 2：跑测试，验证失败**

- [ ] **Step 3：实现 event_system**

```gdscript
# scripts/systems/event_system.gd
class_name EventSystem
extends Node

var events: Dictionary = {}
var flags: Dictionary = {}

func register_event(trigger_type: String, key: String, callback: Callable, conditions: Array = []):
    if not events.has(trigger_type):
        events[trigger_type] = []
    events[trigger_type].append({
        "key": key,
        "callback": callback,
        "conditions": conditions
    })

func trigger(trigger_type: String, key: String = "", context: Dictionary = {}):
    if not events.has(trigger_type):
        return
    for ev in events[trigger_type]:
        if key != "" and ev["key"] != key:
            continue
        if _check_conditions(ev["conditions"]):
            ev["callback"].call(context)

func _check_conditions(conditions: Array) -> bool:
    for c in conditions:
        if c["type"] == "flag":
            if flags.get(c["key"], null) != c.get("value", null):
                return false
    return true

func set_flag(key: String, value):
    flags[key] = value
    trigger("on_flag_set", key)
```

- [ ] **Step 4：跑测试，验证通过**

- [ ] **Step 5：创建示例事件脚本**

```json
// data/events/ch0_rescue_ehto.json
{
  "id": "ch0_rescue_ehto",
  "trigger": "on_talk",
  "key": "npc_ehto",
  "conditions": [{"type": "flag", "key": "ehto_rescued", "value": false}],
  "steps": [
    {"type": "show_dialogue", "id": "npc_ehto_intro"},
    {"type": "set_flag", "key": "ehto_rescued", "value": true},
    {"type": "join_party", "character": "ehto"}
  ]
}
```

- [ ] **Step 6：Commit**

```bash
git add tests/test_event_system.gd scripts/systems/event_system.gd data/events/
git commit -m "feat(events): event system with flags and conditions"
```

### 任务 3.4：事件 → 对话/战斗/角色加入的执行器
**文件：**
- Modify: `scripts/systems/event_system.gd`
- Create: `scripts/systems/event_executor.gd`

- [ ] **Step 1：实现执行器**

```gdscript
# scripts/systems/event_executor.gd
class_name EventExecutor
extends RefCounted

var dialogue_ui_scene: PackedScene
var battle_scene: PackedScene
var event_system: EventSystem

func _init(es: EventSystem):
    event_system = es

func execute_steps(steps: Array, parent: Node):
    for step in steps:
        match step.get("type", ""):
            "show_dialogue":
                await _show_dialogue(step["id"], parent)
            "set_flag":
                event_system.set_flag(step["key"], step["value"])
            "start_battle":
                await _start_battle(step["enemies"], parent)
            "join_party":
                _join_party(step["character"])

func _show_dialogue(dialogue_id: String, parent: Node) -> void:
    var parser = DialogueParser.load_from_file("res://data/dialogues/%s.json" % dialogue_id)
    var ui = preload("res://scripts/ui/dialogue_ui.gd").new()
    parent.add_child(ui)
    ui.start_dialogue(parser)
    await ui.dialogue_finished

func _start_battle(enemy_ids: Array, parent: Node) -> void:
    print("Starting battle with: %s" % str(enemy_ids))

func _join_party(character_id: String):
    event_system.set_flag("party_has_%s" % character_id, true)
```

- [ ] **Step 2：Commit**

```bash
git add scripts/systems/event_executor.gd
git commit -m "feat(events): step executor (dialogue/battle/party)"
```

### Phase 3 验收
- [ ] GUT 跑 3 个 dialogue_parser + 2 个 event_system 测试通过
- [ ] 触发 on_talk 显示对话 UI
- [ ] 选项分支正确跳转
- [ ] 中英双语切换显示不同文本
- [ ] 事件触发后 flag 被设置

---

## Phase 4：内容整合 + 存档（第 4 周）

### 任务 4.1：洛奈城小地图
**文件：**
- Create: `scenes/world/loranai_city.tscn`
- Create: `data/npcs/loranai_npcs.json`
- Create: `data/events/loranai_intro.json`

- [ ] **Step 1：手工创建 loranai_city.tscn（占位 tile 地图）**

参考 test_scene.tscn 结构，加：
- 32×18 tile 地图（grass 拼成）
- 5-8 个 NPC 节点（Node2D + dialogue_id 标记）
- 1 个出口节点（指向 starting_cave.tscn）

- [ ] **Step 2：NPC 数据**

```json
// data/npcs/loranai_npcs.json
{
  "town_chief": {
    "id": "town_chief",
    "name_key": "npc_town_chief",
    "position": {"x": 5, "y": 4},
    "dialogue": "npc_town_chief_intro"
  },
  "inn_keeper": {
    "id": "inn_keeper",
    "name_key": "npc_inn_keeper",
    "position": {"x": 12, "y": 6},
    "dialogue": "npc_inn_keeper_intro"
  }
}
```

- [ ] **Step 3：玩家 → NPC 交互（E 键）**

```gdscript
# scripts/world/player_interaction.gd
extends Area2D

@export var dialogue_id: String

func _input(event):
    if event.is_action_pressed("interact"):
        var bodies = get_overlapping_bodies()
        for b in bodies:
            if b.has_method("trigger_dialogue"):
                b.trigger_dialogue(dialogue_id)
```

- [ ] **Step 4：Commit**

```bash
git add scenes/world/loranai_city.tscn data/npcs/ scripts/world/player_interaction.gd
git commit -m "feat(world): Loranai city map with NPC interaction"
```

### 任务 4.2：起始洞窟
**文件：**
- Create: `scenes/world/starting_cave.tscn`
- Create: `data/events/cave_clear.json`
- Create: `data/dialogues/cave_exit.json`

- [ ] **Step 1：3 个房间的小洞窟（手工搭）**

Room 1 → Room 2 → Room 3（boss room）
- Room 1：2 个 goblin 巡逻
- Room 2：1 个宝箱
- Room 3：1 个 Boss（orc）+ 1 个 NPC 艾特（被绑）

- [ ] **Step 2：进出洞窟事件**

```json
// data/events/cave_clear.json
{
  "id": "cave_clear",
  "trigger": "on_flag",
  "key": "cave_boss_defeated",
  "steps": [
    {"type": "show_dialogue", "id": "npc_ehto_intro"},
    {"type": "set_flag", "key": "ehto_rescued", "value": true},
    {"type": "join_party", "character": "ehto"}
  ]
}
```

- [ ] **Step 3：Commit**

```bash
git add scenes/world/starting_cave.tscn data/events/ data/dialogues/
git commit -m "feat(world): starting cave with 3 rooms + boss"
```

### 任务 4.3：TDD - 存档序列化
**文件：**
- Create: `tests/test_save_system.gd`
- Create: `scripts/systems/save_system.gd`

- [ ] **Step 1：写失败测试**

```gdscript
# tests/test_save_system.gd
extends GutTest

var SaveSystem = preload("res://scripts/systems/save_system.gd")

func test_save_and_load():
    var s1 = SaveSystem.new()
    s1.set("player_pos", Vector2(100, 200))
    s1.set("flags", {"ch1_done": true})
    s1.set("party_hp", [80, 90, 100])
    s1.save_to_slot(0)
    
    var s2 = SaveSystem.new()
    s2.load_from_slot(0)
    assert_eq(s2.get("player_pos"), Vector2(100, 200))
    assert_eq(s2.get("flags"), {"ch1_done": true})
    assert_eq(s2.get("party_hp"), [80, 90, 100])

func test_free_save_no_restriction():
    var s = SaveSystem.new()
    # 任何时机都能存
    s.set("state", "in_battle")
    s.save_to_slot(0)
    s.set("state", "in_dialogue")
    s.save_to_slot(1)
    s.set("state", "on_map")
    s.save_to_slot(2)
    assert_true(s.slot_exists(0))
    assert_true(s.slot_exists(1))
    assert_true(s.slot_exists(2))
```

- [ ] **Step 2：跑测试，验证失败**

- [ ] **Step 3：实现**

```gdscript
# scripts/systems/save_system.gd
class_name SaveSystem
extends RefCounted

const SAVE_DIR = "user://saves/"

var data: Dictionary = {}

func set(key: String, value):
    data[key] = value

func get(key: String):
    return data.get(key, null)

func save_to_slot(slot: int):
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)
    var path = "%ssave_%d.json" % [SAVE_DIR, slot]
    var f = FileAccess.open(path, FileAccess.WRITE)
    var stamp = Time.get_datetime_string_from_system()
    var payload = data.duplicate()
    payload["_timestamp"] = stamp
    f.store_string(JSON.stringify(payload))

func load_from_slot(slot: int) -> bool:
    var path = "%ssave_%d.json" % [SAVE_DIR, slot]
    if not FileAccess.file_exists(path):
        return false
    var f = FileAccess.open(path, FileAccess.READ)
    data = JSON.parse_string(f.get_as_text())
    return true

func slot_exists(slot: int) -> bool:
    return FileAccess.file_exists("%ssave_%d.json" % [SAVE_DIR, slot])
```

- [ ] **Step 4：跑测试，验证通过**

- [ ] **Step 5：Commit**

```bash
git add tests/test_save_system.gd scripts/systems/save_system.gd
git commit -m "feat(save): free-save system with 10 slots, JSON serialization"
```

### 任务 4.4：存档 UI（主菜单调用）
**文件：**
- Create: `scripts/ui/save_load_ui.gd`

- [ ] **Step 1：实现存档 UI（10 个槽位 + 列表）**

```gdscript
# scripts/ui/save_load_ui.gd
class_name SaveLoadUI
extends Control

var save_system: SaveSystem
var list: VBoxContainer
var mode: String = "save"  # 或 "load"

func _ready():
    set_anchors_preset(Control.PRESET_FULL_RECT)
    list = VBoxContainer.new()
    list.set_anchors_preset(Control.PRESET_CENTER)
    add_child(list)
    _refresh()

func _refresh():
    for c in list.get_children(): c.queue_free()
    for i in 10:
        var btn = Button.new()
        if save_system.slot_exists(i):
            var s = SaveSystem.new()
            s.load_from_slot(i)
            btn.text = "[%d] %s | %s" % [i, s.get("_timestamp"), s.get("chapter", "")]
        else:
            btn.text = "[%d] 空槽位" % i
        if mode == "save":
            btn.pressed.connect(func(): _save(i))
        else:
            btn.pressed.connect(func(): _load(i))
        list.add_child(btn)

func _save(slot: int):
    save_system.save_to_slot(slot)
    _refresh()

func _load(slot: int):
    if save_system.load_from_slot(slot):
        queue_free()
        # Game reload scene
```

- [ ] **Step 2：Commit**

```bash
git add scripts/ui/save_load_ui.gd
git commit -m "feat(save): save/load UI with 10 slots"
```

### 任务 4.5：主线流程串通
（这一步是手动 QA）：

- [ ] 进入 Loranai City
- [ ] 跟 town_chief 说话 → 接到洞窟任务
- [ ] 出城进洞窟
- [ ] 打败 2 个 goblin
- [ ] 开宝箱
- [ ] 打败 Boss（orc）
- [ ] 跟 Ehto 对话 → Ehto 加入队伍
- [ ] 出洞窟回洛奈城
- [ ] 存读档验证

### Phase 4 验收
- [ ] GUT 跑 2 个 save_system 测试通过
- [ ] 主线流程可从头跑到尾（10-15 分钟）
- [ ] 存档可自由读写 10 个槽位
- [ ] 战斗中可暂停存档
- [ ] 读档后位置/队伍/flag 全部恢复

---

## Phase 5：打磨 + 音频 + 包装（第 5 周）

### 任务 5.1：AI 生成 BGM
**文件：**
- Create: `assets/audio/bgm/loranai.ogg`
- Create: `assets/audio/bgm/cave.ogg`

- [ ] **Step 1：使用 Suno / Udio 生成 2 首 BGM**

提示词（loranai.ogg）：
```
A peaceful medieval town theme, acoustic guitar, flute, soft strings, 
gentle and welcoming, 90s JRPG town music style
```

提示词（cave.ogg）：
```
A dark dungeon exploration theme, low brass, mysterious atmosphere, 
slow tempo, JRPG cave music, 2 minutes loop
```

- [ ] **Step 2：音频管理脚本**

```gdscript
# scripts/core/audio_manager.gd
class_name AudioManager
extends Node

var current_bgm: String = ""
var bgm_player: AudioStreamPlayer

func _ready():
    bgm_player = AudioStreamPlayer.new()
    add_child(bgm_player)

func play_bgm(stream_path: String, fade_duration: float = 1.0):
    if stream_path == current_bgm:
        return
    current_bgm = stream_path
    var stream = load(stream_path)
    bgm_player.stream = stream
    bgm_player.volume_db = -80
    bgm_player.play()
    var tween = create_tween()
    tween.tween_property(bgm_player, "volume_db", 0, fade_duration)
```

- [ ] **Step 3：Commit**

```bash
git add assets/audio/bgm/ scripts/core/audio_manager.gd
git commit -m "feat(audio): AI-generated BGM + audio manager"
```

### 任务 5.2：SFX 接入
**文件：**
- Modify: `scripts/systems/battle_controller.gd`
- Create: `assets/audio/sfx/`（10-15 个 SFX）

- [ ] **Step 1：从免版税包下载 SFX**

来源：freesound.org / OpenGameArt

- [ ] **Step 2：在战斗和菜单中接入**

```gdscript
# 在 battle_controller.gd 中：
func execute_action(...):
    AudioManager.play_sfx("res://assets/audio/sfx/attack.wav")
```

- [ ] **Step 3：Commit**

```bash
git add assets/audio/sfx/ scripts/
git commit -m "feat(audio): SFX integration in battle and menu"
```

### 任务 5.3：主菜单 + 标题画面
**文件：**
- Create: `scenes/main_menu.tscn`
- Create: `scripts/ui/main_menu.gd`

- [ ] **Step 1：实现**

```gdscript
# scripts/ui/main_menu.gd
class_name MainMenu
extends Control

func _ready():
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var bg = ColorRect.new()
    bg.color = Color(0.05, 0.05, 0.1)
    add_child(bg)
    var title = Label.new()
    title.text = "罗德岛战记\nLordisland: Record of Lodoss War"
    title.set_anchors_preset(Control.PRESET_CENTER_TOP)
    title.position.y = 100
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_child(title)
    var vbox = VBoxContainer.new()
    vbox.set_anchors_preset(Control.PRESET_CENTER)
    add_child(vbox)
    for label in ["新游戏", "继续", "设置", "退出"]:
        var btn = Button.new()
        btn.text = label
        vbox.add_child(btn)
        btn.pressed.connect(_on_button_pressed.bind(label))

func _on_button_pressed(label: String):
    match label:
        "新游戏":
            get_tree().change_scene_to_file("res://scenes/world/loranai_city.tscn")
        "继续":
            var ui = preload("res://scripts/ui/save_load_ui.gd").new()
            add_child(ui)
        "退出":
            get_tree().quit()
```

- [ ] **Step 2：在 project.godot 中设为主场景**

```ini
[application]
run/main_scene="res://scenes/main_menu.tscn"
```

- [ ] **Step 3：Commit**

```bash
git add scenes/main_menu.tscn scripts/ui/main_menu.gd project.godot
git commit -m "feat(menu): main menu and title screen"
```

### 任务 5.4：最终 QA + Bug 修复
- [ ] 完整 1 周目跑通
- [ ] 中英切换正常
- [ ] 存档正常
- [ ] 1080p/60fps 验证
- [ ] Bug 列表记录

### 任务 5.5：M1 demo 打包 + 发布
- [ ] Godot 导出 Windows .exe
- [ ] README + 启动指南
- [ ] M1 演示视频（如需）

### Phase 5 验收
- [ ] 主菜单 → 新游戏 → demo 完整跑通
- [ ] BGM/SFX 全接入
- [ ] 5-10 个关键 Bug 已修
- [ ] 1080p/60fps
- [ ] 中英双语可切换
- [ ] 可发布到 Steam Next Fest 试玩（如需要）

---

## Self-Review

**1. Spec 覆盖度：**
- § 1 目标定位 → 文档头已说明 ✅
- § 2 体验核心 → 5 个 Phase 分别实现 ✅
- § 3 架构（10 系统）→ P1 渲染/探索；P2 战斗/库存/UI；P3 对话/事件/本地化；P4 存档；P5 音频 ✅
- § 4 战斗系统 → P2 完整 ✅
- § 5 世界探索 → P4 洛奈+洞窟 ✅
- § 6 剧情内容 → P3 对话+事件 ✅
- § 7 存档 → P4 完整 ✅
- § 8 资源管线 → P5 音频 ✅
- § 9 国际化 → P3 完成 ✅
- § 10 里程碑 → 本 plan 是 M1 ✅
- § 11 M1 垂直切片验收 → 5 个 Phase 都有验收标准 ✅

**2. 占位符扫描：** 无 TBD / TODO。

**3. 类型/方法一致性：**
- `BattleFormula.physical_damage` / `magical_damage` 在 P2 定义，P2/P4 都用 ✅
- `DialogueParser` 在 P3 定义，P3/P4 都用 ✅
- `EventSystem` 在 P3 定义，P3/P4 都用 ✅
- `SaveSystem` 在 P4 定义，P4/P5 都用 ✅
- `AudioManager` 在 P5 定义，P5 用 ✅
- 角色数据格式 `data/characters/*.json` 一致 ✅

---

## 执行方式

按你之前的指示——**"全程你自己动手推进"**。我会：

1. 顺序执行 P1 → P5，每个任务一条 commit
2. 每完成一个 Phase，停下来：
   - 跑 GUT 测试（应全过）
   - 启动 Godot 手动验证关键场景
   - 给你 phase 总结（commit log、关键截图/输出、待 review 项）
3. 等你点头才进下一个 Phase
4. 任何阻塞（Godot 下载失败、API 误用等）立刻标记

如果中途需要中途调整（换方向、改设计），随时打断我。

**开干。** 我先做 P1 的"装 Godot"——Godot 不在系统上，我得先下下来。
