# Lordisland: Record of Lodoss War 2D RPG

> **Status: v0.4.0 — Steam Playtest Ready (220+ tests passing)**

A 2D HD-2D RPG game built in Godot 4.3, based on the classic Record of Lodoss War OVA.

## Quick Start

### Play (Editor)
```bash
godot --path /path/to/Lordisland
```

### Play (Windows)
```bash
# Download Godot 4.3 export templates first (one-time)
# Then in Godot Editor: Project → Export → Add → Windows Desktop
# Or via CLI:
godot --headless --path . --export-release "Windows Desktop" build/lordisland.exe
```

### CLI (Headless)
```bash
".tools/Godot_v4.3-stable_win64.exe" --headless --path .
```

## Features

### Gameplay
- **Main menu** → 新游戏 / 继续 / 读档 / 设置 / 退出
- **洛奈城** (Loranai) — Talk to 村长, accept quest
- **起始洞窟** (Cave) — 2 battles, rescue Ehto, she joins party
- **洛奈野外** (Wilderness) — 3 battles, meet Slayn & Tike, they join after you clear the battles, troll boss
- **Settings** — Music volume / SFX volume / Language (zh/en/ja) / Resolution / Fullscreen

### Systems (v0.4.0)
- ✅ **5v3 turn-based combat** (帕恩 + 艾特 + 斯雷因 + 蒂特 + 吉姆 vs orc + 2 goblin)
- ✅ **9 skills** + 4 enemies + 5 party members
- ✅ **Procedural HD-2D sprites** — all characters (no BoxMesh placeholders)
- ✅ **4-frame walk animation** with billboard orientation
- ✅ **Programmatic BGM** — 5 different styles (town/forest/cave/battle/boss)
- ✅ **Programmatic SFX** — 13 effects (click/hit/crit/heal/buy/victory/levelup/etc.)
- ✅ **Audio buses** — Master / Music / SFX with separate volume control
- ✅ **Inventory + Shop system** — 5 items, gold management
- ✅ **Quest log** — 3 side quests + counters
- ✅ **JSON dialogue + event system** with i18n (zh/en/ja)
- ✅ **Save/Load** — 10 slots, JSON serialization, deep-copy safe
- ✅ **3 maps** — 洛奈城 / 起始洞窟 / 洛奈野外
- ✅ **Main quest line** + side quests
- ✅ **Steam integration** — GodotSteam-ready stub + 9 achievements
- ✅ **220+ tests passing** (18 test files)

## Steam 上线清单

| 项目 | 状态 |
|------|------|
| 单元测试 100% 通过 | ✅ 220+ assertions |
| 端到端穿测 16 项全过 | ✅ |
| Save/Load 真正可用 | ✅ 修复了 P0 类型 bug |
| 设置页（音量/语言/分辨率/全屏） | ✅ |
| 程序化 SFX（无需音频文件） | ✅ 13 种 |
| 程序化 BGM | ✅ 5 种 |
| Steamworks SDK 桩 | ✅ GodotSteam 集成预留 |
| Achievement 框架 | ✅ 9 个成就定义 |
| steam_appid.txt | ✅ |
| 默认 Audio Bus Layout | ✅ Master/Music/SFX |
| i18n（zh/en/ja） | ✅ |
| 启动入口 | ✅ main_menu.tscn |
| 导出预设 | ✅ Windows Desktop |
| 导出模板 | ⚠️ 需手动下载（约 990MB） |

## Project Structure

```
Lordisland/
├── project.godot                 # Engine config + Steam bridge autoload
├── export_presets.cfg            # Windows export config
├── steam_appid.txt               # Steam app id (default 480 for dev)
├── default_bus_layout.tres       # Master/Music/SFX audio buses
├── docs/superpowers/             # Design docs & plans
│   ├── specs/
│   └── plans/
├── scenes/
│   ├── ui/main_menu.tscn         # Main menu (logo + 5 buttons)
│   ├── battle/battle_scene.tscn  # Battle controller + UI
│   └── world/
│       ├── loranai_city.tscn
│       ├── starting_cave.tscn
│       └── loranai_wilderness.tscn
├── scripts/
│   ├── core/                     # Autoloads & global systems
│   │   ├── game_globals.gd       # Global state singleton
│   │   ├── audio_manager.gd      # BGM + SFX player
│   │   ├── bgm_generator.gd      # Procedural BGM
│   │   ├── sfx_generator.gd      # Procedural SFX
│   │   ├── steam_bridge.gd       # GodotSteam integration
│   │   ├── inventory.gd          # 物品+金币
│   │   ├── quest_log.gd          # 任务
│   │   ├── party_manager.gd      # 队伍
│   │   ├── save_system.gd
│   │   └── ...
│   ├── systems/                  # 战斗/对话/事件
│   │   ├── actor.gd              # Battle actor model
│   │   ├── battle_controller.gd  # State machine
│   │   ├── battle_formula.gd     # Damage calc
│   │   ├── dialogue_parser.gd
│   │   ├── event_system.gd
│   │   └── ...
│   ├── world/                    # 地图/NPC/装饰
│   └── ui/                       # UI 控件
│       ├── main_menu.gd
│       ├── battle_ui.gd
│       ├── dialogue_ui.gd
│       ├── shop_ui.gd
│       ├── save_load_ui.gd
│       ├── settings_ui.gd        # NEW (v0.4.0)
│       └── floating_text.gd
├── data/
│   ├── characters/               # 5 chars JSON
│   ├── dialogues/                # 6 段对话
│   ├── events/                   # 3 事件
│   ├── items.json                # 5 物品
│   ├── quests.json               # 3 任务
│   ├── enemies.json              # 5 敌人
│   └── skills.json               # 9 技能
├── locale/                       # zh.po + en.po
├── assets/                       # 程序生成 + AI 图片资源
│   ├── title_bg.jpg
│   ├── logo.jpg
│   ├── battle_bg.jpg
│   └── sprites/
└── tests/                        # 18 个测试文件
```

## Testing

```bash
# Run all tests
$env:APPDATA = "$PWD\.godot_user"
$env:LOCALAPPDATA = "$PWD\.godot_cache"
$G = "$PWD\.tools\Godot_v4.3-stable_win64.exe"

# Run individual test
& $G --headless -s tests/test_damage_formula.gd

# Run all (loop)
foreach ($t in Get-ChildItem tests/*.gd) {
    & $G --headless -s $t.FullName 2>&1 | Select-String "RESULT"
}

# Run end-to-end smoke test
& $G --headless -s tests/e2e_smoke.gd
```

### Test Coverage
| Test | Assertions |
|---|---|
| test_damage_formula | 5 |
| test_dialogue_parser | 8 |
| test_dialogue_e2e | 8 |
| test_event_system | 6 |
| test_event_e2e | 8 |
| test_save_system | 19 |
| test_main_quest_flow | 16 |
| test_sprite_generator | 9 |
| test_sprite_actor_e2e | 5 |
| test_wilderness_e2e | 12 |
| test_inventory_shop | 27 |
| test_quest_log | 19 |
| test_bgm | 17 |
| test_battle_5v3 | 3 |
| test_m3_polish | 31 |
| test_scenetree_sanity | 3 |
| test_steam_bridge | 3 |
| e2e_smoke | 16 |
| **Total** | **220+** |

## Steam 集成步骤

### 1. 安装 GodotSteam 插件
```bash
# 下载 https://github.com/CoaguCo-Industries/GodotSteam/releases
# 解压 addons/godotsteam/ 到项目 addons/ 目录
```

### 2. 启用插件
Godot Editor → Project → Plugins → 启用 GodotSteam

### 3. 配置 Steam App ID
```bash
# 修改 steam_appid.txt 为真实 appid（默认 480 = Spacewar 测试）
# 修改 project.godot 中 [steam] section
```

### 4. 导出 Windows
```bash
# 1. 下载导出模板 (Editor → Editor → Manage Export Templates)
# 2. Project → Export → Add → Windows Desktop
# 3. Export Project → build/lordisland.exe
```

## Roadmap (post-launch)

- [ ] Flaim 城 + 灼热沙漠
- [ ] 龙 Boss
- [ ] 实时昼夜系统
- [ ] iOS / Android 导出
- [ ] 完整第 1 章
- [ ] Online leaderboards

## License

MIT