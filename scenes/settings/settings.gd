extends Control

## 設定画面: BGM/SE音量。変更は即時反映し、画面を出るときに保存する。

@onready var bgm_slider: HSlider = $CenterContainer/VBoxContainer/BGMSlider
@onready var bgm_value_label: Label = $CenterContainer/VBoxContainer/BGMRow/BGMValueLabel
@onready var se_slider: HSlider = $CenterContainer/VBoxContainer/SESlider
@onready var se_value_label: Label = $CenterContainer/VBoxContainer/SERow/SEValueLabel
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton


func _ready() -> void:
	bgm_slider.value = AudioManager.get_bgm_volume()
	se_slider.value = AudioManager.get_se_volume()
	_update_value_labels()

	bgm_slider.value_changed.connect(_on_bgm_changed)
	se_slider.value_changed.connect(_on_se_changed)
	se_slider.drag_ended.connect(_on_se_drag_ended)
	back_button.pressed.connect(_on_back_pressed)


func _update_value_labels() -> void:
	bgm_value_label.text = "%d%%" % int(round(bgm_slider.value * 100))
	se_value_label.text = "%d%%" % int(round(se_slider.value * 100))


func _on_bgm_changed(value: float) -> void:
	AudioManager.set_bgm_volume(value)
	_update_value_labels()


func _on_se_changed(value: float) -> void:
	AudioManager.set_se_volume(value)
	_update_value_labels()


func _on_se_drag_ended(_value_changed: bool) -> void:
	# 音量確認用にSEを鳴らす
	AudioManager.play_se("enter")


func _on_back_pressed() -> void:
	SaveManager.save_volume_settings(bgm_slider.value, se_slider.value)
	AudioManager.play_se("enter")
	get_tree().change_scene_to_file("res://scenes/title_screen/title_screen.tscn")


func _notification(what: int) -> void:
	# Androidバックキー等で抜けた場合も設定を失わないようにする
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		SaveManager.save_volume_settings(bgm_slider.value, se_slider.value)
