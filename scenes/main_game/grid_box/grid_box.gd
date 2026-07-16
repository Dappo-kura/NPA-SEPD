class_name GridBox
extends Control

## グリッド描画・配置判定・プレビュー表示を担当するコアコンポーネント
## 画面幅に追従する正方形ボックス内へ、グリッドを中央配置する。

const MAX_BOX_SIZE: int = 1000
const MIN_BOX_SIZE: int = 680
const BOX_SIDE_PADDING: int = 56

const BLOCKED_COLOR: Color = Color(0.0, 0.0, 0.0, 0.78)
const BORDER_COLOR: Color = Color(0.95, 0.74, 0.38, 0.86)
const EMPTY_CELL_COLOR: Color = Color(0.015, 0.012, 0.014, 0.58)
const EMPTY_CELL_EDGE_COLOR: Color = Color(1.0, 0.32, 0.20, 0.58)
const PREVIEW_OK_COLOR: Color = Color(0.36, 1.0, 0.48, 0.46)
const PREVIEW_NG_COLOR: Color = Color(1.0, 0.12, 0.12, 0.50)
const GLOW_OK_COLOR: Color = Color(1.0, 0.25, 0.12, 0.42)
const GLOW_NG_COLOR: Color = Color(0.95, 0.05, 0.05, 0.55)
const CURSED_WARN_COLOR: Color = Color(0.62, 0.16, 0.75, 1.0)
const CURSED_WARN_DURATION: float = 3.0  # 呪いセル封鎖までの警告時間（秒）

var cell_size: int = 100
var _box_size: int = MAX_BOX_SIZE
var _grid_offset: Vector2 = Vector2.ZERO  # グリッドをボックス内で中央に寄せるオフセット

var _bg_texture: Texture2D = null

var grid_width: int = 6
var grid_height: int = 5
var blocked_cells: Array[Vector2i] = []

## Vector2i(col, row) → ItemData
var cell_map: Dictionary = {}

## 配置済みピースを1個単位で描くための記録。
## 各エントリ: {item: ItemData, origin: Vector2i, shape: Array[Vector2i]}
var _placed_entries: Array = []

## プレビュー用（ドラッグ中 or クリック配置モード）
var _preview_shape: Array[Vector2i] = []
var _preview_origin: Vector2i = Vector2i(-1, -1)
var _preview_item: ItemData = null
var _preview_valid: bool = false

var _board_glow: float = 0.0
var _board_glow_color: Color = GLOW_OK_COLOR
var _placed_pulse_item: ItemData = null
var _placed_pulse_origin: Vector2i = Vector2i(-999, -999)
var _placed_pulse: float = 0.0

## 途中出現した呪いセル（ステージ定義の blocked_cells とは別に追跡し、リセットで解除する）
var _dynamic_cursed: Array[Vector2i] = []
var _cursed_warning_cell: Vector2i = Vector2i(-1, -1)  # 封鎖予告中のセル（なければ -1,-1）
var _cursed_warning_left: float = 0.0
var _time_warning_left: float = -1.0

signal item_placed(item: ItemData, origin: Vector2i)
signal item_rejected()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg_texture = load("res://resources/puzzle_box.png")
	resized.connect(_on_resized)
	_update_size()


func setup(stage: StageData) -> void:
	grid_width = stage.grid_width
	grid_height = stage.grid_height
	blocked_cells = stage.blocked_cells.duplicate()
	cell_map.clear()
	_placed_entries.clear()
	_dynamic_cursed.clear()
	_cursed_warning_cell = Vector2i(-1, -1)
	_cursed_warning_left = 0.0
	_time_warning_left = -1.0
	_preview_clear()
	_update_size()
	queue_redraw()


func _on_resized() -> void:
	_update_size()
	queue_redraw()


func _recalc_cell_size() -> void:
	cell_size = int(floor(min(float(_box_size) / float(grid_width), float(_box_size) / float(grid_height))))
	cell_size = max(1, cell_size)


func _update_size() -> void:
	var parent_size := Vector2.ZERO
	var parent := get_parent() as Control
	if parent != null:
		parent_size = parent.size
	var available_w := parent_size.x if parent_size.x > 0.0 else float(MAX_BOX_SIZE)
	var available_h := parent_size.y if parent_size.y > 0.0 else available_w
	var target := int(floor(min(available_w - BOX_SIDE_PADDING, available_h, float(MAX_BOX_SIZE))))
	_box_size = clamp(target, MIN_BOX_SIZE, MAX_BOX_SIZE)
	custom_minimum_size = Vector2(_box_size, _box_size)
	size = custom_minimum_size
	_recalc_cell_size()

	# グリッド領域をボックス中央に配置するオフセットを計算
	var grid_px_w := grid_width * cell_size
	var grid_px_h := grid_height * cell_size
	_grid_offset = Vector2(
		(float(_box_size) - float(grid_px_w)) * 0.5,
		(float(_box_size) - float(grid_px_h)) * 0.5
	)


# ─── 座標変換 ──────────────────────────────────────────────────
func local_pos_to_cell(local_pos: Vector2) -> Vector2i:
	var adjusted := local_pos - _grid_offset
	if adjusted.x < 0.0 or adjusted.y < 0.0:
		return Vector2i(-1, -1)
	return Vector2i(int(adjusted.x) / cell_size, int(adjusted.y) / cell_size)


func cell_to_local_pos(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size, cell.y * cell_size) + _grid_offset


# ─── プレビュー ────────────────────────────────────────────────
func set_preview(item: ItemData, shape: Array[Vector2i], local_pos: Vector2) -> void:
	_preview_item = item
	_preview_shape = shape

	if item != null:
		var bb := item.get_bounding_box(shape)
		var offset_x := bb.x / 2
		var offset_y := bb.y / 2
		var cell := local_pos_to_cell(local_pos)
		_preview_origin = Vector2i(cell.x - offset_x, cell.y - offset_y)
	else:
		_preview_origin = Vector2i(-1, -1)

	_preview_valid = can_place(shape, _preview_origin)
	queue_redraw()


func clear_preview() -> void:
	_preview_clear()
	queue_redraw()


func _preview_clear() -> void:
	_preview_item = null
	_preview_shape = []
	_preview_origin = Vector2i(-1, -1)
	_preview_valid = false


# ─── 配置判定 ──────────────────────────────────────────────────
func can_place(shape: Array[Vector2i], origin: Vector2i) -> bool:
	for cell in shape:
		var world_cell := Vector2i(origin.x + cell.x, origin.y + cell.y)
		if world_cell.x < 0 or world_cell.x >= grid_width:
			return false
		if world_cell.y < 0 or world_cell.y >= grid_height:
			return false
		if world_cell in blocked_cells:
			return false
		if cell_map.has(world_cell):
			return false
	return true


func place_item(item: ItemData, shape: Array[Vector2i], origin: Vector2i) -> bool:
	if not can_place(shape, origin):
		pulse_reject()
		item_rejected.emit()
		return false

	for cell in shape:
		var world_cell := Vector2i(origin.x + cell.x, origin.y + cell.y)
		cell_map[world_cell] = item
	_placed_entries.append({"item": item, "origin": origin, "shape": shape.duplicate()})

	_preview_clear()
	pulse_success(item, origin)
	# 警告中のセルをピースで守った → 警告を即解除して防御パルス
	if _cursed_warning_cell.x >= 0 and cell_map.has(_cursed_warning_cell):
		_cursed_warning_cell = Vector2i(-1, -1)
		_cursed_warning_left = 0.0
		pulse_defended()
	item_placed.emit(item, origin)
	queue_redraw()
	return true


func pulse_success(item: ItemData, origin: Vector2i) -> void:
	_board_glow_color = GLOW_OK_COLOR
	_placed_pulse_item = item
	_placed_pulse_origin = origin
	_set_board_glow(1.0)
	_set_placed_pulse(1.0)
	var tween := create_tween()
	tween.tween_method(_set_board_glow, 1.0, 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(_set_placed_pulse, 1.0, 0.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_clear_placed_pulse)


func pulse_reject() -> void:
	_board_glow_color = GLOW_NG_COLOR
	_set_board_glow(1.0)
	var tween := create_tween()
	tween.tween_method(_set_board_glow, 1.0, 0.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## 呪い封鎖確定の紫パルス（配置ミスの赤と判別する）
func pulse_cursed() -> void:
	_board_glow_color = Color(0.62, 0.16, 0.75, 0.50)
	_set_board_glow(1.0)
	var tween := create_tween()
	tween.tween_method(_set_board_glow, 1.0, 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## 呪い予告セルを守ったときの防御パルス
func pulse_defended() -> void:
	_board_glow_color = Color(0.85, 0.75, 1.0, 0.46)
	_set_board_glow(1.0)
	var tween := create_tween()
	tween.tween_method(_set_board_glow, 1.0, 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _clear_placed_pulse() -> void:
	_placed_pulse_item = null
	_placed_pulse_origin = Vector2i(-999, -999)


func _set_board_glow(value: float) -> void:
	_board_glow = value
	queue_redraw()


func _set_placed_pulse(value: float) -> void:
	_placed_pulse = value
	queue_redraw()


func clear_all_items() -> void:
	cell_map.clear()
	_placed_entries.clear()
	_preview_clear()
	queue_redraw()


func get_empty_cell_count() -> int:
	var count := 0
	for row in range(grid_height):
		for col in range(grid_width):
			var cell := Vector2i(col, row)
			if not cell_map.has(cell) and cell not in blocked_cells:
				count += 1
	return count


## 呪いセルの封鎖予告を開始する（即封鎖せず、警告時間の経過後に確定する）
func begin_cursed_warning() -> bool:
	if _cursed_warning_cell.x >= 0:
		return false  # 警告中は重ねて出さない
	var empty_cells: Array[Vector2i] = []
	for row in range(grid_height):
		for col in range(grid_width):
			var cell := Vector2i(col, row)
			if not cell_map.has(cell) and cell not in blocked_cells:
				empty_cells.append(cell)
	if empty_cells.is_empty():
		return false
	_cursed_warning_cell = empty_cells[randi() % empty_cells.size()]
	_cursed_warning_left = CURSED_WARN_DURATION
	queue_redraw()
	return true


## 警告の残り時間を進める（ポーズ・封印中は呼び出し側が止める）
func tick_cursed_warning(delta: float) -> void:
	if _cursed_warning_cell.x < 0:
		return
	_cursed_warning_left -= delta
	if _cursed_warning_left <= 0.0:
		_commit_cursed_cell()
	else:
		queue_redraw()


func _commit_cursed_cell() -> void:
	var cell := _cursed_warning_cell
	_cursed_warning_cell = Vector2i(-1, -1)
	_cursed_warning_left = 0.0
	# 警告中にピースを置いて守られたセルは封鎖しない（次の間隔で再抽選）
	if not cell_map.has(cell) and cell not in blocked_cells:
		blocked_cells.append(cell)
		_dynamic_cursed.append(cell)
		pulse_cursed()
	queue_redraw()


## 残り3秒の最終警告（負の値で解除）。main_game が毎フレーム渡す
func set_time_warning(remaining: float) -> void:
	var was_active := _time_warning_left >= 0.0
	_time_warning_left = remaining
	if remaining >= 0.0 or was_active:
		queue_redraw()


## 途中出現した呪いセル（と警告中のセル）を解除する。ステージ定義の封鎖マスは残す
func clear_cursed_cells() -> void:
	for cell in _dynamic_cursed:
		blocked_cells.erase(cell)
	_dynamic_cursed.clear()
	_cursed_warning_cell = Vector2i(-1, -1)
	_cursed_warning_left = 0.0
	queue_redraw()


func get_item_cell_count(item: ItemData) -> int:
	var count := 0
	for v in cell_map.values():
		if v == item:
			count += 1
	return count


func get_placed_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for entry in _placed_entries:
		result.append(entry["item"])
	return result


# ─── 描画 ─────────────────────────────────────────────────────
func _draw() -> void:
	_draw_background()
	_draw_empty_cells()
	_draw_placed_items()
	_draw_cursed_warning()
	_draw_preview()
	_draw_grid_lines()
	_draw_board_glow()
	_draw_time_warning()


func _draw_background() -> void:
	var bg_rect := Rect2(Vector2.ZERO, size)
	if _bg_texture:
		draw_texture_rect(_bg_texture, bg_rect, false)
	else:
		draw_rect(bg_rect, Color(0.12, 0.12, 0.15, 1.0))

	# ブロックマス（グリッドオフセット適用）
	for cell in blocked_cells:
		var rect := _cell_rect(cell, 0.0)
		draw_rect(rect, BLOCKED_COLOR)
		draw_rect(rect.grow(-2.0), Color(0.96, 0.14, 0.08, 0.80), false, 3.0)
		var mark_inset: float = maxf(8.0, float(cell_size) * 0.13)
		var p1 := Vector2(rect.position.x + mark_inset, rect.position.y + mark_inset)
		var p2 := Vector2(rect.end.x - mark_inset, rect.end.y - mark_inset)
		var p3 := Vector2(rect.end.x - mark_inset, rect.position.y + mark_inset)
		var p4 := Vector2(rect.position.x + mark_inset, rect.end.y - mark_inset)
		draw_line(p1, p2, Color(0.98, 0.18, 0.08, 0.90), 3.0)
		draw_line(p3, p4, Color(0.98, 0.18, 0.08, 0.90), 3.0)


func _draw_empty_cells() -> void:
	for row in range(grid_height):
		for col in range(grid_width):
			var cell := Vector2i(col, row)
			if cell_map.has(cell) or cell in blocked_cells:
				continue
			var rect := _cell_rect(cell, 5.0)
			draw_rect(rect, EMPTY_CELL_COLOR)
			draw_rect(rect, EMPTY_CELL_EDGE_COLOR, false, 1.8)
			draw_rect(rect.grow(-max(5.0, float(cell_size) * 0.09)),
					Color(1.0, 0.62, 0.44, 0.14), false, 1.0)


func _draw_placed_items() -> void:
	const PLACED_BORDER_DARK := Color(0.02, 0.02, 0.025, 1.0)
	const PLACED_BORDER_LIGHT := Color(1.0, 0.82, 0.46, 0.95)
	for entry in _placed_entries:
		var item: ItemData = entry["item"]
		var origin: Vector2i = entry["origin"]
		var shape: Array[Vector2i] = entry["shape"]
		var bb := item.get_bounding_box(shape)
		var pulse_scale := 1.0
		if item == _placed_pulse_item and origin == _placed_pulse_origin:
			pulse_scale = 1.0 - 0.08 * _placed_pulse

		for cell in shape:
			var world_cell := Vector2i(origin.x + cell.x, origin.y + cell.y)
			var rect := _cell_rect(world_cell, 1.0)
			if pulse_scale != 1.0:
				rect = _scaled_rect(rect, pulse_scale)
			var cell_fill := Color(item.color.r, item.color.g, item.color.b, 0.38)
			draw_rect(rect, Color(0.0, 0.0, 0.0, 0.48))
			draw_rect(rect.grow(-4.0), cell_fill)
			if item.texture:
				_draw_texture_cell(item.texture, cell, rect.grow(-6.0), bb,
						Color(1.0, 1.0, 1.0, 0.96))
			draw_rect(rect, PLACED_BORDER_DARK, false, 4.0)
			draw_rect(rect.grow(-3.0), PLACED_BORDER_LIGHT, false, 2.0)

			for d in range(item.danger):
				var dot_radius: float = clampf(float(cell_size) * 0.045, 4.0, 8.0)
				var dot_x: float = rect.position.x + dot_radius * 2.0 + d * dot_radius * 2.6
				var dot_y: float = rect.position.y + dot_radius * 2.0
				draw_circle(Vector2(dot_x, dot_y), dot_radius, Color(1, 0.18, 0.12, 0.95))


func _draw_cursed_warning() -> void:
	if _cursed_warning_cell.x < 0:
		return
	var rect := _cell_rect(_cursed_warning_cell, 2.0)
	# 残り時間に合わせてアルファを振動させ、封鎖が迫っていることを知らせる
	var alpha := 0.22 + 0.34 * absf(sin(_cursed_warning_left * TAU))
	draw_rect(rect, Color(CURSED_WARN_COLOR.r, CURSED_WARN_COLOR.g, CURSED_WARN_COLOR.b, alpha))
	draw_rect(rect, Color(CURSED_WARN_COLOR.r, CURSED_WARN_COLOR.g, CURSED_WARN_COLOR.b, 0.9), false, 3.0)
	var count := str(ceili(_cursed_warning_left))
	var font_size: int = maxi(24, int(float(cell_size) * 0.52))
	var text_size := ThemeDB.fallback_font.get_string_size(count, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pos := rect.position + Vector2((rect.size.x - text_size.x) * 0.5, (rect.size.y + text_size.y * 0.7) * 0.5)
	draw_string(ThemeDB.fallback_font, pos, count, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1.0, 0.9, 1.0, 0.95))


func _draw_preview() -> void:
	if _preview_item == null or _preview_shape.is_empty():
		return
	if _preview_origin.x < 0:
		return

	var color := PREVIEW_OK_COLOR if _preview_valid else PREVIEW_NG_COLOR
	var border := Color(color.r, color.g, color.b, 0.95)

	for cell in _preview_shape:
		var world_cell := Vector2i(_preview_origin.x + cell.x, _preview_origin.y + cell.y)
		if world_cell.x < 0 or world_cell.x >= grid_width:
			continue
		if world_cell.y < 0 or world_cell.y >= grid_height:
			continue

		var rect := _cell_rect(world_cell, 2.0)
		draw_rect(rect, color)
		draw_rect(rect, border, false, 4.0)


func _draw_grid_lines() -> void:
	var grid_h := grid_height * cell_size
	var grid_w := grid_width * cell_size
	# 縦線
	for col in range(grid_width + 1):
		var x := _grid_offset.x + col * cell_size
		draw_line(Vector2(x, _grid_offset.y), Vector2(x, _grid_offset.y + grid_h), BORDER_COLOR, 2.0)
	# 横線
	for row in range(grid_height + 1):
		var y := _grid_offset.y + row * cell_size
		draw_line(Vector2(_grid_offset.x, y), Vector2(_grid_offset.x + grid_w, y), BORDER_COLOR, 2.0)
	var bounds := Rect2(_grid_offset, Vector2(grid_w, grid_h))
	draw_rect(bounds, Color(1.0, 0.86, 0.46, 0.96), false, 4.0)


func _draw_board_glow() -> void:
	if _board_glow <= 0.0:
		return
	var glow_color := Color(_board_glow_color.r, _board_glow_color.g, _board_glow_color.b, _board_glow_color.a * _board_glow)
	var outer := Rect2(Vector2.ZERO, size).grow(-8.0)
	draw_rect(outer, glow_color, false, 8.0 + 10.0 * _board_glow)


func _draw_time_warning() -> void:
	if _time_warning_left < 0.0:
		return
	var outer := Rect2(Vector2.ZERO, size).grow(-6.0)
	var color := Color(1.0, 0.08, 0.05, 0.30 + 0.45 * absf(sin(_time_warning_left * TAU)))
	draw_rect(outer, color, false, 10.0)


func _cell_rect(cell: Vector2i, inset: float) -> Rect2:
	return Rect2(
		_grid_offset.x + cell.x * cell_size + inset,
		_grid_offset.y + cell.y * cell_size + inset,
		cell_size - inset * 2.0,
		cell_size - inset * 2.0
	)


func _scaled_rect(rect: Rect2, scale_value: float) -> Rect2:
	var new_size := rect.size * scale_value
	return Rect2(rect.position + (rect.size - new_size) * 0.5, new_size)


func _draw_texture_cell(texture: Texture2D, shape_cell: Vector2i, dest_rect: Rect2, bb: Vector2i, modulate: Color) -> void:
	if bb.x <= 0 or bb.y <= 0:
		return
	var tex_size := texture.get_size()
	var src_size := Vector2(tex_size.x / float(bb.x), tex_size.y / float(bb.y))
	var src_rect := Rect2(
		Vector2(shape_cell.x * src_size.x, shape_cell.y * src_size.y),
		src_size
	)
	draw_texture_rect_region(texture, dest_rect, src_rect, modulate)


# ─── マウス（クリック配置モード用） ────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			pass
