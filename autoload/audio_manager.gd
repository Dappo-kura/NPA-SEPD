extends Node

var _bgm_player: AudioStreamPlayer
var _se_player: AudioStreamPlayer

var _se_streams: Dictionary = {}

var _bgm_volume: float = 1.0
var _se_volume: float = 1.0


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	add_child(_bgm_player)

	_se_player = AudioStreamPlayer.new()
	add_child(_se_player)

	_se_streams["puzzle"] = load("res://resources/sound/puzzle_se.mp3")
	_se_streams["enter"]  = load("res://resources/sound/enter.mp3")
	_se_streams["seal"]   = load("res://resources/sound/seal.mp3")


func play_bgm() -> void:
	if _bgm_player.playing:
		return
	var stream := load("res://resources/sound/npasepd_bgm.mp3") as AudioStreamMP3
	stream.loop = true
	_bgm_player.stream = stream
	_bgm_player.play()


func stop_bgm() -> void:
	_bgm_player.stop()


func play_se(key: String) -> void:
	if not _se_streams.has(key):
		return
	_se_player.stream = _se_streams[key]
	_se_player.play()


# ─── 音量設定（0.0〜1.0、SaveManagerから初期化される） ──────
func set_bgm_volume(v: float) -> void:
	_bgm_volume = clampf(v, 0.0, 1.0)
	_bgm_player.volume_db = linear_to_db(_bgm_volume) if _bgm_volume > 0.0 else -80.0


func set_se_volume(v: float) -> void:
	_se_volume = clampf(v, 0.0, 1.0)
	_se_player.volume_db = linear_to_db(_se_volume) if _se_volume > 0.0 else -80.0


func get_bgm_volume() -> float:
	return _bgm_volume


func get_se_volume() -> float:
	return _se_volume
