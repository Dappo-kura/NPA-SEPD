extends Control

const CHAR_INTERVAL := 0.05  # 1文字あたりの秒数

@onready var bg_image: TextureRect = $BackgroundImage
@onready var page_title: Label = $DialogBox/MarginContainer/VBoxContainer/PageTitle
@onready var dialog_text: Label = $DialogBox/MarginContainer/VBoxContainer/DialogText
@onready var tap_label: Label = $DialogBox/TapToContinue

var _pages: Array[String] = []
var _page_titles: Array[String] = []
var _current_page: int = 0
var _char_index: int = 0
var _elapsed: float = 0.0
var _text_done: bool = false


func _ready() -> void:
	var day := GameManager.current_day
	var data := ScenarioManager.get_day(day)

	# 背景CG
	var cg_path: String = data.get("event_cg_path", "")
	if cg_path != "" and ResourceLoader.exists(cg_path):
		bg_image.texture = load(cg_path)

	# ページ1: 事件資料、ページ2: 開始前テキスト
	var case_title: String = data.get("case_title", "")
	var header := "【事件資料】" + case_title if case_title != "" else "【事件資料】"
	_pages = [
		data.get("case_file_text", "（データなし）"),
		data.get("intro_text", "（データなし）"),
	]
	_page_titles = [header, ""]

	_load_page(0)


func _load_page(page: int) -> void:
	_current_page = page
	_char_index = 0
	_elapsed = 0.0
	_text_done = false
	tap_label.visible = false

	var title: String = _page_titles[page]
	page_title.text = title
	page_title.visible = title != ""
	dialog_text.text = ""


func _process(delta: float) -> void:
	if _text_done:
		return
	var full_text: String = _pages[_current_page]
	_elapsed += delta
	while _elapsed >= CHAR_INTERVAL and _char_index < full_text.length():
		_elapsed -= CHAR_INTERVAL
		_char_index += 1
		dialog_text.text = full_text.substr(0, _char_index)
	if _char_index >= full_text.length():
		_text_done = true
		tap_label.visible = true


func _input(event: InputEvent) -> void:
	var tapped := false
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			tapped = true
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			tapped = true

	if tapped:
		_handle_advance()


func _handle_advance() -> void:
	var full_text: String = _pages[_current_page]
	if not _text_done:
		# タップ時：テキストを一気に表示
		_char_index = full_text.length()
		dialog_text.text = full_text
		_text_done = true
		tap_label.visible = true
	else:
		# 次ページへ / ゲームへ
		AudioManager.play_se("enter")
		if _current_page < _pages.size() - 1:
			_load_page(_current_page + 1)
		else:
			get_tree().change_scene_to_file("res://scenes/main_game/main_game.tscn")
