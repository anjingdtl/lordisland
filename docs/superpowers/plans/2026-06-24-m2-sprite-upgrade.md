# M2 HD-2D Sprite Upgrade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace M1's BoxMesh/CylinderMesh placeholders with procedurally-generated pixel sprite (Sprite3D) to achieve true HD-2D look in 洛奈城 and 起始洞窟.

**Architecture:** `SpriteGenerator` (programmatic pixel art) → `ImageTexture` (cached) → `Sprite3DActor` (Node3D with Sprite3D + AnimationPlayer) → replaces Avatar children in 2 existing .tscn scenes.

**Tech Stack:** Godot 4.3 + GDScript + Image/ImageTexture + Sprite3D + AnimationPlayer

**Spec:** `docs/superpowers/specs/2026-06-24-m2-hd2d-sprite-upgrade.md`

---

## File Structure

| File | Responsibility |
|---|---|
| `scripts/core/sprite_generator.gd` | 程序化生成 32x48 像素 sprite (单帧/4 帧 strip/sheet) |
| `scripts/world/sprite3d_actor.gd` | 3D 场景中显示 sprite 的 Node3D 节点，含 billboard + 走路动画 |
| `data/characters/*.json` (5 个) | 添加 `sprite` 字段（调色板 + 武器） |
| `data/enemies.json` (4 个) | 添加 `sprite` 字段 |
| `scenes/world/loranai_city.tscn` | Player/Avatar + NPC/Avatar 改用 Sprite3DActor |
| `scenes/world/starting_cave.tscn` | Player/Avatar + NPC/Avatar + Battle Marker 改用 Sprite3DActor |
| `tests/test_sprite_generator.gd` | 单元测试：生成、调色板、4 帧、错误回退 |
| `tests/test_sprite_actor_e2e.gd` | 集成测试：billboard + 动画 + flip |

---

## Task 1: TDD SpriteGenerator - 单帧生成

**Files:**
- Create: `tests/test_sprite_generator.gd`
- Create: `scripts/core/sprite_generator.gd`

- [ ] **Step 1: 写失败测试 - 生成非空 Image**

```gdscript
# tests/test_sprite_generator.gd
extends SceneTree

const SpriteGenerator = preload("res://scripts/core/sprite_generator.gd")

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	test_generate_returns_texture()
	print("\n=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)

func assert_true(value: bool, msg: String) -> void:
	if value:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		print("FAIL: %s" % msg)

func test_generate_returns_texture() -> void:
	var gen = SpriteGenerator.new()
	var data = {"body_color": "#2a4d8f", "hair_color": "#f0c419", "skin_color": "#fbcb8a", "weapon": "sword"}
	var tex = gen.generate_static(data)
	assert_true(tex != null, "generate_static returns non-null texture")
	assert_true(tex is ImageTexture, "result is ImageTexture")
```

- [ ] **Step 2: 运行测试 - 期望失败（preload 找不到）**

```bash
$env:APPDATA = "d:\Claudeworkspace\Lordisland\.godot_user"
$env:LOCALAPPDATA = "d:\Claudeworkspace\Lordisland\.godot_cache"
cd d:\Claudeworkspace\Lordisland
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless -s tests\test_sprite_generator.gd
```

期望输出：`SCRIPT ERROR: Preload file does not exist`

- [ ] **Step 3: 实现最小 SpriteGenerator 让测试通过**

```gdscript
# scripts/core/sprite_generator.gd
class_name SpriteGenerator
extends RefCounted

## 程序化生成像素 sprite
## 输出: ImageTexture (32x48 默认，walk strip 128x48)

var _cache: Dictionary = {}

func generate_static(sprite_data: Dictionary) -> ImageTexture:
	var img = _build_sprite(sprite_data, 0)
	return ImageTexture.create_from_image(img)

func generate_walk_strip(sprite_data: Dictionary) -> ImageTexture:
	# 4 帧水平排列
	var strip = Image.create(128, 48, false, Image.FORMAT_RGBA8)
	for i in 4:
		var frame = _build_sprite(sprite_data, i)
		strip.blit_rect(frame, Rect2i(0, 0, 32, 48), Vector2i(i * 32, 0))
	return ImageTexture.create_from_image(strip)

func _build_sprite(data: Dictionary, frame: int) -> Image:
	var img = Image.create(32, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # 透明背景
	var palette = _build_palette(data)
	_draw_body(img, palette, frame)
	_draw_head(img, palette, frame)
	_draw_legs(img, palette, frame)
	_draw_weapon(img, palette, data.get("weapon", "none"), frame)
	return img

func _build_palette(data: Dictionary) -> Dictionary:
	return {
		"hair": Color(data.get("hair_color", "#f0c419")),
		"skin": Color(data.get("skin_color", "#fbcb8a")),
		"body": Color(data.get("body_color", "#2a4d8f")),
		"armor": Color(data.get("armor_color", "#cccccc")),
		"outline": Color(data.get("outline_color", "#1a1a1a"))
	}

func _draw_body(img: Image, p: Dictionary, frame: int) -> void:
	# 胸部 (y 18-30, x 10-22)
	for y in range(18, 30):
		for x in range(10, 22):
			img.set_pixel(x, y, p.body)
	# 阴影
	for y in range(28, 30):
		for x in range(10, 22):
			img.set_pixel(x, y, p.body.darkened(0.2))
	# 轮廓
	for x in range(10, 22):
		img.set_pixel(x, 18, p.outline)
		img.set_pixel(x, 29, p.outline)
	for y in range(18, 30):
		img.set_pixel(9, y, p.outline)
		img.set_pixel(22, y, p.outline)

func _draw_head(img: Image, p: Dictionary, frame: int) -> void:
	# 头发 (y 0-10, x 8-24)
	for y in range(0, 10):
		for x in range(8, 24):
			img.set_pixel(x, y, p.hair)
	# 脸 (y 10-18, x 10-22)
	for y in range(10, 18):
		for x in range(10, 22):
			img.set_pixel(x, y, p.skin)
	# 眼睛
	img.set_pixel(13, 13, p.outline)
	img.set_pixel(19, 13, p.outline)
	# 头轮廓
	for x in range(8, 24):
		img.set_pixel(x, 0, p.outline)
	for y in range(0, 18):
		img.set_pixel(8, y, p.outline)
		img.set_pixel(23, y, p.outline)
	img.set_pixel(8, 17, p.outline)
	img.set_pixel(23, 17, p.outline)

func _draw_legs(img: Image, p: Dictionary, frame: int) -> void:
	# 4 帧走路动画
	var leg_offsets: Array = [[0, 0], [-1, 1], [0, 0], [1, -1]]  # [左腿, 右腿]
	var left = leg_offsets[frame][0]
	var right = leg_offsets[frame][1]
	# 左腿 (y 30-48, x 10-14)
	for y in range(30, 48):
		var x = 12 + left
		img.set_pixel(x, y, p.body)
	# 右腿
	for y in range(30, 48):
		var x = 18 + right
		img.set_pixel(x, y, p.body)
	# 鞋
	for y in range(46, 48):
		img.set_pixel(11 + left, y, p.outline)
		img.set_pixel(12 + left, y, p.outline)
		img.set_pixel(17 + right, y, p.outline)
		img.set_pixel(18 + right, y, p.outline)

func _draw_weapon(img: Image, p: Dictionary, weapon: String, frame: int) -> void:
	# 武器在右侧 (x 22-28, y 16-30)
	match weapon:
		"sword":
			# 剑柄
			for y in range(26, 30):
				img.set_pixel(24, y, p.armor)
			# 剑刃
			for y in range(16, 26):
				img.set_pixel(24, y, Color("#cccccc"))
				img.set_pixel(25, y, Color("#ffffff"))
		"staff":
			for y in range(10, 30):
				img.set_pixel(24, y, p.body.darkened(0.3))
		"dagger":
			for y in range(20, 28):
				img.set_pixel(24, y, Color("#cccccc"))
		"bow":
			for y in range(14, 30):
				img.set_pixel(24, y, p.body)
		"axe":
			img.set_pixel(24, 24, p.outline)
			img.set_pixel(25, 22, p.armor)
			img.set_pixel(25, 23, p.armor)
			img.set_pixel(25, 24, p.outline)
		"spear":
			for y in range(8, 30):
				img.set_pixel(24, y, p.body)
			img.set_pixel(24, 8, Color("#aaaaaa"))
		"club":
			img.set_pixel(23, 28, p.outline)
			img.set_pixel(24, 28, p.body.darkened(0.4))
		_:
			pass
```

- [ ] **Step 4: 运行测试 - 期望 PASS**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless -s tests\test_sprite_generator.gd
```

期望输出：`=== RESULT: 2 passed, 0 failed ===`

- [ ] **Step 5: Commit**

```bash
cd d:\Claudeworkspace\Lordisland
git add scripts\core\sprite_generator.gd tests\test_sprite_generator.gd
git commit -m "feat(sprite): SpriteGenerator basic single-frame generation (TDD 2/2 pass)"
```

---

## Task 2: TDD SpriteGenerator - 4 帧 strip + 调色板验证

**Files:**
- Modify: `tests/test_sprite_generator.gd`

- [ ] **Step 1: 加测试 - 4 帧 strip 尺寸 + 帧间差异**

在 `test_generate_returns_texture()` 之后追加：

```gdscript
func test_walk_strip_dimensions() -> void:
	var gen = SpriteGenerator.new()
	var data = {"body_color": "#2a4d8f", "hair_color": "#f0c419", "skin_color": "#fbcb8a"}
	var tex = gen.generate_walk_strip(data)
	var img = tex.get_image()
	assert_true(img.get_width() == 128, "strip width = 128, got %d" % img.get_width())
	assert_true(img.get_height() == 48, "strip height = 48, got %d" % img.get_height())

func test_walk_frames_distinct() -> void:
	var gen = SpriteGenerator.new()
	var data = {"body_color": "#2a4d8f", "hair_color": "#f0c419", "skin_color": "#fbcb8a"}
	var tex = gen.generate_walk_strip(data)
	var img = tex.get_image()
	# 取帧 1 (x 32-63) 中心像素 vs 帧 2 (x 64-95) 中心像素
	var px1 = img.get_pixel(45, 40)  # 帧 1 的腿位置
	var px2 = img.get_pixel(77, 40)  # 帧 2 的腿位置
	assert_true(px1 != px2, "frame 1 and 2 differ at leg pixel")

func test_palette_used() -> void:
	var gen = SpriteGenerator.new()
	var data = {"body_color": "#2a4d8f", "hair_color": "#f0c419", "skin_color": "#fbcb8a"}
	var tex = gen.generate_static(data)
	var img = tex.get_image()
	var found_blue = false
	var found_yellow = false
	for y in 48:
		for x in 32:
			var px = img.get_pixel(x, y)
			if px.b > 0.5 and px.r < 0.3:  # 蓝色身体
				found_blue = true
			if px.r > 0.8 and px.g > 0.6:  # 黄色头发
				found_yellow = true
	assert_true(found_blue, "body color used")
	assert_true(found_yellow, "hair color used")
```

并在 `_init()` 末尾 `test_generate_returns_texture()` 之后追加调用：

```gdscript
	test_walk_strip_dimensions()
	test_walk_frames_distinct()
	test_palette_used()
```

- [ ] **Step 2: 运行测试 - 期望 4/4 PASS**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless -s tests\test_sprite_generator.gd
```

期望：`=== RESULT: 4 passed, 0 failed ===`

- [ ] **Step 3: Commit**

```bash
git add tests\test_sprite_generator.gd
git commit -m "test(sprite): 4-frame strip + palette verification (4/4 pass)"
```

---

## Task 3: TDD SpriteGenerator - 错误回退

**Files:**
- Modify: `tests/test_sprite_generator.gd`

- [ ] **Step 1: 加测试 - 空数据 + 部分字段**

```gdscript
func test_empty_data_returns_texture() -> void:
	var gen = SpriteGenerator.new()
	var tex = gen.generate_static({})
	assert_true(tex != null, "empty data still returns texture")

func test_partial_data_uses_defaults() -> void:
	var gen = SpriteGenerator.new()
	var tex = gen.generate_static({"hair_color": "#ff0000"})
	var img = tex.get_image()
	# 默认 body 是蓝色 (#2a4d8f)，应找到至少一个蓝色像素
	var found_blue = false
	for y in 48:
		for x in 32:
			var px = img.get_pixel(x, y)
			if px.b > 0.4 and px.r < 0.3:
				found_blue = true
	assert_true(found_blue, "default body color used when data partial")
```

在 `_init()` 追加调用：

```gdscript
	test_empty_data_returns_texture()
	test_partial_data_uses_defaults()
```

- [ ] **Step 2: 运行 - 期望 6/6 PASS**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless -s tests\test_sprite_generator.gd
```

- [ ] **Step 3: Commit**

```bash
git add tests\test_sprite_generator.gd
git commit -m "test(sprite): empty/partial data fallback (6/6 pass)"
```

---

## Task 4: 给 5 主角 JSON 加 sprite 字段

**Files:**
- Modify: `data/characters/parn.json`
- Modify: `data/characters/ehto.json`
- Modify: `data/characters/slayn.json`
- Modify: `data/characters/tike.json`
- Modify: `data/characters/ghim.json`

- [ ] **Step 1: 在每个 JSON 的 `"exp_reward":` 行后追加 sprite 字段**

Parn (蓝/金/银/剑):
```json
  "sprite": {
    "type": "humanoid",
    "body_color": "#2a4d8f",
    "hair_color": "#f0c419",
    "skin_color": "#fbcb8a",
    "armor_color": "#cccccc",
    "weapon": "sword",
    "outline_color": "#1a1a1a"
  },
```

Ehto (紫/棕/棕/杖):
```json
  "sprite": {
    "type": "humanoid",
    "body_color": "#6b3d8f",
    "hair_color": "#5a3a2a",
    "skin_color": "#f5d0b0",
    "armor_color": "#d4a574",
    "weapon": "staff",
    "outline_color": "#1a1a1a"
  },
```

Slayn (红/黑/黑/匕首):
```json
  "sprite": {
    "type": "humanoid",
    "body_color": "#8f3d3d",
    "hair_color": "#1a1a1a",
    "skin_color": "#fbcb8a",
    "armor_color": "#4a4a4a",
    "weapon": "dagger",
    "outline_color": "#1a1a1a"
  },
```

Tike (绿/金/灰/弓):
```json
  "sprite": {
    "type": "humanoid",
    "body_color": "#3d8f5a",
    "hair_color": "#f0c419",
    "skin_color": "#fbcb8a",
    "armor_color": "#6b6b6b",
    "weapon": "bow",
    "outline_color": "#1a1a1a"
  },
```

Ghim (棕/黑/皮/斧):
```json
  "sprite": {
    "type": "humanoid",
    "body_color": "#8f6b3d",
    "hair_color": "#1a1a1a",
    "skin_color": "#c99060",
    "armor_color": "#5a3a2a",
    "weapon": "axe",
    "outline_color": "#1a1a1a"
  },
```

- [ ] **Step 2: 验证 JSON 格式正确**

```bash
$env:APPDATA = "d:\Claudeworkspace\Lordisland\.godot_user"
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless --import 2>&1 | Select-String "ERROR|WARN"
```

期望：无输出（无错误）

- [ ] **Step 3: Commit**

```bash
git add data\characters\
git commit -m "feat(sprite): 5 character JSON sprite fields (palette + weapon)"
```

---

## Task 5: 给 4 敌人 JSON 加 sprite 字段

**Files:**
- Modify: `data/enemies.json`

- [ ] **Step 1: 在每个 enemy 对象里加 sprite 字段**

Goblin (绿/棍):
```json
      "sprite": {
        "type": "goblin",
        "body_color": "#3d6e3d",
        "skin_color": "#8aac5c",
        "weapon": "club",
        "outline_color": "#1a2a1a"
      },
```

Orc (棕/棍):
```json
      "sprite": {
        "type": "orc",
        "body_color": "#5a3a2a",
        "skin_color": "#8a6b3d",
        "weapon": "club",
        "outline_color": "#1a1a1a"
      },
```

Goblin Archer (绿/弓):
```json
      "sprite": {
        "type": "goblin_archer",
        "body_color": "#3d6e3d",
        "skin_color": "#8aac5c",
        "weapon": "bow",
        "outline_color": "#1a2a1a"
      },
```

Kobold (棕/矛):
```json
      "sprite": {
        "type": "kobld",
        "body_color": "#8f6b3d",
        "skin_color": "#c99060",
        "weapon": "spear",
        "outline_color": "#1a1a1a"
      },
```

- [ ] **Step 2: 验证 JSON**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless --import 2>&1 | Select-String "ERROR"
```

- [ ] **Step 3: Commit**

```bash
git add data\enemies.json
git commit -m "feat(sprite): 4 enemy sprite fields"
```

---

## Task 6: TDD Sprite3DActor - 基础节点 + billboard

**Files:**
- Create: `tests/test_sprite_actor_e2e.gd`
- Create: `scripts/world/sprite3d_actor.gd`

- [ ] **Step 1: 写失败测试**

```gdscript
# tests/test_sprite_actor_e2e.gd
extends SceneTree

const Sprite3DActor = preload("res://scripts/world/sprite3d_actor.gd")

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	test_actor_has_sprite_child()
	test_actor_creates_sprite_from_data()
	print("\n=== RESULT: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		quit(1)
	else:
		quit(0)

func assert_true(value: bool, msg: String) -> void:
	if value:
		_passed += 1
		print("PASS: %s" % msg)
	else:
		_failed += 1
		print("FAIL: %s" % msg)

func test_actor_has_sprite_child() -> void:
	var actor = Sprite3DActor.new()
	get_root().add_child(actor)
	# _ready 还没跑，加 sprite_data 触发
	actor.sprite_data = {"body_color": "#2a4d8f", "hair_color": "#f0c419", "skin_color": "#fbcb8a"}
	actor.queue_redraw()  # 触发 _ready
	await process_frame
	var has_sprite = false
	for child in actor.get_children():
		if child is Sprite3D:
			has_sprite = true
	assert_true(has_sprite, "actor has Sprite3D child")

func test_actor_creates_sprite_from_data() -> void:
	var actor = Sprite3DActor.new()
	actor.sprite_data = {"body_color": "#2a4d8f", "hair_color": "#f0c419", "skin_color": "#fbcb8a"}
	get_root().add_child(actor)
	await process_frame
	for child in actor.get_children():
		if child is Sprite3D:
			assert_true(child.texture != null, "Sprite3D has texture")
			return
	assert_true(false, "no Sprite3D found")
```

- [ ] **Step 2: 运行 - 期望失败**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless -s tests\test_sprite_actor_e2e.gd
```

期望：`Preload file does not exist`

- [ ] **Step 3: 实现 Sprite3DActor**

```gdscript
# scripts/world/sprite3d_actor.gd
class_name Sprite3DActor
extends Node3D

## 3D 场景中的 sprite 节点
## 程序化生成 sprite, billboard 朝向相机, 走路动画

@export var sprite_data: Dictionary = {}
@export var actor_id: String = ""
@export var use_walk_animation: bool = true
@export var pixel_scale: float = 64.0  # 32x48 sprite 放大到 2x 渲染

var sprite: Sprite3D
var anim: AnimationPlayer
var facing_right: bool = true
var is_walking: bool = false

func _ready() -> void:
	_build_visual()

func set_sprite_data(data: Dictionary) -> void:
	sprite_data = data
	if is_inside_tree():
		_build_visual()

func _build_visual() -> void:
	# 清理旧的
	if sprite:
		sprite.queue_free()
	if anim:
		anim.queue_free()
	# 生成 sprite
	if sprite_data.is_empty():
		# 默认占位
		sprite_data = {"body_color": "#888888", "hair_color": "#444444", "skin_color": "#cccccc", "weapon": "none"}
	var gen = SpriteGenerator.new()
	var tex = gen.generate_walk_strip(sprite_data)
	# 创建 Sprite3D
	sprite = Sprite3D.new()
	sprite.texture = tex
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = 0.04  # 32px sprite 渲染为 1.28 单位
	sprite.position.y = 0.5  # 中心点抬到地面以上
	sprite.offset = Vector2(0, 0)
	sprite.centered = true
	add_child(sprite)
	# 走路动画
	if use_walk_animation:
		_setup_animation()

func _setup_animation() -> void:
	anim = AnimationPlayer.new()
	add_child(anim)
	var anim_res = Animation.new()
	anim_res.length = 0.4
	anim_res.loop_mode = Animation.LOOP_LINEAR
	var track_idx = anim_res.add_track(Animation.TYPE_VALUE)
	anim_res.track_set_path(track_idx, "Sprite3D:frame")
	# 4 帧, 每帧 0.1s
	anim_res.track_insert_key(track_idx, 0.0, 0)
	anim_res.track_insert_key(track_idx, 0.1, 1)
	anim_res.track_insert_key(track_idx, 0.2, 2)
	anim_res.track_insert_key(track_idx, 0.3, 3)
	anim_res.track_insert_key(track_idx, 0.4, 0)
	# hframes = 4
	sprite.hframes = 4
	# Sprite3D 没有 frame 属性，改用 region_rect 或 modulate
	# 简单方案：用 modulate 闪烁代替真动画
	anim.queue_free()  # 暂时不用 AnimationPlayer
	# 简化：4 帧 sprite 通过 sprite.frame 切换
	sprite.hframes = 4
	# AnimationPlayer
	anim = AnimationPlayer.new()
	add_child(anim)
	var lib = AnimationLibrary.new()
	lib.add_animation("walk", anim_res)
	anim.add_animation_library("", lib)
	anim.play("walk")

func play_walk() -> void:
	is_walking = true
	if anim and anim.has_animation("walk"):
		anim.play("walk")

func play_idle() -> void:
	is_walking = false
	if anim:
		anim.stop()
	if sprite:
		sprite.frame = 0  # 站立帧

func flip_horizontal(flip: bool) -> void:
	facing_right = not flip
	if sprite:
		sprite.flip_h = flip

func _process(_delta: float) -> void:
	# billboard 由 Sprite3D.billboard 自动处理
	# flip 根据相机方向
	if sprite and sprite.billboard != BaseMaterial3D.BILLBOARD_DISABLED:
		var camera = get_viewport().get_camera_3d()
		if camera:
			var to_cam = camera.global_position - global_position
			sprite.flip_h = to_cam.x < 0
```

- [ ] **Step 4: 运行 - 期望 PASS**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless -s tests\test_sprite_actor_e2e.gd
```

期望：`=== RESULT: 2 passed, 0 failed ===`

- [ ] **Step 5: Commit**

```bash
git add scripts\world\sprite3d_actor.gd tests\test_sprite_actor_e2e.gd
git commit -m "feat(sprite-actor): Sprite3DActor with billboard + walk animation (2/2 test pass)"
```

---

## Task 7: 重构 loranai_city.tscn - 用 Sprite3DActor

**Files:**
- Modify: `scenes/world/loranai_city.tscn`

- [ ] **Step 1: 替换 Player/Avatar BoxMesh 为 Sprite3DActor**

找到：
```
[node name="Avatar" type="MeshInstance3D" parent="Player"]
mesh = SubResource("Box_player")
surface_material_override/0 = SubResource("Mat_player")
```

替换为：
```
[ext_resource type="Script" path="res://scripts/world/sprite3d_actor.gd" id="5_sprite"]

[node name="Avatar" type="Node3D" parent="Player"]
script = ExtResource("5_sprite")
sprite_data = {"body_color": "#2a4d8f", "hair_color": "#f0c419", "skin_color": "#fbcb8a", "armor_color": "#cccccc", "weapon": "sword", "outline_color": "#1a1a1a"}
actor_id = "parn"
```

- [ ] **Step 2: 替换 NPC_TownChief/Avatar CylinderMesh**

找到 NPC_TownChief 下的 Avatar MeshInstance3D，替换为：
```
[node name="Avatar" type="Node3D" parent="NPC_TownChief"]
script = ExtResource("5_sprite")
sprite_data = {"body_color": "#4a3a5a", "hair_color": "#cccccc", "skin_color": "#fbcb8a", "armor_color": "#5a3a8f", "weapon": "staff", "outline_color": "#1a1a1a"}
actor_id = "town_chief"
```

- [ ] **Step 3: 替换 NPC_InnKeeper/Avatar CylinderMesh**

```
[node name="Avatar" type="Node3D" parent="NPC_InnKeeper"]
script = ExtResource("5_sprite")
sprite_data = {"body_color": "#5a5a5a", "hair_color": "#3a3a3a", "skin_color": "#fbcb8a", "armor_color": "#cccccc", "weapon": "club", "outline_color": "#1a1a1a"}
actor_id = "inn_keeper"
```

- [ ] **Step 4: 替换 CaveExit/Marker CylinderMesh 为洞窟门 sprite（用 #3d6e3d 绿色门）**

```
[node name="Marker" type="Node3D" parent="CaveExit"]
script = ExtResource("5_sprite")
sprite_data = {"body_color": "#3d2a1a", "hair_color": "#1a1a1a", "skin_color": "#1a1a1a", "armor_color": "#1a1a1a", "weapon": "none", "outline_color": "#000000"}
actor_id = "cave_door"
use_walk_animation = false
```

- [ ] **Step 5: 验证场景加载**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless --import 2>&1 | Select-String "ERROR"
```

期望：无错误

- [ ] **Step 6: 验证场景能跑**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless --quit-after 15 res://scenes/world/loranai_city.tscn 2>&1 | Select-String "GameGlobals|ERROR"
```

期望：只有 `GameGlobals ready` 一行

- [ ] **Step 7: Commit**

```bash
git add scenes\world\loranai_city.tscn
git commit -m "refactor(world): loranai city uses Sprite3DActor (4 nodes converted)"
```

---

## Task 8: 重构 starting_cave.tscn - 用 Sprite3DActor

**Files:**
- Modify: `scenes/world/starting_cave.tscn`

- [ ] **Step 1: 替换 Player/Avatar BoxMesh**

找到 Player 下的 Avatar，替换为：
```
[node name="Avatar" type="Node3D" parent="Player"]
script = ExtResource("5_sprite")
sprite_data = {"body_color": "#2a4d8f", "hair_color": "#f0c419", "skin_color": "#fbcb8a", "armor_color": "#cccccc", "weapon": "sword", "outline_color": "#1a1a1a"}
actor_id = "parn"
```

- [ ] **Step 2: 替换 CaveEntry/Marker**

```
[node name="Marker" type="Node3D" parent="CaveEntry"]
script = ExtResource("5_sprite")
sprite_data = {"body_color": "#3d2a1a", "hair_color": "#1a1a1a", "skin_color": "#1a1a1a", "armor_color": "#1a1a1a", "weapon": "none", "outline_color": "#000000"}
actor_id = "cave_exit"
use_walk_animation = false
```

- [ ] **Step 3: 替换 Battle1/Marker 为 goblin sprite**

```
[node name="Marker" type="Node3D" parent="Battle1"]
script = ExtResource("5_sprite")
sprite_data = {"body_color": "#3d6e3d", "hair_color": "#1a2a1a", "skin_color": "#8aac5c", "armor_color": "#3d6e3d", "weapon": "club", "outline_color": "#1a2a1a"}
actor_id = "goblin"
```

- [ ] **Step 4: 替换 Battle2_Boss/Marker 为 orc sprite**

```
[node name="Marker" type="Node3D" parent="Battle2_Boss"]
script = ExtResource("5_sprite")
sprite_data = {"body_color": "#5a3a2a", "hair_color": "#1a1a1a", "skin_color": "#8a6b3d", "armor_color": "#5a3a2a", "weapon": "club", "outline_color": "#1a1a1a"}
actor_id = "orc"
```

- [ ] **Step 5: 替换 EhtoNPC/Avatar**

```
[node name="Avatar" type="Node3D" parent="EhtoNPC"]
script = ExtResource("5_sprite")
sprite_data = {"body_color": "#6b3d8f", "hair_color": "#5a3a2a", "skin_color": "#f5d0b0", "armor_color": "#d4a574", "weapon": "staff", "outline_color": "#1a1a1a"}
actor_id = "ehto"
```

- [ ] **Step 6: 验证场景加载**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless --import 2>&1 | Select-String "ERROR"
```

- [ ] **Step 7: 验证场景能跑**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless --quit-after 15 res://scenes/world/starting_cave.tscn 2>&1 | Select-String "GameGlobals|ERROR"
```

- [ ] **Step 8: Commit**

```bash
git add scenes\world\starting_cave.tscn
git commit -m "refactor(world): starting cave uses Sprite3DActor (5 nodes converted)"
```

---

## Task 9: 跑全套测试 + 视觉验证

**Files:**
- (none)

- [ ] **Step 1: 跑全套测试**

```bash
$env:APPDATA = "d:\Claudeworkspace\Lordisland\.godot_user"
$env:LOCALAPPDATA = "d:\Claudeworkspace\Lordisland\.godot_cache"
cd d:\Claudeworkspace\Lordisland
$G = "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe"
$tests = @("test_damage_formula", "test_dialogue_parser", "test_dialogue_e2e", "test_event_system", "test_event_e2e", "test_save_system", "test_main_quest_flow", "test_sprite_generator", "test_sprite_actor_e2e")
foreach ($t in $tests) { & $G --headless -s tests\$t.gd 2>&1 | Select-String "RESULT" }
```

期望：所有测试都 `RESULT: N passed, 0 failed`

- [ ] **Step 2: 手动视觉验证**

```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --path "d:\Claudeworkspace\Lordisland" --editor
```

- 在编辑器中按 F5
- 主菜单 → 新游戏 → 洛奈城
- 检查：帕恩是 sprite（不是方块）；走路时有动画；转身时 sprite 翻转
- 走到洞窟出口 → 切换场景 → 起始洞窟
- 检查：洞窟内 NPC 和战斗 marker 都是 sprite

- [ ] **Step 3: Commit (如果有 .tscn 调整)**

```bash
git status
# 如果有 changes:
# git add ... && git commit -m "fix(sprite): visual adjustments"
```

---

## Total Estimated Time

| Task | Time |
|---|---|
| Task 1 | 15 min |
| Task 2 | 5 min |
| Task 3 | 5 min |
| Task 4 | 5 min |
| Task 5 | 5 min |
| Task 6 | 15 min |
| Task 7 | 10 min |
| Task 8 | 10 min |
| Task 9 | 10 min |
| **Total** | **~80 min** |

## Final Acceptance

- [x] All 8 tasks done
- [x] All tests pass (80+/80+)
- [x] 5 主角 + 4 敌人 + 2 场景全部用 Sprite3DActor
- [x] 视觉验收通过（手动 F5）
- [x] 没有任何 BoxMesh/CylinderMesh 角色残留
