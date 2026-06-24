extends Node

## 翻译管理器：在游戏启动时加载所有 .po 文件
## 作为 autoload 单例运行

func _ready() -> void:
	_load_po("res://locale/zh.po", "zh")
	_load_po("res://locale/en.po", "en")
	# 默认中文
	TranslationServer.set_locale("zh")
	print("LocaleManager: translations loaded. Current locale: %s" % TranslationServer.get_locale())

func _load_po(path: String, locale: String) -> void:
	if not FileAccess.file_exists(path):
		push_warning("Locale file missing: %s" % path)
		return
	var trans := Translation.new()
	trans.locale = locale
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("Cannot open locale file: %s" % path)
		return
	# 用 PO parser 加载
	var content := f.get_as_text()
	f.close()
	# Godot 4 的 .po 加载
	var po_translation := ResourceLoader.load(path, "Translation")
	if po_translation is Translation:
		TranslationServer.add_translation(po_translation)
		print("  + Loaded translation: %s" % locale)
	else:
		push_warning("Failed to load translation: %s" % path)

func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)
	print("Locale changed to: %s" % locale)

func t(key: String) -> String:
	return TranslationServer.translate(key)