extends Node

## 全局游戏状态
## EventSystem、PartyManager、SaveManager 都在这里

var event_system: EventSystem
var party_manager: PartyManager
var save_system: SaveSystem
var scene_manager: SceneManager

func _ready() -> void:
	event_system = EventSystem.new()
	party_manager = PartyManager.new(event_system)
	save_system = SaveSystem.new()
	scene_manager = SceneManager.new()
	print("GameGlobals ready: event_system=%s party_manager=%s" % [
		event_system, party_manager
	])
