class_name GridBox
extends Control

## グリッド描画・配置判定・プレビュー表示を担当するコアコンポーネント
## 画面幅に追従する正方形ボックス内へ、グリッドを中央配置する。

const MAX_BOX_SIZE: int = 1000
const MIN_BOX_SIZE: int = 680
const BOX_SIDE_PADDING: int = 56

const GRID_COLOR: Color = Color(0.3, 0.3, 0.35, 1.0)
const BLOCKED_COLOR: Color = Color(0.0, 0.0, 0.0, 0.55)
const BORDER_COLOR: Color = Color(0.74, 0.52, 0.24, 0.72)
const EMPTY_CELL_COLOR: Color = Color(1.0, 0.18, 0.12, 0.10)
const EMPTY_CELL_EDGE_COLOR: Color = Color(1.0, 0.6, 0.45, 0.18)
const PREVIEW_OK_COLOR: Color = Color(0.36, 1.0, 0.48, 0.46)
const PREVIEW_NG_COLOR: Color = Color(1.0, 0.12, 0.12, 0.50)
const GLOW_OK_COLOR: Color = Color(1.0, 0.25, 0.12, 0.42)
const GLOW_NG_COLOR: Color = Color(0.95, 0.05, 0.05, 0.55)

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


func add_cursed_cell() -> bool:
	var empty_cells: Array[Vector2i] = []
	for row in range(grid_height):
		for col in range(grid_width):
			var cell := Vector2i(col, row)
			if not cell_map.has(cell) and cell not in blocked_cells:
				empty_cells.append(cell)
	if empty_cells.is_empty():
		return false
	var target := empty_cells[randi() % empty_cells.size()]
	blocked_cells.append(target)
	pulse_reject()
	queue_redraw()
	return true


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
	_draw_preview()
	_draw_grid_lines()
	_draw_board_glow()


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
		var p1 := Vector2(rect.position.x + 8, rect.position.y + 8)
		var p2 := Vector2(rect.end.x - 8, rect.end.y - 8)
		var p3 := Vector2(rect.end.x - 8, rect.position.y + 8)
		var p4 := Vector2(rect.position.x + 8, rect.end.y - 8)
		draw_line(p1, p2, Color(0.5, 0.3, 0.1, 0.8), 2.0)
		draw_line(p3, p4, Color(0.5, 0.3, 0.1, 0.8), 2.0)


func _draw_empty_cells() -> void:
	for row in range(grid_height):
		for col in range(grid_width):
			var cell := Vector2i(col, row)
			if cell_map.has(cell) or cell in blocked_cells:
				continue
			var rect := _cell_rect(cell, 5.0)
			draw_rect(rect, EMPTY_CELL_COLOR)
			draw_rect(rect, EMPTY_CELL_EDGE_COLOR, false, 1.0)


func _draw_placed_items() -> void:
	const PLACED_FILL_COLOR := Color(0.60, 0.60, 0.62, 0.50)
	const PLACED_BORDER_COLOR := Color(0.35, 0.35, 0.38, 0.90)
	const PLACED_TEX_MODULATE := Color(0.72, 0.72, 0.75, 0.55)
	for entry in _placed_entries:
		var item: ItemData = entry["item"]
		var origin: Vector2i = entry["origin"]
		var shape: Array[Vector2i] = entry["shape"]
		var pulse_scale := 1.0
		if item == _placed_pulse_item and origin == _placed_pulse_origin:
			pulse_scale = 1.0 - 0.08 * _placed_pulse

		if item.texture:
			var bb := item.get_bounding_box(shape)
			var full_rect := Rect2(
				_grid_offset + Vector2(origin.x * cell_size, origin.y * cell_size),
				Vector2(bb.x * cell_size, bb.y * cell_size)
			)
			if pulse_scale != 1.0:
				full_rect = _scaled_rect(full_rect, pulse_scale)
			draw_texture_rect(item.texture, full_rect, false, PLACED_TEX_MODULATE)

		for cell in shape:
			var world_cell := Vector2i(origin.x + cell.x, origin.y + cell.y)
			var rect := _cell_rect(world_cell, 1.0)
			if pulse_scale != 1.0:
				rect = _scaled_rect(rect, pulse_scale)
			if not item.texture:
				draw_rect(rect, PLACED_FILL_COLOR)
			draw_rect(rect, PLACED_BORDER_COLOR, false, 1.5)

			for d in range(item.danger):
				var dot_x := rect.position.x + 10.0 + d * 14.0
				var dot_y := rect.position.y + 10.0
				draw_circle(Vector2(dot_x, dot_y), 5.0, Color(1, 0.3, 0.3, 0.9))


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
		draw_rect(rect, border, false, 3.0)


func _draw_grid_lines() -> void:
	var grid_h := grid_height * cell_size
	var grid_w := grid_width * cell_size
	# 縦線
	for col in range(grid_width + 1):
		var x := _grid_offset.x + col * cell_size
		draw_line(Vector2(x, _grid_offset.y), Vector2(x, _grid_offset.y + grid_h), BORDER_COLOR, 1.5)
	# 横線
	for row in range(grid_height + 1):
		var y := _grid_offset.y + row * cell_size
		draw_line(Vector2(_grid_offset.x, y), Vector2(_grid_offset.x + grid_w, y), BORDER_COLOR, 1.5)


func _draw_board_glow() -> void:
	if _board_glow <= 0.0:
		return
	var glow_color := Color(_board_glow_color.r, _board_glow_color.g, _board_glow_color.b, _board_glow_color.a * _board_glow)
	var outer := Rect2(Vector2.ZERO, size).grow(-8.0)
	draw_rect(outer, glow_color, false, 8.0 + 10.0 * _board_glow)


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


# ─── マウス（クリック配置モード用） ────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			pass
