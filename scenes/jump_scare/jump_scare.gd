class_name JumpScare
extends CanvasLayer

@onready var background: ColorRect = $Background
@onready var scare_image: TextureRect = $ScareImage
@onready var audio_scare: AudioStreamPlayer = $AudioScare

var _is_playing: bool = false
var _available_indices: Array[int] = []

const JUMPSCARE_DIR := "res://resources/jumpscare/"


func _ready() -> void:
	_scan_available_jumpscares()
	visible = false


# res://resources/jumpscare/ 内の jumpscare_N.png を検索してインデックス一覧を構築
func _scan_available_jumpscares() -> void:
	var dir := DirAccess.open(JUMPSCARE_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with("jumpscare_") and file_name.ends_with(".png"):
			var num_str := file_name.trim_prefix("jumpscare_").trim_suffix(".png")
			if num_str.is_valid_int():
				_available_indices.append(num_str.to_int())
		file_name = dir.get_next()
	dir.list_dir_end()
	_available_indices.sort()


func trigger() -> void:
	# エフェクト中の再トリガーは無視
	if _is_playing:
		return
	if _available_indices.is_empty():
		return
	# ランダムに選択
	var idx: int = _available_indices[randi() % _available_indices.size()]
	_play_effect(idx)


func _play_effect(idx: int) -> void:
	_is_playing = true

	# 選択インデックスに対応する画像・SEをロード
	var img_path := JUMPSCARE_DIR + "jumpscare_%d.png" % idx
	scare_image.texture = load(img_path) if ResourceLoader.exists(img_path) else null

	var se_path := JUMPSCARE_DIR + "jumpscare_%d.mp3" % idx
	audio_scare.stream = load(se_path)  # null + エラー出力でロード失敗を検知可能

	visible = true

	# 即時表示 (alpha=1)
	background.modulate.a = 1.0
	scare_image.modulate.a = 1.0

	# 効果音再生 → 0.5秒で音量フェードアウト
	if audio_scare.stream != null:
		audio_scare.stop()
		audio_scare.volume_db = 0.0
		audio_scare.play()
		var audio_tween := create_tween()
		audio_tween.tween_method(_set_audio_db, 0.0, -80.0, 3.0)

	# 0.7秒ホールド → 0.5秒フェードアウト
	var tween := create_tween()
	tween.tween_interval(0.7)
	tween.tween_method(_set_alpha, 1.0, 0.0, 0.5)
	tween.tween_callback(_on_effect_finished)


func _set_alpha(a: float) -> void:
	background.modulate.a = a
	scare_image.modulate.a = a


func _set_audio_db(db: float) -> void:
	audio_scare.volume_db = db


func _on_effect_finished() -> void:
	audio_scare.stop()
	audio_scare.volume_db = 0.0
	visible = false
	_is_playing = false
