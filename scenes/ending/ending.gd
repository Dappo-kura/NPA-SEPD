extends Control

const FULL_TEXT := "見所があるな！よし！ご褒美をあげよう"
const CHAR_INTERVAL := 0.07  # 1文字あたりの秒数

@onready var dialog_text: Label = $DialogBox/MarginContainer/DialogText
@onready var tap_label: Label = $DialogBox/TapToContinue

var _char_index: int = 0
var _elapsed: float = 0.0
var _text_done: bool = false


func _ready() -> void:
	dialog_text.text = ""
	tap_label.visible = false


func _process(delta: float) -> void:
	if _text_done:
		return
	_elapsed += delta
	while _elapsed >= CHAR_INTERVAL and _char_index < FULL_TEXT.length():
		_elapsed -= CHAR_INTERVAL
		_char_index += 1
		dialog_text.text = FULL_TEXT.substr(0, _char_index)
	if _char_index >= FULL_TEXT.length():
		_text_done = true
		tap_label.visible = true


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_handle_advance()
	elif event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed:
			_handle_advance()


func _handle_advance() -> void:
	if not _text_done:
		# タップ時：テキストを一気に表示
		_char_index = FULL_TEXT.length()
		dialog_text.text = FULL_TEXT
		_text_done = true
		tap_label.visible = true
	else:
		# テキスト表示完了後のタップ：タイトルに戻る
		AudioManager.play_se("enter")
		GameManager.reset_game()
		get_tree().change_scene_to_file("res://scenes/title_screen/title_screen.tscn")
