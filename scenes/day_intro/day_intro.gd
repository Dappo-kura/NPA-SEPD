extends Control

const CHAR_INTERVAL := 0.07
const TYPE_NARRATION := "narration"
const TYPE_DIALOGUE := "dialogue"
const FONT_PATH := "res://resources/fonts/HGRME.TTC"

@onready var bg_image: TextureRect = $BackgroundImage
@onready var bottom_gradient: TextureRect = $BottomGradient
@onready var narration_area: Control = $NarrationArea
@onready var narration_text: Label = $NarrationArea/NarrationText
@onready var dialogue_area: VBoxContainer = $DialogueArea
@onready var speaker_name: Label = $DialogueArea/SpeakerName
@onready var dialogue_text: Label = $DialogueArea/DialogueText
@onready var tap_indicator: Label = $TapIndicator

var _lines: Array = []
var _line_index: int = 0
var _char_index: int = 0
var _elapsed: float = 0.0
var _text_done: bool = false
var _blink_time: float = 0.0


func _ready() -> void:
	_setup_bottom_gradient()
	_apply_font()

	var day := GameManager.current_day
	var data := ScenarioManager.get_day(day)

	# 背景CG
	var cg_path: String = data.get("event_cg_path", "")
	if cg_path != "" and ResourceLoader.exists(cg_path):
		bg_image.texture = load(cg_path)

	# intro_text を1行ずつパース
	# JSON側に intro_lines 配列があればそちらを優先（将来対応）
	var intro_lines = data.get("intro_lines", null)
	if intro_lines is Array:
		for entry in intro_lines:
			_lines.append({
				type = entry.get("type", TYPE_NARRATION),
				speaker = entry.get("speaker", ""),
				text = entry.get("text", "")
			})
	else:
		var intro_text: String = data.get("intro_text", "")
		_lines = _parse_text(intro_text)

	if _lines.is_empty():
		get_tree().change_scene_to_file("res://scenes/main_game/main_game.tscn")
		return

	_show_line()


## 長文テキストを段落に分割して narration / dialogue に分類する
func _parse_text(raw: String) -> Array:
	var result: Array = []
	for para in raw.split("\n\n"):
		var stripped := para.strip_edges()
		if stripped.is_empty():
			continue
		# 「...」で始まり終わる段落はセリフとして扱う（「」は除去して表示）
		if stripped.begins_with("「") and stripped.ends_with("」"):
			result.append({
				type = TYPE_DIALOGUE,
				speaker = "",
				text = stripped.substr(1, stripped.length() - 2)
			})
		else:
			result.append({
				type = TYPE_NARRATION,
				speaker = "",
				text = stripped
			})
	return result


## HGR明朝Eをすべてのテキストノードに適用
func _apply_font() -> void:
	if not ResourceLoader.exists(FONT_PATH):
		return
	var font: FontFile = load(FONT_PATH)
	narration_text.add_theme_font_override("font", font)
	dialogue_text.add_theme_font_override("font", font)
	speaker_name.add_theme_font_override("font", font)
	tap_indicator.add_theme_font_override("font", font)


## 下部グラデーションテクスチャをコードで生成（透明→暗）
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
		get_tree().change_scene_to_file("res://scenes/case_file/case_file.tscn")
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


func _process(delta: float) -> void:
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
	if _line_index >= _lines.size():
		return

	var line: Dictionary = _lines[_line_index]

	if not _text_done:
		# タイプライターをスキップして全文表示
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
