extends Control

## ゲームオーバー画面。
## ストーリーモード死亡時はリワード広告視聴で同じDayからSAN全快で再挑戦できる。

@onready var retry_button: Button = $VBoxContainer/RetryButton
@onready var return_button: Button = $VBoxContainer/ReturnButton


func _ready() -> void:
	return_button.pressed.connect(_on_return_pressed)
	retry_button.pressed.connect(_on_retry_pressed)

	# 広告リトライはストーリーモード死亡時のみ
	# （死亡時点ではランは消去済み。広告報酬で再生成する）
	if GameManager.game_mode == GameManager.MODE_STORY and AdManager.is_rewarded_ad_available():
		retry_button.text = "広告を見て Day %d から再挑戦" % GameManager.current_day
	else:
		retry_button.visible = false


func _on_retry_pressed() -> void:
	AudioManager.play_se("enter")
	retry_button.disabled = true
	AdManager.show_rewarded(_on_ad_finished)


func _on_ad_finished(success: bool) -> void:
	if not success:
		retry_button.disabled = false
		return
	# 報酬: 死亡したDayをSAN全快で再開
	SaveManager.save_story_run(GameManager.current_day, 100)
	GameManager.continue_story()
	get_tree().change_scene_to_file("res://scenes/day_intro/day_intro.tscn")


func _on_return_pressed() -> void:
	AudioManager.play_se("enter")
	get_tree().change_scene_to_file("res://scenes/title_screen/title_screen.tscn")
