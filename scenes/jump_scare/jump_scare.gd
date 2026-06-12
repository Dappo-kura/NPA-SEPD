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


# load() で連番を直接探索（エクスポートビルドでも動作する）
func _scan_available_jumpscares() -> void:
	var consecutive_missing := 0
	var i := 1
	while consecutive_missing < 5:
		var img_path := JUMPSCARE_DIR + "jumpscare_%d.png" % i
		var tex = load(img_path)
		if tex != null:
			_available_indices.append(i)
			consecutive_missing = 0
		else:
			consecutive_missing += 1
		i += 1
	_available_indices.sort()


func trigger() -> void:
	# エフェクト中の再トリガーは無視
	if _is_playing:
		return
	# インデックスが取得できていればランダム選択、なければ画像なしで演出だけ実行
	var idx: int = -1
	if not _available_indices.is_empty():
		idx = _available_indices[randi() % _available_indices.size()]
	_play_effect(idx)


func _play_effect(idx: int) -> void:
	_is_playing = true

	# 画像・SEをロード（idx=-1 または load失敗の場合は null）
	if idx >= 0:
		var img_path := JUMPSCARE_DIR + "jumpscare_%d.png" % idx
		scare_image.texture = load(img_path)
		var se_path := JUMPSCARE_DIR + "jumpscare_%d.mp3" % idx
		audio_scare.stream = load(se_path)
	else:
		scare_image.texture = null
		audio_scare.stream = null

	visible = true

	# 即時表示 (alpha=1)
	background.modulate.a = 1.0
	scare_image.modulate.a = 1.0

	# 効果音再生 → 音量フェードアウト（SE音量設定を基準にする）
	if audio_scare.stream != null:
		audio_scare.stop()
		var se_vol := AudioManager.get_se_volume()
		var base_db := linear_to_db(se_vol) if se_vol > 0.0 else -80.0
		audio_scare.volume_db = base_db
		audio_scare.play()
		var audio_tween := create_tween()
		audio_tween.tween_method(_set_audio_db, base_db, -80.0, 3.0)

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
