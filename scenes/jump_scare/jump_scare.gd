class_name JumpScare
extends CanvasLayer

@onready var background: ColorRect = $Background
@onready var scare_image: TextureRect = $ScareImage
@onready var noise_overlay: ColorRect = $NoiseOverlay
@onready var audio_scare: AudioStreamPlayer = $AudioScare
@onready var audio_noise: AudioStreamPlayer = $AudioNoise

var _is_playing: bool = false


func _ready() -> void:
	# ジャンプスケア画像ロード（存在しない場合はスキップ）
	if ResourceLoader.exists("res://resources/jumpscare.png"):
		scare_image.texture = load("res://resources/jumpscare.png")

	# 効果音ロード
	if ResourceLoader.exists("res://resources/sound/jumpscare.mp3"):
		audio_scare.stream = load("res://resources/sound/jumpscare.mp3")

	if ResourceLoader.exists("res://resources/sound/noise.mp3"):
		audio_noise.stream = load("res://resources/sound/noise.mp3")

	visible = false


func trigger() -> void:
	# エフェクト中の再トリガーは無視
	if _is_playing:
		return
	_play_effect()


func _play_effect() -> void:
	_is_playing = true
	visible = true

	# 即時表示 (alpha=1)
	background.modulate.a = 1.0
	scare_image.modulate.a = 1.0
	noise_overlay.modulate.a = 1.0

	# 効果音再生
	if audio_scare.stream != null:
		audio_scare.play()
	if audio_noise.stream != null:
		audio_noise.play()

	# 1.2秒ホールド → 0.5秒フェードアウト
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_method(_set_alpha, 1.0, 0.0, 0.5)
	tween.tween_callback(_on_effect_finished)


func _set_alpha(a: float) -> void:
	background.modulate.a = a
	scare_image.modulate.a = a
	noise_overlay.modulate.a = a


func _on_effect_finished() -> void:
	visible = false
	_is_playing = false
