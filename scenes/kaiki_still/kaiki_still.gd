class_name KaikiStill
extends Control

## 未収納封印時に表示するフルスクリーン怪異スチル
## damage > 0 のときだけ main_game から呼び出す

const FONT_PATH := "res://resources/fonts/HGRME.TTC"

@onready var bg_image: TextureRect = $BgImage
@onready var red_flash: ColorRect = $RedFlash
@onready var tap_indicator: Label = $TapIndicator

signal still_dismissed()

var _blink_time: float = 0.0
var _ready_to_dismiss: bool = false


func _ready() -> void:
	visible = false
	_apply_font()


func show_still(day: int) -> void:
	var data := ScenarioManager.get_kaiki_still(day)
	var img_path: String = data.get("kaiki_still_path", "")
	if img_path != "" and ResourceLoader.exists(img_path):
		bg_image.texture = load(img_path)
	else:
		bg_image.texture = null

	tap_indicator.modulate.a = 0.0
	red_flash.modulate.a = 0.0
	_ready_to_dismiss = false
	_blink_time = 0.0
	visible = true
	set_process_input(true)

	# 赤フラッシュ → フェードアウト後にタップ受付
	var tween := create_tween()
	tween.tween_property(red_flash, "modulate:a", 0.65, 0.1)
	tween.tween_property(red_flash, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void: _ready_to_dismiss = true)


func _apply_font() -> void:
	if not ResourceLoader.exists(FONT_PATH):
		return
	var font: FontFile = load(FONT_PATH)
	tap_indicator.add_theme_font_override("font", font)


func _process(delta: float) -> void:
	if not visible or not _ready_to_dismiss:
		return
	_blink_time += delta
	tap_indicator.modulate.a = 0.4 + 0.6 * abs(sin(_blink_time * 3.0))


func _input(event: InputEvent) -> void:
	if not visible or not _ready_to_dismiss:
		return
	var tapped := false
	if event is InputEventScreenTouch:
		if (event as InputEventScreenTouch).pressed:
			tapped = true
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			tapped = true

	if tapped:
		AudioManager.play_se("enter")
		visible = false
		set_process_input(false)
		still_dismissed.emit()
