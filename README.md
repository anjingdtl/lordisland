# Lordisland: Record of Lodoss War 2D RPG

A 2D HD-2D RPG game built in Godot 4.3, based on the classic Record of Lodoss War OVA.

> **Status: M1 Vertical Slice Complete (73/73 tests passing)**

## Quick Start

```bash
# Linux/Mac/Windows: requires Godot 4.3 stable
# Download from https://godotengine.org/download

# 1. Open project in Godot Editor
godot --path /path/to/Lordisland

# 2. Press F5 to run the game (main menu)
# 3. Click "新游戏" (New Game) → 帕恩 (Parn) appears in 洛奈城 (Loranai)
# 4. Walk (WASD/方向键) to the 村长 (Town Chief) → press E
# 5. Walk to 洞窟出口 (Cave Exit) at the edge → press E
# 6. Defeat 哥布林 (goblin) and 兽人 (orc) boss to rescue 艾特 (Ehto)
# 7. 艾特 (Ehto) joins your party
```

## Features (M1)

- ✅ **5v3 turn-based combat** (帕恩 + 艾特 + 斯雷因 + 蒂特 + 吉姆 vs orc + 2 goblin)
- ✅ **9 skills** (attack, light_sword, smash, double_shot, fireball, ice_shard, heal, bless, fortify)
- ✅ **Status effects & buffs** (3-round duration)
- ✅ **Random critical hits & variance** (5% crit, ±10% variance)
- ✅ **JSON-based dialogue system** with branching choices
- ✅ **Event/trigger system** with conditions (flag-based gating)
- ✅ **Save/Load** — 10 slots, JSON serialization, **unrestricted timing** (per design doc §7)
- ✅ **i18n (中文/English)** — all UI text + dialogues + skill names
- ✅ **2 maps**: 洛奈城 (Loranai) + 起始洞窟 (Starting Cave) with 3 battles
- ✅ **Main quest line**: Parn → 洛奈城 → 洞窟 → 救艾特 → 艾特入队
- ✅ **Main menu** with continue/load/settings
- ✅ **Audio system** (stub; ready for asset integration)
- ✅ **73/73 tests passing** (5 damage formula + 8 dialogue parser + 8 dialogue e2e + 6 event system + 8 event e2e + 19 save system + 16 main quest flow + 3 5v3 battle)

## Project Structure

```
Lordisland/
├── project.godot              # Godot project config (1920x1080, Forward+)
├── docs/superpowers/          # Design docs & plans
│   ├── specs/2026-06-24-lordisland-2d-rpg-design.md
│   └── plans/2026-06-24-m1-vertical-slice.md
├── scenes/
│   ├── ui/main_menu.tscn      # 主菜单
│   ├── battle/battle_scene.tscn
│   └── world/
│       ├── loranai_city.tscn  # 洛奈城
│       └── starting_cave.tscn # 起始洞窟
├── scripts/
│   ├── core/                  # Autoloads & global systems
│   │   ├── game_globals.gd    # 全局游戏状态
│   │   ├── locale_manager.gd  # i18n
│   │   ├── party_manager.gd   # 队伍
│   │   ├── save_system.gd     # 存档
│   │   ├── scene_manager.gd   # 场景切换
│   │   └── audio_manager.gd   # 音频 (stub)
│   ├── systems/               # 核心系统
│   │   ├── battle_controller.gd  # 战斗状态机
│   │   ├── battle_formula.gd  # 伤害公式
│   │   ├── battle_driver.gd   # 战斗测试
│   │   ├── actor.gd           # 角色
│   │   ├── dialogue_parser.gd # 对话解析
│   │   ├── event_system.gd    # 事件系统
│   │   └── event_executor.gd  # 事件执行
│   ├── world/                 # 世界交互
│   │   ├── world_player.gd    # 玩家
│   │   ├── npc.gd             # NPC
│   │   ├── cave_exit.gd       # 洞窟出口
│   │   ├── cave_entry.gd      # 洞窟入口
│   │   └── battle_trigger.gd  # 战斗触发器
│   └── ui/                    # UI 控件
│       ├── main_menu.gd
│       ├── save_load_ui.gd
│       ├── dialogue_ui.gd
│       └── battle_ui.gd
├── data/                      # 游戏数据
│   ├── characters/{parn,ehto,slayn,tike,ghim}.json
│   ├── enemies.json           # 4 敌人
│   ├── skills.json            # 9 技能
│   ├── dialogues/             # 对话 JSON
│   └── events/                # 事件 JSON
├── locale/                    # 翻译
│   ├── zh.po
│   └── en.po
├── tests/                     # 自动化测试 (SceneTree scripts)
│   ├── test_damage_formula.gd
│   ├── test_dialogue_parser.gd
│   ├── test_dialogue_e2e.gd
│   ├── test_event_system.gd
│   ├── test_event_e2e.gd
│   ├── test_save_system.gd
│   ├── test_main_quest_flow.gd
│   └── test_battle_5v3.gd
└── .tools/                    # Godot 4.3 binary (gitignored)
```

## Running Tests

```bash
# Set Godot binary path
$env:APPDATA = "d:\Claudeworkspace\Lordisland\.godot_user"
$env:LOCALAPPDATA = "d:\Claudeworkspace\Lordisland\.godot_cache"

# Run individual test
godot --headless -s tests/test_damage_formula.gd
godot --headless -s tests/test_battle_5v3.gd
godot --headless -s tests/test_main_quest_flow.gd

# Check scene parsing
godot --headless --import
godot --headless --quit-after 30 res://scenes/world/loranai_city.tscn
```

## Roadmap (M2+)

- [ ] Replace BoxMesh placeholders with real 2D sprites / 3D models
- [ ] Add real BGM + SFX (assets needed)
- [ ] Add chest in cave (1 chest)
- [ ] Add shop system in 洛奈城
- [ ] Add more maps (Forest, 魔神像 dungeon, etc.)
- [ ] Add save/load thumbnails
- [ ] Add full first chapter (10+ battles, 20+ dialogues)
- [ ] iOS/Android export

## License

MIT (TBD)
