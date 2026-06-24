# Lordisland: Record of Lodoss War 2D RPG

A 2D HD-2D RPG game built in Godot 4.3, based on the classic Record of Lodoss War OVA.

> **Status: M2 序章完整 (159/159 tests passing)**

## Quick Start

```bash
# Open project in Godot Editor and press F5
godot --path /path/to/Lordisland
```

Or run from CLI:
```bash
& "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe" --headless --path "d:\Claudeworkspace\Lordisland"
```

## Gameplay

- **Main menu** → 新游戏 / 继续 / 读档 / 设置 / 退出
- **洛奈城** (Loranai) — Talk to 村长, accept quest
- **起始洞窟** (Cave) — 2 battles, rescue Ehto, she joins party
- **洛奈野外** (Wilderness) — 3 battles, meet Slayn & Tike, they join after you clear the battles, troll boss

## Features (M2 Complete)

- ✅ **5v3 turn-based combat** (帕恩 + 艾特 + 斯雷因 + 蒂特 + 吉姆 vs orc + 2 goblin)
- ✅ **9 skills** + 4 enemies + 5 party members
- ✅ **Procedural HD-2D sprites** — all characters (no BoxMesh placeholders)
- ✅ **4-frame walk animation** with billboard orientation
- ✅ **Programmatic BGM** — 5 different styles (town/forest/cave/battle/boss)
- ✅ **Inventory + Shop system** — 5 items, gold management
- ✅ **Quest log** — 3 side quests
- ✅ **JSON dialogue + event system** with i18n (zh/en)
- ✅ **Save/Load** — 10 slots, JSON serialization
- ✅ **3 maps** — 洛奈城 / 起始洞窟 / 洛奈野外
- ✅ **Main quest line** + side quests
- ✅ **159/159 tests passing**

## Project Structure

```
Lordisland/
├── project.godot
├── docs/superpowers/                  # Design docs & plans
│   ├── specs/
│   └── plans/
├── scenes/
│   ├── ui/main_menu.tscn
│   └── world/
│       ├── loranai_city.tscn
│       ├── starting_cave.tscn
│       └── loranai_wilderness.tscn
├── scripts/
│   ├── core/                          # Autoloads & global systems
│   │   ├── game_globals.gd
│   │   ├── inventory.gd               # 物品+金币
│   │   ├── quest_log.gd               # 任务
│   │   ├── audio_manager.gd           # 音频
│   │   ├── bgm_generator.gd           # 程序化 BGM
│   │   ├── sprite_generator.gd        # 程序化 sprite
│   │   ├── save_system.gd
│   │   └── ...
│   ├── systems/                       # 战斗/对话/事件
│   ├── world/                         # 地图/NPC/装饰
│   └── ui/                            # UI 控件
├── data/
│   ├── characters/                    # 5 chars JSON
│   ├── dialogues/                     # 6 段对话
│   ├── events/                        # 3 事件
│   ├── items.json                     # 5 物品
│   ├── quests.json                    # 3 任务
│   ├── enemies.json                   # 5 敌人
│   └── skills.json                    # 9 技能
├── locale/                            # zh.po + en.po
└── tests/                             # 13 个测试文件
```

## Testing

```bash
$env:APPDATA = "d:\Claudeworkspace\Lordisland\.godot_user"
$env:LOCALAPPDATA = "d:\Claudeworkspace\Lordisland\.godot_cache"
cd d:\Claudeworkspace\Lordisland
$G = "d:\Claudeworkspace\Lordisland\.tools\Godot_v4.3-stable_win64.exe"

# Run all tests
foreach ($t in Get-ChildItem tests/*.gd) {
    & $G --headless -s $t.FullName 2>&1 | Select-String "RESULT"
}
```

### Test Count
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
| **Total** | **170+** |

## Roadmap (M3+)

- [ ] Flaim 城 + 灼热沙漠
- [ ] 龙 Boss
- [ ] 实时昼夜系统
- [ ] Windows .exe 导出
- [ ] 完整第 1 章
- [ ] iOS / Android

## License

MIT (TBD)
