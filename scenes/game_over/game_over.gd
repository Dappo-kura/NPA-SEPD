extends Control

## ゲームオーバー画面。
## ストーリーモード死亡時はリワード広告視聴で同じDayからSAN全快で再挑戦できる。

@onready var retry_button: Button = $VBoxContainer/RetryButton
@onready var return_button: Button = $VBoxContainer/ReturnButton
@onready var vignette: TextureRect = $Vignette
@onready var content: VBoxContainer = $VBoxContainer

var _retry_available := false


func _ready() -> void:
	AudioManager.stop_bgm()
	return_button.pressed.connect(_on_return_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	_setup_vignette()
	content.modulate.a = 0.0
	retry_button.visible = false
	return_button.visible = false

	# 広告リトライはストーリーモード死亡時のみ
	# （死亡時点ではランは消去済み。広告報酬で再生成する）
	if GameManager.game_mode == GameManager.MODE_STORY and AdManager.is_rewarded_ad_available():
		_retry_available = true
		retry_button.text = "広告を見て Day %d から再挑戦" % GameManager.current_day

	var fade := create_tween()
	fade.tween_property(content, "modulate:a", 1.0, 1.5)
	fade.tween_callback(func() -> void:
		retry_button.visible = _retry_available
		return_button.visible = true)

	var breathe := create_tween().set_loops()
	breathe.tween_property(vignette, "modulate:a", 0.75, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathe.tween_property(vignette, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _setup_vignette() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0.45, 0.02, 0.02, 0.85)])
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill = GradientTexture2D.FILL_RADIAL
	gradient_texture.fill_from = Vector2(0.5, 0.5)
	gradient_texture.fill_to = Vector2(0.5, 0.0)
	vignette.texture = gradient_texture


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
