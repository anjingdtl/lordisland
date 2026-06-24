extends Node

## 全局游戏状态
## EventSystem、PartyManager、SaveManager 都在这里

var event_system: EventSystem
var party_manager: PartyManager
var save_system: SaveSystem
var scene_manager: SceneManager
var audio_manager: AudioManager
var inventory: Inventory
var quest_log: QuestLog

func _ready() -> void:
	event_system = EventSystem.new()
	party_manager = PartyManager.new(event_system)
	save_system = SaveSystem.new()
	scene_manager = SceneManager.new()
	audio_manager = AudioManager.new()
	inventory = Inventory.new()
	quest_log = QuestLog.new(event_system)
	print("GameGlobals ready: event_system=%s party_manager=%s audio_manager=%s inventory=%s quest_log=%s" % [
		event_system, party_manager, audio_manager, inventory, quest_log
	])
