extends Node

## 全 Control ノードに HG明朝E フォントを適用するグローバルテーマ設定
## Web版で日本語が豆腐になる問題の恒久対応

func _ready() -> void:
	var font: FontFile = load("res://resources/fonts/HGRME.TTC")
	if font == null:
		return
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 32
	get_tree().root.theme = theme
