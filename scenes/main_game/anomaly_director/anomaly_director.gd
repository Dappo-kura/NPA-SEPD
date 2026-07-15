class_name AnomalyDirector
extends Control

## 残り時間に応じた視覚・音響・ピース・手の怪異演出を一元管理する。
## 演出時計は MainGame から渡される delta だけで進行する。

const TENSION_SMOOTH_TIME: float = 0.5
const GLITCH_DURATION: float = 0.5
const HAND_WAIT_DURATION: float = 1.2
const HAND_ENTER_DURATION: float = 0.4
const HAND_HOLD_DURATION: float = 0.6
const HAND_EXIT_DURATION: float = 0.5

enum HandPhase { IDLE, WAITING, ENTERING, HOLDING, EXITING }

@onready var vignette: ColorRect = $Vignette
@onready var ghost_hand: TextureRect = $GhostHand
@onready var item_tray: ItemTray = get_parent().get_node("VBoxContainer/ItemTray") as ItemTray

var _rng := RandomNumberGenerator.new()
var _effect_time: float = 0.0
var _smooth_tension: float = 0.0
var _flicker_spike: float = 0.0
var _event_timer: float = 0.0

var _glitch_target: ItemVisual = null
var _glitch_elapsed: float = 0.0
var _glitch_seed_base: float = 0.0

var _hand_phase: HandPhase = HandPhase.IDLE
var _hand_elapsed: float = 0.0
var _hand_x_ratio: float = 0.0


func _ready() -> void:
	_rng.randomize()
	ghost_hand.visible = false
	_update_shader_parameters()


func tick(delta: float, tension: float) -> void:
	var safe_delta := maxf(delta, 0.0)
	_effect_time += safe_delta
	var blend := 1.0 - exp(-safe_delta / TENSION_SMOOTH_TIME)
	_smooth_tension = lerpf(_smooth_tension, clampf(tension, 0.0, 1.0), blend)
	_flicker_spike = maxf(0.0, _flicker_spike - safe_delta * 2.8)

	_update_anomaly_event(safe_delta)
	_update_glitch(safe_delta)
	_update_ghost_hand(safe_delta)
	_update_shader_parameters()
	AudioManager.set_bgm_pitch(lerpf(1.0, 1.07, _smooth_tension))


func on_mistake() -> void:
	if _hand_phase != HandPhase.IDLE:
		return
	_hand_phase = HandPhase.WAITING
	_hand_elapsed = 0.0
	_hand_x_ratio = _rng.randf_range(-0.16, 0.16)
	ghost_hand.visible = false


func stop_all() -> void:
	_hand_phase = HandPhase.IDLE
	_hand_elapsed = 0.0
	ghost_hand.visible = false
	if is_instance_valid(_glitch_target):
		_glitch_target.glitch_amount = 0.0
	_glitch_target = null
	_glitch_elapsed = 0.0
	_flicker_spike = 0.0
	_smooth_tension = 0.0
	_event_timer = 0.0
	_update_shader_parameters()
	AudioManager.set_bgm_pitch(1.0)


func _update_shader_parameters() -> void:
	var material := vignette.material as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter("tension", _smooth_tension)
	material.set_shader_parameter("effect_time", _effect_time)
	material.set_shader_parameter("flicker_spike", _flicker_spike)


func _update_anomaly_event(delta: float) -> void:
	if _smooth_tension <= 0.15:
		_event_timer = 0.0
		return

	var interval := lerpf(14.0, 5.0, _smooth_tension)
	if _event_timer <= 0.0:
		_event_timer = interval
	_event_timer -= delta
	if _event_timer > 0.0:
		return

	_event_timer = interval
	if _rng.randf() < 0.6:
		_start_piece_glitch()
	else:
		_flicker_spike = 1.0


func _start_piece_glitch() -> void:
	if is_instance_valid(_glitch_target):
		return
	var visuals := item_tray.get_item_visuals()
	if visuals.is_empty():
		_flicker_spike = 1.0
		return
	_glitch_target = visuals[_rng.randi_range(0, visuals.size() - 1)] as ItemVisual
	_glitch_elapsed = 0.0
	_glitch_seed_base = _rng.randf_range(0.0, 1000.0)


func _update_glitch(delta: float) -> void:
	if not is_instance_valid(_glitch_target):
		_glitch_target = null
		_glitch_elapsed = 0.0
		return

	_glitch_elapsed += delta
	var progress := clampf(_glitch_elapsed / GLITCH_DURATION, 0.0, 1.0)
	_glitch_target.glitch_seed = _glitch_seed_base + _effect_time * 30.0
	_glitch_target.glitch_amount = sin(progress * PI)
	if _glitch_elapsed >= GLITCH_DURATION:
		_glitch_target.glitch_amount = 0.0
		_glitch_target = null
		_glitch_elapsed = 0.0


func _update_ghost_hand(delta: float) -> void:
	var remaining := delta
	while remaining > 0.0 and _hand_phase != HandPhase.IDLE:
		var duration := _get_hand_phase_duration()
		var step := minf(remaining, duration - _hand_elapsed)
		_hand_elapsed += step
		remaining -= step
		_apply_hand_phase_visual(duration)
		if _hand_elapsed >= duration:
			_advance_hand_phase()


func _get_hand_phase_duration() -> float:
	match _hand_phase:
		HandPhase.WAITING:
			return HAND_WAIT_DURATION
		HandPhase.ENTERING:
			return HAND_ENTER_DURATION
		HandPhase.HOLDING:
			return HAND_HOLD_DURATION
		HandPhase.EXITING:
			return HAND_EXIT_DURATION
	return 0.0


func _apply_hand_phase_visual(duration: float) -> void:
	var hand_width := minf(size.x * 0.38, 420.0)
	ghost_hand.size = Vector2(hand_width, hand_width * 1.5)
	var x := (size.x - ghost_hand.size.x) * 0.5 + size.x * _hand_x_ratio
	var hidden_y := size.y + 12.0
	var shown_y := size.y - ghost_hand.size.y * 0.72

	match _hand_phase:
		HandPhase.WAITING:
			ghost_hand.visible = false
		HandPhase.ENTERING:
			ghost_hand.visible = true
			var enter_t := smoothstep(0.0, 1.0, _hand_elapsed / duration)
			ghost_hand.position = Vector2(x, lerpf(hidden_y, shown_y, enter_t))
		HandPhase.HOLDING:
			ghost_hand.visible = true
			ghost_hand.position = Vector2(x, shown_y)
		HandPhase.EXITING:
			ghost_hand.visible = true
			var exit_t := smoothstep(0.0, 1.0, _hand_elapsed / duration)
			ghost_hand.position = Vector2(x, lerpf(shown_y, hidden_y, exit_t))


func _advance_hand_phase() -> void:
	_hand_elapsed = 0.0
	match _hand_phase:
		HandPhase.WAITING:
			_hand_phase = HandPhase.ENTERING
		HandPhase.ENTERING:
			_hand_phase = HandPhase.HOLDING
		HandPhase.HOLDING:
			_hand_phase = HandPhase.EXITING
		HandPhase.EXITING:
			_hand_phase = HandPhase.IDLE
			ghost_hand.visible = false
