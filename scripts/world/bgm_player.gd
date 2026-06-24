class_name BGMPlayer
extends Node

## 场景 BGM 播放节点
## _ready 时调用 AudioManager.play_music

@export var music: String = "town"  # town/forest/cave/battle/boss

func _ready() -> void:
	var globals = _get_globals()
	if globals and globals.audio_manager:
		globals.audio_manager.play_music(music)

func _get_globals() -> Node:
	for child in get_tree().root.get_children():
		if child.name == "GameGlobals":
			return child
	return null