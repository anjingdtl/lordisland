# M2.1: 洛奈野外地图

| 项目 | 内容 |
|---|---|
| **文档名** | 洛奈野外地图设计 |
| **创建日期** | 2026-06-24 |
| **状态** | 已批准 |
| **前置** | M1 + M2 sprite 升级完成 |

---

## 1. 目标

在洛奈城外加一张新地图 `loranai_wilderness.tscn`，扩展游戏世界 30-50%。包含：
- 1 张新地图（森林）
- 3 场战斗（哥布林/巨魔/哥布林射手）
- 2 个 NPC（斯雷因/蒂特）—— *加入队伍的事件留到 M2.2*
- 1 个 chest（道具奖励）
- 1 个入口（从洛奈城来）+ 1 个出口（通往下一区域）

## 2. 地图布局

```
                    ┌───────────────────────┐
                    │                       │
        [Boss 巨魔]  │   [Chest]             │
                    │                       │
                    │       [斯雷因 NPC]     │
                    │                       │
        [战斗 B]    │   [哥布林射手 B]      │
                    │                       │
                    │       [蒂特 NPC]       │
                    │                       │
        [战斗 A]    │                       │
                    │                       │
        [出口: 洛奈] │   [入口: 洛奈城]      │  ← 双向
                    │                       │
                    └───────────────────────┘
```

坐标系（x: 南北, z: 东西）：
- 入口/出口：(0, 0, 15) — 南侧中部
- 战斗 A（哥布林）：(-12, 0, 5)
- 战斗 B（哥布林射手）：(-12, 0, -8)
- Boss 巨魔：(12, 0, -15)
- 哥布林射手 B（独立）：(8, 0, -3)
- Chest：(15, 0, 8)
- 斯雷因 NPC：(3, 0, -10)
- 蒂特 NPC：(2, 0, 3)

## 3. 视觉风格

- 地面：深绿（#3a5a3a）+ 棕色路径
- 光照：偏冷（#8090c0）冷调阳光
- 装饰：圆筒 mesh = 树干（深棕）+ 低多边形石头（灰）
- 8-12 棵树，4 块石头，3 株灌木

## 4. 战斗配置

| ID | 敌人 | 位置 | 触发表 |
|---|---|---|---|
| 战斗 A | 哥布林 × 2 | (-12, 0, 5) | "wilderness_battle_a_cleared" |
| 战斗 B | 哥布林射手 × 2 | (-12, 0, -8) | "wilderness_battle_b_cleared" |
| Boss 巨魔 | 巨魔 × 1 | (12, 0, -15) | "wilderness_boss_defeated" |

## 5. NPC 配置

| NPC | 位置 | 角色数据 | dialogue_id | event_id |
|---|---|---|---|---|
| 斯雷因 | (3, 0, -10) | slayn.json | npc_slayn_meet | - |
| 蒂特 | (2, 0, 3) | tike.json | npc_tike_meet | - |

**注**：本任务只放 NPC + 对话。**入队事件留 M2.2**。

## 6. Chest

- 位置：(15, 0, 8)
- 内容：1 治疗药水（heal_potion）
- 一次性：触发后 flag `chest_wilderness_1_opened = true`
- 视觉：紫色立方体（区分 NPC）

## 7. 入口/出口

- 洛奈城 → 野外：在洛奈城西侧加一个 WildernessExit 节点
- 野外 → 洛奈城：在野外南侧入口回到洛奈城

## 8. 数据文件

- `data/enemies.json` 加 `troll`（巨魔）：HP 120, STR 14, VIT 10, exp_reward 50
- `data/dialogues/npc_slayn_meet.json`（5-6 节点）
- `data/dialogues/npc_tike_meet.json`（5-6 节点）

## 9. 文件清单

| 文件 | 改动 |
|---|---|
| `data/enemies.json` | 加 troll 字段 |
| `data/dialogues/npc_slayn_meet.json` | 新增 |
| `data/dialogues/npc_tike_meet.json` | 新增 |
| `data/dialogues/translation_keys.txt` | 加新 key |
| `locale/zh.po` | 加翻译 |
| `locale/en.po` | 加翻译 |
| `scenes/world/loranai_wilderness.tscn` | 新增 |
| `scenes/world/loranai_city.tscn` | 加 WildernessExit 节点 |
| `scripts/world/chest.gd` | 新增 |
| `scripts/world/wilderness_exit.gd` | 新增 |
| `scripts/world/forest_decorator.gd` | 新增（程序化生成树/石头） |
| `tests/test_wilderness_e2e.gd` | E2E 测试 |

## 10. 验收

- [ ] 5 主角从洛奈城可走到野外入口
- [ ] 野外有 3 场战斗（哥布林×2、哥布林射手×2、巨魔×1）
- [ ] 2 个 NPC（斯雷因/蒂特）可对话
- [ ] 1 个 chest 拾取治疗药水
- [ ] 5+ 新测试通过
- [ ] 90+ 测试总数通过
- [ ] 视觉上明显是森林风格（深绿 + 树）

## 11. 工作量估计

| 项 | 行数 |
|---|---|
| chest.gd | 60 |
| wilderness_exit.gd | 30 |
| forest_decorator.gd | 80 |
| loranai_wilderness.tscn | 100 |
| 2 段对话 JSON | 60 |
| 翻译更新 | 40 |
| 测试 | 80 |
| 场景调整 + lore 装饰 | 50 |
| **合计** | **~500 行** |
