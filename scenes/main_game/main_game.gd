class_name MainGame
extends Control

# ─── 子ノード参照 ──────────────────────────────────────────────
@onready var hud: HUD = $VBoxContainer/HUDArea/HUD
@onready var item_tray: ItemTray = $VBoxContainer/ItemTray
@onready var grid_box: GridBox = $VBoxContainer/GridArea/GridBox
@onready var reset_button: Button = $VBoxContainer/BottomArea/BottomBar/ResetButton
@onready var seal_button: Button = $VBoxContainer/BottomArea/BottomBar/SealButton
@onready var drag_ghost: ItemVisual = $DragGhost
@onready var nightmare_event: NightmareEvent = $NightmareEvent
@onready var jump_scare: JumpScare = $JumpScare
@onready var hint_label: Label = $HintLabel

# ─── 状態機械 ─────────────────────────────────────────────────
enum State { IDLE, DRAGGING, CLICK_TO_PLACE, SEALED }
var _state: State = State.IDLE

var _game_just_cleared := false

# DRAGGING / CLICK_TO_PLACE 共通
var _active_item: ItemData = null
var _active_shape: Array[Vector2i] = []

# DRAGGING専用
var _drag_screen_offset: Vector2 = Vector2.ZERO

# ─── タイマー ─────────────────────────────────────────────────
var _time_limit: float = 0.0
var _cursed_cell_interval: float = 15.0  # 呪われたセルが出現する間隔（秒）
var _cursed_cell_timer: float = 0.0      # 次の呪われたセル出現までの残り時間


func _ready() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.game_cleared.connect(_on_game_cleared)
	GameManager.day_changed.connect(_on_day_changed)

	reset_button.pressed.connect(_on_reset_pressed)
	seal_button.pressed.connect(_on_seal_pressed)

	item_tray.item_drag_started.connect(_on_tray_drag_started)
	item_tray.item_click_selected.connect(_on_tray_click_selected)

	grid_box.item_placed.connect(_on_grid_item_placed)
	grid_box.item_rejected.connect(_on_grid_item_rejected)

	nightmare_event.event_dismissed.connect(_on_nightmare_dismissed)

	drag_ghost.visible = false
	drag_ghost.is_ghost = true
	drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_init_from_game_manager()


func _init_from_game_manager() -> void:
	var stage := GameManager.active_stage
	if stage == null:
		return
	grid_box.setup(stage)
	item_tray.populate(GameManager.unplaced_items)
	_start_timer()
	_set_state(State.IDLE)


func _start_timer() -> void:
	_time_limit = GameManager.get_time_limit()
	hud.setup_timer(_time_limit)
	# 呪われたセルは時間の半分が経過した頃から15秒ごとに出現
	_cursed_cell_timer = _cursed_cell_interval


# ─── Day/Wave切り替え ──────────────────────────────────────────
func _on_day_changed(_day: int) -> void:
	var stage := GameManager.active_stage
	if stage == null:
		return
	grid_box.setup(stage)
	item_tray.populate(GameManager.unplaced_items)
	_start_timer()
	_set_state(State.IDLE)


# ─── 入力処理 ─────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	match _state:
		State.DRAGGING:
			_handle_input_dragging(event)
		State.CLICK_TO_PLACE:
			_handle_input_click_to_place(event)


func _process(delta: float) -> void:
	match _state:
		State.DRAGGING:
			_update_drag_ghost()
			_update_grid_preview_from_mouse()
		State.CLICK_TO_PLACE:
			_update_grid_preview_from_mouse()

	# タイムダウン（封印中・ゲームオーバー後は動かさない）
	if _state != State.SEALED and _time_limit > 0.0:
		var remaining := hud.tick(delta)

		# 呪われたセル: 時間が半分以下になったら定期出現
		if hud.get_time_ratio() < 0.5:
			_cursed_cell_timer -= delta
			if _cursed_cell_timer <= 0.0:
				grid_box.add_cursed_cell()
				_cursed_cell_timer = _cursed_cell_interval

		# タイムアップ → 強制封印
		if remaining <= 0.0:
			jump_scare.trigger()
			_on_seal_pressed()


func _handle_input_dragging(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			var grid_local := grid_box.get_local_mouse_position()
			var in_grid := Rect2(Vector2.ZERO, grid_box.size).has_point(grid_local)
			if in_grid:
				_try_place_on_grid(grid_local)
			else:
				_restore_to_tray()


func _handle_input_click_to_place(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var grid_local := grid_box.get_local_mouse_position()
			var in_grid := Rect2(Vector2.ZERO, grid_box.size).has_point(grid_local)
			if in_grid:
				_try_place_on_grid(grid_local)
			else:
				_restore_to_tray()


# ─── ドラッグ ─────────────────────────────────────────────────
func _on_tray_drag_started(item: ItemData, shape: Array[Vector2i], screen_pos: Vector2) -> void:
	_active_item = item
	_active_shape = shape
	item_tray.remove_item(item)
	GameManager.unplaced_items.erase(item)  # 手に取った瞬間に除外

	drag_ghost.setup(item)
	drag_ghost.set_shape(shape)
	drag_ghost.visible = true
	_drag_screen_offset = Vector2.ZERO

	_set_state(State.DRAGGING)


func _update_drag_ghost() -> void:
	if drag_ghost.visible:
		var mouse_global := get_global_mouse_position()
		drag_ghost.global_position = mouse_global - drag_ghost.size * 0.5


func _update_grid_preview_from_mouse() -> void:
	if _active_item == null:
		return
	var grid_local := grid_box.get_local_mouse_position()
	var in_grid := Rect2(Vector2.ZERO, grid_box.size).has_point(grid_local)
	if in_grid:
		grid_box.set_preview(_active_item, _active_shape, grid_local)
	else:
		grid_box.clear_preview()


# ─── クリック配置 ────────────────────────────────────────────
func _on_tray_click_selected(item: ItemData, shape: Array[Vector2i]) -> void:
	# 回転できるピースはタップでトレイ内回転（テトリス方式）
	if item.can_rotate:
		item_tray.rotate_item(item)
		return

	# 回転できないピースのみタップでクリック配置モード
	if _state == State.CLICK_TO_PLACE and _active_item != null:
		item_tray.restore_item(_active_item)
		GameManager.unplaced_items.append(_active_item)

	_active_item = item
	_active_shape = shape
	item_tray.remove_item(item)
	GameManager.unplaced_items.erase(item)
	_set_state(State.CLICK_TO_PLACE)


# ─── 配置 ─────────────────────────────────────────────────────
func _try_place_on_grid(grid_local: Vector2) -> void:
	if _active_item == null:
		return

	var bb := _active_item.get_bounding_box(_active_shape)
	var cell := grid_box.local_pos_to_cell(grid_local)
	var origin := Vector2i(cell.x - bb.x / 2, cell.y - bb.y / 2)

	var success := grid_box.place_item(_active_item, _active_shape, origin)
	if success:
		GameManager.carried_items.append(_active_item)
		# unplaced_items からは手に取った時点で除外済み
		drag_ghost.visible = false
		_set_state(State.IDLE)


func _on_grid_item_placed(_item: ItemData, _origin: Vector2i) -> void:
	AudioManager.play_se("puzzle")
	_active_item = null
	_active_shape = []


func _on_grid_item_rejected() -> void:
	jump_scare.trigger()
	_restore_to_tray()


func _restore_to_tray() -> void:
	if _active_item != null:
		item_tray.restore_item(_active_item)
		GameManager.unplaced_items.append(_active_item)  # 手に取った時点で除外済みなので常に追加
	drag_ghost.visible = false
	grid_box.clear_preview()
	_active_item = null
	_active_shape = []
	_set_state(State.IDLE)


# ─── 回転 ─────────────────────────────────────────────────────
func _rotate_active() -> void:
	if _active_item == null or not _active_item.can_rotate:
		return
	_active_shape = _active_item.get_rotated_shape(_active_shape)
	if _state == State.DRAGGING:
		drag_ghost.set_shape(_active_shape)


# ─── リセット ────────────────────────────────────────────────
func _show_hint(msg: String) -> void:
	hint_label.text = msg
	hint_label.modulate.a = 1.0
	hint_label.visible = true
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(hint_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(hint_label.hide)


func _on_reset_pressed() -> void:
	# 全ピース配置済みなら封印を促す
	if GameManager.unplaced_items.is_empty() and _active_item == null:
		_show_hint("既に封印できる状態です\n封印ボタンを押してください")
		return

	AudioManager.play_se("enter")

	# 手持ちアイテムを破棄
	_active_item = null
	_active_shape = []
	drag_ghost.visible = false
	grid_box.clear_preview()

	# グリッドをクリア
	grid_box.clear_all_items()
	GameManager.carried_items.clear()

	# ステージの初期アイテムからトレイを再構築（追跡ではなくソースから直接復元）
	GameManager.unplaced_items.clear()
	var stage := GameManager.active_stage
	if stage != null:
		for item in stage.available_items:
			GameManager.unplaced_items.append(item)
	item_tray.populate(GameManager.unplaced_items)

	_set_state(State.IDLE)


# ─── 封印（Seal） ────────────────────────────────────────────
func _on_seal_pressed() -> void:
	if _state == State.SEALED:
		return
	_set_state(State.SEALED)

	AudioManager.play_se("seal")

	# 全マス埋め判定 → SAN回復ボーナス
	if grid_box.get_empty_cell_count() == 0 and GameManager.unplaced_items.is_empty():
		GameManager.heal_san(10)

	# 未配置アイテムのSANダメージを計算
	var records: Array = []
	for item in GameManager.unplaced_items:
		records.append({"item": item, "cell_count": item.shape.size()})

	var damage := GameManager.calculate_total_san_damage(records)
	GameManager.apply_san_damage(damage)

	# ナイトメアイベントを表示（ストーリーモードはJSONから取得）
	var nightmare_text := ""
	if GameManager.game_mode == GameManager.MODE_STORY:
		var scenario_data := ScenarioManager.get_day(GameManager.current_day)
		nightmare_text = scenario_data.get("nightmare_text", "")
	if nightmare_text.is_empty():
		var stage := GameManager.active_stage
		nightmare_text = stage.nightmare_text if stage else "暗闇が迫る……"
	nightmare_event.show_event(nightmare_text, damage)


func _on_nightmare_dismissed() -> void:
	if GameManager.san_value > 0:
		_game_just_cleared = false
		GameManager.advance_day()
		# ストーリーモードでゲームが続く場合は day_intro へ
		if not _game_just_cleared and GameManager.game_mode == GameManager.MODE_STORY:
			get_tree().change_scene_to_file("res://scenes/day_intro/day_intro.tscn")


# ─── ゲーム終了 ───────────────────────────────────────────────
func _on_game_over() -> void:
	get_tree().change_scene_to_file("res://scenes/game_over/game_over.tscn")


func _on_game_cleared() -> void:
	_game_just_cleared = true
	get_tree().change_scene_to_file("res://scenes/ending/ending.tscn")


# ─── 状態変更 ─────────────────────────────────────────────────
func _set_state(new_state: State) -> void:
	_state = new_state
