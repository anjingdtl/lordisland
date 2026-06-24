# M2：HD-2D 美术升级 — 程序化 sprite 替换 BoxMesh 占位

| 项目 | 内容 |
|---|---|
| **文档名** | M2 美术升级设计 |
| **创建日期** | 2026-06-24 |
| **状态** | 已批准（待实施） |
| **关联代码** | `d:\Claudeworkspace\Lordisland\` |
| **前置里程碑** | M1（已完成，70/70 测试通过） |

---

## 1. 目标

把 M1 阶段的 BoxMesh / CylinderMesh 占位角色/敌人，替换为**程序化生成的像素 sprite** + Sprite3D 渲染，达到 HD-2D 视觉标准（2D sprite 嵌在 3D 透视场景中）。

**完成定义**：
- 5 主角 + 4 敌人各有一套 sprite 贴图
- 走路动画 4 帧循环
- Sprite 自动朝向相机（billboard）
- 洛奈城 + 起始洞窟两个场景里的所有"角色节点"都是 sprite
- 单元测试 + 集成测试通过

## 2. 架构

### 2.1 `SpriteGenerator` 单例

**位置**：`scripts/core/sprite_generator.gd`

**职责**：根据角色数据生成像素 sprite Image（PNG 格式，可缓存）。

**公开 API**：
```gdscript
class_name SpriteGenerator
extends RefCounted

# 生成单个静态 sprite（32x48）
func generate_static(sprite_data: Dictionary) -> ImageTexture

# 生成 4 帧走路动画 strip（128x48，4 帧并列）
func generate_walk_strip(sprite_data: Dictionary) -> ImageTexture

# 生成 4x4 帧 sprite sheet（128x192）
func generate_sprite_sheet(sprite_data: Dictionary) -> ImageTexture

# 缓存管理
func clear_cache() -> void
```

**生成算法**：
- 32×48 像素画布，4 帧水平排列 = 128×48 strip
- 布局（自顶向下）：
  - 头发/头部装饰：y ∈ [0, 10)，10 px
  - 脸部：y ∈ [10, 18)，8 px
  - 上身/胸甲：y ∈ [18, 30)，12 px
  - 手部 + 武器：y ∈ [30, 38)，8 px
  - 腿部：y ∈ [38, 48)，10 px
- 4 帧走路动画：
  - 帧 0（站立）：腿并拢
  - 帧 1（左脚迈）：左腿前、右腿后
  - 帧 2（站立）：腿并拢
  - 帧 3（右脚迈）：右腿前、左腿后
- 调色板：4-6 色索引（每角色固定）：
  - 背景透明
  - 头发色
  - 肤色
  - 主身色
  - 副身色 / 装备色
  - 武器色
  - 阴影色（主身色 50% 暗）

### 2.2 角色 sprite 数据扩展

**位置**：`data/characters/*.json`，`data/enemies.json`

**新增字段**：
```json
{
  "id": "parn",
  ...
  "sprite": {
    "type": "humanoid",
    "body_color": "#2a4d8f",
    "hair_color": "#f0c419",
    "skin_color": "#fbcb8a",
    "armor_color": "#cccccc",
    "weapon": "sword",
    "outline_color": "#1a1a1a"
  }
}
```

**敌人 sprite**（16×24 小图，2 帧）：
```json
{
  "id": "goblin",
  ...
  "sprite": {
    "type": "goblin",
    "body_color": "#3d6e3d",
    "skin_color": "#8aac5c",
    "weapon": "club",
    "outline_color": "#1a2a1a"
  }
}
```

**5 主角 sprite 调色板**：
| 角色 | body | hair | skin | armor | weapon |
|---|---|---|---|---|---|
| Parn (帕恩) | #2a4d8f 蓝 | #f0c419 金 | #fbcb8a | #cccccc 银 | sword |
| Ehto (艾特) | #6b3d8f 紫 | #5a3a2a 棕 | #f5d0b0 | #d4a574 棕 | staff |
| Slayn (斯雷因) | #8f3d3d 红 | #1a1a1a 黑 | #fbcb8a | #4a4a4a 黑 | dagger |
| Tike (蒂特) | #3d8f5a 绿 | #f0c419 金 | #fbcb8a | #6b6b6b 灰 | bow |
| Ghim (吉姆) | #8f6b3d 棕 | #1a1a1a 黑 | #c99060 | #5a3a2a 皮 | axe |

**4 敌人 sprite 调色板**：
| 敌人 | body | skin | weapon |
|---|---|---|---|
| Goblin | #3d6e3d | #8aac5c | club |
| Orc | #5a3a2a | #8a6b3d | club |
| Goblin Archer | #3d6e3d | #8aac5c | bow |
| Kobold | #8f6b3d | #c99060 | spear |

### 2.3 `Sprite3DActor` 节点

**位置**：`scripts/world/sprite3d_actor.gd`

**职责**：在 3D 场景中显示 sprite，自动朝向相机，播放走路动画。

**继承**：`Node3D`

**结构**：
```
Sprite3DActor (Node3D)
├── Sprite3D (billboard, 不接受阴影)
│   └── texture: ImageTexture
├── AnimationPlayer (walk cycle)
└── ShadowDecal (可选，圆形阴影)
```

**公开 API**：
```gdscript
class_name Sprite3DActor
extends Node3D

@export var sprite_data: Dictionary
@export var actor_id: String
@export var use_walk_animation: bool = true
@export var scale: float = 1.0

var sprite: Sprite3D
var anim: AnimationPlayer
var facing_right: bool = true
var is_walking: bool = false

func set_sprite_data(data: Dictionary) -> void
func play_walk() -> void
func play_idle() -> void
func flip_horizontal(flip: bool) -> void
```

**朝向逻辑**：
- 检测相机位置 vs 自己位置
- `x = camera.global_position.x - global_position.x`
- 如果 x < 0 则 facing_left，flip Sprite3D
- 不做 Z 轴旋转（保持 2D 平面感）

**动画**：
- 4 帧 walk：0.4s 循环（每帧 0.1s）
- 2 状态：idle / walking
- AnimationPlayer 自动播放

### 2.4 场景重构

**loranai_city.tscn** 改动：
- `Player/Avatar` (BoxMesh) → `Player/Sprite3DActor`（持 parn 数据）
- `NPC_TownChief/Avatar` (CylinderMesh) → `Sprite3DActor`
- `NPC_InnKeeper/Avatar` (CylinderMesh) → `Sprite3DActor`
- `CaveExit/Marker` (CylinderMesh) → `Sprite3DActor`（显示洞窟图标）

**starting_cave.tscn** 改动：
- `Player/Avatar` (BoxMesh) → `Sprite3DActor`（parn）
- `CaveEntry/Marker` (CylinderMesh) → `Sprite3DActor`（出口图标）
- `Battle1/Marker` (CylinderMesh) → `Sprite3DActor`（goblin sprite）
- `Battle2_Boss/Marker` (CylinderMesh) → `Sprite3DActor`（orc sprite）
- `EhtoNPC/Avatar` (CylinderMesh) → `Sprite3DActor`（ehto sprite）

### 2.5 相机与光照微调

- DirectionalLight3D 阴影增强：阴影偏移、柔和度
- 场景清屏色：偏暖（#1a1a1f → #18182a）
- Camera3D 不变（HD-2D 透视已 OK）

## 3. 数据流

```
data/characters/parn.json
    ↓ 加载
SpriteGenerator.generate_walk_strip(sprite_data)
    ↓ 像素绘制
ImageTexture (128x48)
    ↓ 传给
Sprite3DActor.set_sprite_data()
    ↓ 内部
Sprite3D.texture + AnimationPlayer.frames
    ↓ 每帧更新
相机方向检测 → flip + 播放动画
```

## 4. 错误处理

- **JSON 缺 sprite 字段**：fallback 用一个简单的灰色人形（4 帧站立）
- **颜色解析失败**：用 #cccccc 占位
- **Image 创建失败**：push_error + 返回 1×1 透明 texture
- **节点未找到**：push_warning 不崩溃

## 5. 测试

### 5.1 单元测试 `test_sprite_generator.gd`

```gdscript
test_generate_image_not_null()       # 生成结果非 null
test_generate_dimensions()           # 128x48
test_generate_has_visible_pixels()   # 不全空
test_generate_palette_used()         # 调色板 4-6 色都被使用
test_walk_4_frames_distinct()        # 4 帧不完全相同
test_static_single_frame()           # generate_static 1 帧
test_clear_cache()                   # 清理后再次生成正常
test_invalid_data_fallback()         # 异常输入返回 fallback
```

### 5.2 集成测试 `test_sprite_actor_e2e.gd`

```gdscript
test_actor_loads_sprite()            # Sprite3D.texture 不为 null
test_actor_flips_on_camera()         # 相机位置变化触发 flip
test_actor_anim_idle_then_walk()     # 状态切换
```

### 5.3 视觉验证（手动）

F5 运行：
- 帕恩 sprite 比 BoxMesh 明显更"HD-2D"
- 走路动画流畅（4 帧）
- 转身时 sprite 水平翻转
- 阴影/光照合理

## 6. 工作量

| 模块 | 估计行数 |
|---|---|
| `sprite_generator.gd` | 280 |
| `sprite3d_actor.gd` | 150 |
| `data/characters/*.json` (5 个) | +50 |
| `data/enemies.json` (4 个) | +40 |
| `loranai_city.tscn` 改动 | +30 |
| `starting_cave.tscn` 改动 | +30 |
| `test_sprite_generator.gd` | 120 |
| `test_sprite_actor_e2e.gd` | 60 |
| 文档 + commit | 20 |
| **合计** | **~780 行** |

## 7. 风险

| 风险 | 缓解 |
|---|---|
| 程序化 sprite 视觉质量差 | 调色板精心选色；保留 BoxMesh 作 fallback |
| 动画卡顿 | 用 AnimationPlayer + 固定时间步 |
| 性能（5+ sprite + 阴影） | Sprite3D 共享 material；阴影只 1 个方向光 |
| 加载慢（生成 sprite 阻塞） | 启动时预生成 + 缓存到内存 |

## 8. 验收 checklist

- [ ] `test_sprite_generator.gd` 8+ tests pass
- [ ] `test_sprite_actor_e2e.gd` 3+ tests pass
- [ ] 5 主角 + 4 敌人 sprite 都能在场景中看到
- [ ] 走路动画 4 帧可见
- [ ] 转身时 sprite 水平翻转
- [ ] 没有任何 BoxMesh/CylinderMesh 角色残留
- [ ] 整体测试 80+/80+ pass（70 现有 + 10+ 新增）
- [ ] 视觉验收（手动 F5）通过
