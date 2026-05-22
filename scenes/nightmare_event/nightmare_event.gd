class_name NightmareEvent
extends Control

## 封印後に表示するVNスタイルのナイトメアイベント画面

const CHAR_INTERVAL := 0.07
const TYPE_NARRATION := "narration"
const TYPE_DIALOGUE := "dialogue"
const FONT_PATH := "res://resources/fonts/HGRME.TTC"

@onready var bg_image: TextureRect = $BackgroundImage
@onready var bottom_gradient: TextureRect = $BottomGradient
@onready var san_overlay: Control = $SANOverlay
@onready var san_label: Label = $SANOverlay/SANLabel
@onready var narration_area: Control = $NarrationArea
@onready var narration_text: Label = $NarrationArea/NarrationText
@onready var dialogue_area: VBoxContainer = $DialogueArea
@onready var speaker_name: Label = $DialogueArea/SpeakerName
@onready var dialogue_text: Label = $DialogueArea/DialogueText
@onready var tap_indicator: Label = $TapIndicator

signal event_dismissed()

var _lines: Array = []
var _line_index: int = 0
var _char_index: int = 0
var _elapsed: float = 0.0
var _text_done: bool = false
var _blink_time: float = 0.0
var _san_damage: int = 0
var _showing_san: bool = false


func _ready() -> void:
	visible = false
	_setup_bottom_gradient()
	_apply_font()


func show_event(nightmare_text: String, san_damage: int) -> void:
	_san_damage = san_damage

	# CG背景をScenarioManagerから取得
	var data := ScenarioManager.get_day(GameManager.current_day)
	var cg_path: String = data.get("event_cg_path", "")
	if cg_path != "" and ResourceLoader.exists(cg_path):
		bg_image.texture = load(cg_path)
	else:
		bg_image.texture = null

	# nightmare_text をVNラインにパース
	_lines = _parse_text(nightmare_text)
	# clear_linesがあれば優先使用
	var scenario_data := ScenarioManager.get_day(GameManager.current_day)
	var clear_lines = scenario_data.get("clear_lines", null)
	if clear_lines is Array and not clear_lines.is_empty():
		_lines = []
		for entry in clear_lines:
			_lines.append({
				type = entry.get("type", "narration"),
				speaker = entry.get("speaker", ""),
				text = entry.get("text", "")
			})
	else:
		_lines = _parse_text(nightmare_text)
	_line_index = 0
	_showing_san = false
	san_overlay.visible = false
	visible = true
	set_process_input(true)

	if _lines.is_empty():
		_show_san_result()
	else:
		_show_line()


func _parse_text(raw: String) -> Array:
	var result: Array = []
	for para in raw.split("\n\n"):
		var stripped := para.strip_edges()
		if stripped.is_empty():
			continue
		if stripped.begins_with("「") and stripped.ends_with("」"):
			result.append({type = TYPE_DIALOGUE, speaker = "", text = stripped.substr(1, stripped.length() - 2)})
		else:
			result.append({type = TYPE_NARRATION, speaker = "", text = stripped})
	return result


func _apply_font() -> void:
	if not ResourceLoader.exists(FONT_PATH):
		return
	var font: FontFile = load(FONT_PATH)
	narration_text.add_theme_font_override("font", font)
	dialogue_text.add_theme_font_override("font", font)
	speaker_name.add_theme_font_override("font", font)
	san_label.add_theme_font_override("font", font)
	tap_indicator.add_theme_font_override("font", font)


func _setup_bottom_gradient() -> void:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.9)])
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill_from = Vector2(0.5, 0.0)
	grad_tex.fill_to = Vector2(0.5, 1.0)
	bottom_gradient.texture = grad_tex


func _show_line() -> void:
	if _line_index >= _lines.size():
		_show_san_result()
		return

	var line: Dictionary = _lines[_line_index]
	_char_index = 0
	_elapsed = 0.0
	_text_done = false
	_blink_time = 0.0
	tap_indicator.modulate.a = 0.0

	if line.type == TYPE_NARRATION:
		narration_area.visible = true
		dialogue_area.visible = false
		narration_text.text = ""
	else:
		narration_area.visible = false
		dialogue_area.visible = true
		var spk: String = line.get("speaker", "")
		speaker_name.text = spk
		speaker_name.visible = spk != ""
		dialogue_text.text = ""


func _show_san_result() -> void:
	_showing_san = true
	narration_area.visible = false
	dialogue_area.visible = false
	tap_indicator.modulate.a = 0.0
	_blink_time = 0.0

	if _san_damage > 0:
		san_label.text = "SAN  −" + str(_san_damage)
		san_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
	else:
		san_label.text = "SANは無事だ"
		san_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5, 1.0))
	san_overlay.visible = true
	_text_done = true


func _process(delta: float) -> void:
	if not visible:
		return
	if _showing_san:
		_blink_time += delta
		tap_indicator.modulate.a = 0.4 + 0.6 * abs(sin(_blink_time * 3.0))
		return

	if _line_index >= _lines.size():
		return

	var line: Dictionary = _lines[_line_index]
	var full_text: String = line.text

	if not _text_done:
		_elapsed += delta
		while _elapsed >= CHAR_INTERVAL and _char_index < full_text.length():
			_elapsed -= CHAR_INTERVAL
			_char_index += 1
		var partial := full_text.substr(0, _char_index)
		if line.type == TYPE_NARRATION:
			narration_text.text = partial
		else:
			dialogue_text.text = partial
		if _char_index >= full_text.length():
			_text_done = true
	else:
		_blink_time += delta
		tap_indicator.modulate.a = 0.4 + 0.6 * abs(sin(_blink_time * 3.0))


func _input(event: InputEvent) -> void:
	if not visible:
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
		_handle_advance()


func _handle_advance() -> void:
	if _showing_san:
		# SAN表示後のタップ → 終了
		AudioManager.play_se("enter")
		visible = false
		set_process_input(false)
		event_dismissed.emit()
		return

	if _line_index >= _lines.size():
		return

	var line: Dictionary = _lines[_line_index]

	if not _text_done:
		_char_index = line.text.length()
		if line.type == TYPE_NARRATION:
			narration_text.text = line.text
		else:
			dialogue_text.text = line.text
		_text_done = true
		tap_indicator.modulate.a = 1.0
	else:
		AudioManager.play_se("enter")
		_line_index += 1
		_show_line()
