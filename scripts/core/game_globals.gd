extends Node

## 全局游戏状态
## EventSystem、PartyManager、SaveManager 都在这里

const AudioManagerScript = preload("res://scripts/core/audio_manager.gd")
const EventSystemScript = preload("res://scripts/systems/event_system.gd")
const InventoryScript = preload("res://scripts/core/inventory.gd")
const PartyManagerScript = preload("res://scripts/core/party_manager.gd")
const QuestLogScript = preload("res://scripts/core/quest_log.gd")
const SaveSystemScript = preload("res://scripts/systems/save_system.gd")
const SceneManagerScript = preload("res://scripts/core/scene_manager.gd")

var event_system: RefCounted
var party_manager: RefCounted
var save_system: RefCounted
var scene_manager: RefCounted
var audio_manager: Node
var inventory: RefCounted
var quest_log: RefCounted

func _ready() -> void:
	event_system = EventSystemScript.new()
	party_manager = PartyManagerScript.new(event_system)
	save_system = SaveSystemScript.new()
	scene_manager = SceneManagerScript.new()
	audio_manager = AudioManagerScript.new()
	add_child(audio_manager)
	inventory = InventoryScript.new()
	quest_log = QuestLogScript.new(event_system)
	print("GameGlobals ready: event_system=%s party_manager=%s audio_manager=%s inventory=%s quest_log=%s" % [
		event_system, party_manager, audio_manager, inventory, quest_log
	])
