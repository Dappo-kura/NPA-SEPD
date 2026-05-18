class_name HUD
extends VBoxContainer

@onready var day_label: Label = $TopRow/DayLabel
@onready var san_label: Label = $TopRow/SANLabel
@onready var san_bar: ProgressBar = $TopRow/SANBar
@onready var timer_bar: ProgressBar = $TimerBar

var _time_limit: float = 0.0
var _time_remaining: float = 0.0


func _ready() -> void:
	GameManager.san_changed.connect(_on_san_changed)
	GameManager.day_changed.connect(_on_day_changed)
	_refresh()


func _refresh() -> void:
	_on_day_changed(GameManager.current_day)
	_on_san_changed(GameManager.san_value)


func _on_day_changed(day: int) -> void:
	if GameManager.game_mode == GameManager.MODE_INFINITE:
		day_label.text = "Wave %d" % day
	else:
		day_label.text = "Day %d" % day


func _on_san_changed(value: int) -> void:
	san_label.text = "SAN: %d" % value
	san_bar.value = value
	if value > 60:
		san_bar.modulate = Color(0.2, 0.8, 0.2)
	elif value > 30:
		san_bar.modulate = Color(0.9, 0.7, 0.1)
	else:
		san_bar.modulate = Color(0.9, 0.2, 0.2)


# ─── タイマー ────────────────────────────────────────────────
func setup_timer(limit: float) -> void:
	_time_limit = limit
	_time_remaining = limit
	if limit <= 0.0:
		timer_bar.visible = false
		return
	timer_bar.visible = true
	timer_bar.max_value = limit
	timer_bar.value = limit
	timer_bar.modulate = Color(0.2, 0.8, 0.2)


## delta分だけ時間を進める。残り時間を返す（0になったらタイムアップ）
func tick(delta: float) -> float:
	if _time_limit <= 0.0:
		return 1.0  # 制限なし
	_time_remaining = max(0.0, _time_remaining - delta)
	timer_bar.value = _time_remaining
	_update_timer_color()
	return _time_remaining


func _update_timer_color() -> void:
	var ratio := _time_remaining / _time_limit
	if ratio > 0.5:
		timer_bar.modulate = Color(0.2, 0.8, 0.2)
	elif ratio > 0.25:
		timer_bar.modulate = Color(0.9, 0.7, 0.1)
	else:
		timer_bar.modulate = Color(0.9, 0.2, 0.2)


func get_time_ratio() -> float:
	if _time_limit <= 0.0:
		return 1.0
	return _time_remaining / _time_limit
