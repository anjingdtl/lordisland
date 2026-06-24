# M3: Steam 试玩级美术升级

| 项目 | 内容 |
|---|---|
| **文档名** | Steam 试玩级美术升级设计 |
| **创建日期** | 2026-06-24 |
| **状态** | 已批准 |
| **关联代码** | `d:\Claudeworkspace\Lordisland\` |
| **前置里程碑** | M1 (70 tests) + M2 (159 tests) |

---

## 1. 目标

把 M2 阶段的"程序化 32x48 sprite + 单光源 + 平面色"提升到 **Steam 试玩版质量**：
- 5 主角 + 5 敌人全部 96x96 真 HD-2D sprite（AI 生图）
- 全屏后期处理管线（Bloom + 暗角 + 色调映射 + SSAO + 雾）
- 多光源照明 + 真实阴影
- 完整战斗 UI（HP 条 + 技能图标 + 行动菜单 + 伤害飘字 + 相机震屏）
- 完整对话 UI（角色立绘 + 打字机动画 + 选项高亮）
- 主菜单重做（logo + 动画 + BGM 渐入）
- TileMap 地面（tiled 64x64 集）
- 启动画面 + Steam 资产

**完成定义**：
- 0 BoxMesh/CylinderMesh 占位残留
- 所有 sprite ≥ 96x96（AI 生成）
- 后期处理管线启用且视觉明显
- 战斗 UI 完整可视
- 主菜单有 logo
- 180+ 测试通过

## 2. 架构

### 2.1 AI 生图系统

**位置**：`scripts/core/ai_image_generator.gd`

**API**：`https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt={prompt}&image_size={size}`

**职责**：调用 AI 生图 API，下载 PNG 到 `assets/sprites/`，返回本地路径。

**公开 API**：
```gdscript
class_name AIImageGenerator
extends RefCounted

const API_BASE := "https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image"
const ASSETS_DIR := "res://assets/sprites/"

func generate_and_save(prompt: String, save_name: String, size: String = "square_hd") -> String
## Returns local res:// path of saved PNG, or empty on failure

func generate_batch(specs: Array) -> Array[String]
## specs: [{prompt, name, size}, ...]
## Returns array of paths
```

**SDXL prompt 模板**：
- 主角：`pixel art, 16-bit JRPG, anime style, full body character, [character desc], standing, transparent background, sprite sheet, 4 walk frames horizontal`
- 敌人：`pixel art, 16-bit JRPG, fantasy monster, [enemy desc], full body, transparent background, sprite sheet`
- Tile：`pixel art, top-down RPG tile, 64x64, [tile type], seamless, RPG Maker style`

**Fallback**：
- HTTP 失败 → 调高分辨率版程序化 sprite（96x96 升级版）
- 不阻塞主流程

### 2.2 AssetLoader

**位置**：`scripts/core/asset_loader.gd`

**职责**：从 `assets/` 加载 PNG，返回 ImageTexture。如不存在则用 fallback。

**公开 API**：
```gdscript
class_name AssetLoader
extends RefCounted

const CACHE := {}

static func get_texture(asset_path: String) -> ImageTexture
## Loads from res:// path, caches result
## If file missing, returns fallback texture

static func has_asset(asset_path: String) -> bool

static func sprite_data_to_path(actor_id: String) -> String
## "parn" -> "res://assets/sprites/parn.png"
```

**Sprite3DActor 改造**：
```gdscript
# 优先加载 assets/parn.png，失败则用程序化
var tex = AssetLoader.get_texture("res://assets/sprites/parn.png")
if tex == null:
    tex = SpriteGenerator.generate_walk_strip(sprite_data)
sprite.texture = tex
```

### 2.3 后期处理管线

**位置**：`scripts/world/world_environment.gd`

**职责**：自动配置 WorldEnvironment 节点 + Environment 资源。

**子节点**：
- DirectionalLight3D（太阳光，启用阴影）
- WorldEnvironment（环境配置）

**Environment 资源参数**：
```gdscript
env.background_mode = Environment.BG_SKY  # 天空盒
env.ambient_light_color = Color(0.4, 0.5, 0.7)
env.ambient_light_energy = 0.4
env.tonemap_mode = Environment.TONE_MAPPER_ACES
env.glow_enabled = true
env.glow_intensity = 0.4
env.glow_bloom = 0.2
env.ssao_enabled = true
env.ssao_radius = 0.5
env.ssao_intensity = 1.0
env.fog_enabled = true
env.fog_light_color = Color(0.7, 0.8, 1.0)
env.fog_density = 0.01
```

### 2.4 多光源系统

**位置**：`scripts/world/lighting.gd`

**职责**：根据场景类型（town/forest/cave）配置多光源。

**配置**：
| 场景 | 主光 | 副光 | 色温 |
|---|---|---|---|
| town | DirectionalLight 1.0 | OmniLight1 0.3 (村庄暖黄) | 暖白 |
| forest | DirectionalLight 0.7 | OmniLight1 0.2 (绿色调) | 冷绿 |
| cave | DirectionalLight 0.4 | OmniLight2 0.5 (蓝色调) | 冷蓝 |

**API**：
```gdscript
class_name Lighting
extends Node3D

@export var scene_type: String = "town"  # town/forest/cave

func _ready() -> void:
    _setup_lights()

func _setup_lights() -> void
```

### 2.5 TileMap 地面

**位置**：`scripts/world/tilemap_ground.gd` + TileSet 资源

**职责**：用 TileMap 替代 PlaneMesh 地面。

**TileSet**：
- `res://assets/tilesets/grass.tres`
- `res://assets/tilesets/cave.tres`
- `res://assets/tilesets/stone.tres`

**API**：
```gdscript
class_name TileMapGround
extends TileMap

@export var tileset_path: String
@export var width: int = 30
@export var height: int = 30

func _ready() -> void:
    _build_ground()
```

**注**：M3 阶段用程序化 tiles（不依赖 AI），M3.1 用 AI 生成真实 tile。

### 2.6 战斗 UI 完整版

**位置**：`scripts/ui/battle_ui.gd`（重写）

**职责**：完整战斗 UI，节点化、动画化。

**结构**：
```
BattleUI (Control, full screen)
├── Background (ColorRect 半透明)
├── TopBar (5 角色 HP/MP 条)
│   └── PartyMemberSlot (5 个)
│       ├── Portrait (TextureRect)
│       ├── Name (Label)
│       ├── HP_Bar (ProgressBar)
│       └── MP_Bar (ProgressBar)
├── BottomBar (5 敌人 HP 条)
├── ActionMenu (4 选项: 攻击/技能/物品/防御)
├── SkillMenu (动态)
├── FloatingText (动态)
└── LogPanel (左下角)
```

**API**：
```gdscript
class_name BattleUI
extends Control

signal action_chosen(action: String, target: int)

func set_party(actors: Array) -> void
func set_enemies(actors: Array) -> void
func update_hp(actor_idx: int, hp: int, max_hp: int) -> void
func show_damage(target_idx: int, amount: int, is_crit: bool) -> void
func show_message(text: String) -> void
func show_menu(menu_type: String) -> void
```

### 2.7 相机震屏

**位置**：`scripts/core/camera_shake.gd`

**职责**：战斗受击时震屏。

**API**：
```gdscript
class_name CameraShake
extends Node

@export var trauma: float = 0.0
@export var max_offset: Vector3 = Vector3(0.3, 0.3, 0)
@export var decay: float = 1.5  # 每秒衰减

func add_trauma(amount: float) -> void
## 0.0-1.0 范围

func _process(delta: float) -> void
```

### 2.8 飘字系统

**位置**：`scripts/ui/floating_text.gd`

**职责**：战斗伤害/治疗数字飘字。

**API**：
```gdscript
class_name FloatingText
extends Node2D

@export var text: String
@export var color: Color = Color.RED
@export var is_crit: bool = false
@export var lifetime: float = 1.5

func show_at(position: Vector2) -> void
```

### 2.9 对话 UI 升级

**位置**：`scripts/ui/dialogue_ui.gd`（重写）

**结构**：
```
DialogueUI (Control, full screen bottom-half)
├── Portrait (TextureRect, 左边)
├── NameLabel (Label)
├── Body (Panel + RichTextLabel, 打字机动画)
├── Choices (VBoxContainer, 动态)
└── Continue (右下角 "▼" 提示)
```

**打字机动画**：
- 0.05s/字符
- 文字渐入 + 闪烁光标
- 选项在文字完成后显示

### 2.10 主菜单重做

**位置**：`scripts/ui/main_menu.gd`（重写）+ 新 logo

**结构**：
```
MainMenu (Control, full screen)
├── Background (TextureRect 全屏，渐变 + 远景)
├── Logo (TextureRect 居中，AI 生成的"罗德岛战记" logo)
├── Buttons (VBoxContainer)
│   ├── NewGame (Button)
│   ├── Continue (Button)
│   ├── Load (Button)
│   └── Quit (Button)
└── Footer (版本号 + 版权)
```

### 2.11 Steam 资产

**位置**：`assets/steam/`

**文件**：
- `capsule_main.png` (460x215) - 主 capsule
- `capsule_vertical.png` (600x900) - 竖 capsule
- `library_hero.png` (3840x1240) - 库主页
- `header.png` (460x215) - 库 header
- `icon.png` (256x256) - 游戏 icon
- `logo.png` (1280x720) - logo

**生成**：AI 生图（同样 API）

## 3. 数据流

```
[AI API] -> PNG bytes -> res://assets/sprites/{id}.png
                                     ↓
[AssetLoader] -> ImageTexture (cached)
                                     ↓
[Sprite3DActor.set_sprite_data()]
                                     ↓
[Sprite3D.texture]
                                     ↓
[Camera3D] (with CameraShake) -> [Camera3D screenshake]
```

## 4. 错误处理

- **AI API 失败**：重试 1 次，仍失败则 fallback 到增强版程序化 sprite
- **Asset 文件缺失**：SpriteGenerator fallback
- **TileSet 缺失**：用单 PlaneMesh + 颜色（已有）
- **Environment 缺失**：用 Godot 默认 + 自定义后期

## 5. 测试

### 5.1 AI 生图测试 `test_ai_image_generator.gd`
```gdscript
test_api_url_format()           # URL 格式正确
test_prompt_template()          # prompt 模板正确
test_fallback_when_no_internet() # 没网时返回空字符串
test_batch_generation_skip_existing() # 跳过已存在的
```

### 5.2 AssetLoader 测试 `test_asset_loader.gd`
```gdscript
test_load_existing_texture()    # 加载存在的
test_load_missing_returns_fallback()  # 不存在返回 fallback
test_sprite_data_to_path()      # actor_id -> path
test_cache_avoids_reload()      # 缓存不重复 IO
```

### 5.3 战斗 UI 测试 `test_battle_ui.gd`
```gdscript
test_battle_ui_creates_party_slots()
test_battle_ui_creates_enemy_slots()
test_battle_ui_updates_hp_bar()
test_battle_ui_shows_damage_text()
test_battle_ui_action_signal()
```

### 5.4 相机震屏测试 `test_camera_shake.gd`
```gdscript
test_shake_adds_trauma()
test_shake_decays_over_time()
test_shake_max_offset_enforced()
test_shake_stops_at_zero()
```

### 5.5 视觉集成测试 `test_visual_integration.gd`
```gdscript
test_world_environment_exists()
test_all_scenes_have_lighting()
test_no_boxmesh_characters_remain()
test_sprites_min_96x96()  # 验证 sprite 尺寸
```

## 6. 文件结构

```
Lordisland/
├── assets/
│   ├── sprites/                  # AI 生成的 sprite PNG
│   ├── tilesets/                 # 程序化 + 后期 AI tile
│   ├── ui/                       # UI 元素
│   ├── logo/                     # logo PNG
│   └── steam/                    # Steam 资产
├── scripts/
│   ├── core/
│   │   ├── ai_image_generator.gd  # NEW
│   │   ├── asset_loader.gd        # NEW
│   │   ├── camera_shake.gd        # NEW
│   ├── world/
│   │   ├── world_environment.gd   # NEW
│   │   ├── lighting.gd            # NEW
│   │   ├── tilemap_ground.gd      # NEW
│   │   ├── sprite3d_actor.gd      # MODIFIED: use AssetLoader
│   ├── ui/
│   │   ├── battle_ui.gd           # MODIFIED: 完整版
│   │   ├── dialogue_ui.gd         # MODIFIED: 打字机 + 立绘
│   │   ├── main_menu.gd           # MODIFIED: logo
│   │   ├── floating_text.gd       # NEW
└── tests/
    ├── test_ai_image_generator.gd
    ├── test_asset_loader.gd
    ├── test_battle_ui.gd
    ├── test_camera_shake.gd
    └── test_visual_integration.gd
```

## 7. 工作量

| 模块 | 行数 | 估计时间 |
|---|---|---|
| ai_image_generator.gd | 100 | 15 min |
| asset_loader.gd | 60 | 5 min |
| world_environment.gd | 50 | 5 min |
| lighting.gd | 80 | 10 min |
| tilemap_ground.gd | 60 | 10 min |
| sprite3d_actor.gd 升级 | 30 | 5 min |
| camera_shake.gd | 50 | 5 min |
| floating_text.gd | 80 | 10 min |
| battle_ui.gd 重写 | 350 | 30 min |
| dialogue_ui.gd 重写 | 200 | 20 min |
| main_menu.gd 重做 | 200 | 20 min |
| AI 生图 (~15 张) | - | 30 min |
| 5 测试文件 | 250 | 25 min |
| 集成 + 修 bug | 200 | 20 min |
| **合计** | **~1700** | **~3.5h** |

## 8. 风险

| 风险 | 缓解 |
|---|---|
| AI API 慢/超时 | 同步调用 + 5s timeout + fallback |
| API 返回错误图 | 验证文件大小 (>1KB) + 透明度检查 |
| 资产不匹配 sprite 字段 | 同 prompt 模板保证风格统一 |
| 后期处理性能 | 默认低质量档 + 设置可调 |
| TileMap 复杂 | M3 用程序化 tile 简化 |

## 9. 验收 checklist

- [x] AI 生图 API 工作
- [x] 5 主角 + 5 敌人 sprite ≥ 96x96
- [x] AssetLoader fallback 正确
- [x] 后期处理管线启用
- [x] 多光源 + 阴影
- [x] 战斗 UI 完整可视
- [x] 相机震屏工作
- [x] 飘字系统工作
- [x] 对话 UI 打字机动画
- [x] 主菜单 logo
- [x] 0 BoxMesh 角色残留
- [x] 180+ 测试通过
