class_name GridBox
extends Control

## グリッド描画・配置判定・プレビュー表示を担当するコアコンポーネント

const MAX_cell_size: int = 160
const MAX_GRID_PIXELS: int = 900  # 画面に収まる最大グリッド幅（px）
const GRID_COLOR: Color = Color(0.3, 0.3, 0.35, 1.0)
const BLOCKED_COLOR: Color = Color(0.0, 0.0, 0.0, 0.55)
const BORDER_COLOR: Color = Color(0.6, 0.45, 0.2, 0.6)
const PREVIEW_OK_COLOR: Color = Color(0.2, 0.9, 0.2, 0.45)
const PREVIEW_NG_COLOR: Color = Color(0.9, 0.2, 0.2, 0.45)

var cell_size: int = MAX_cell_size

var _bg_texture: Texture2D = null

var grid_width: int = 6
var grid_height: int = 5
var blocked_cells: Array[Vector2i] = []

## Vector2i(col, row) → ItemData
var cell_map: Dictionary = {}

## プレビュー用（ドラッグ中 or クリック配置モード）
var _preview_shape: Array[Vector2i] = []
var _preview_origin: Vector2i = Vector2i(-1, -1)
var _preview_item: ItemData = null
var _preview_valid: bool = false

signal item_placed(item: ItemData, origin: Vector2i)
signal item_rejected()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg_texture = load("res://resources/puzzle_box.png")
	_update_size()


func setup(stage: StageData) -> void:
	grid_width = stage.grid_width
	grid_height = stage.grid_height
	blocked_cells = stage.blocked_cells.duplicate()
	cell_map.clear()
	_preview_clear()
	_recalc_cell_size()
	_update_size()
	queue_redraw()


func _recalc_cell_size() -> void:
	var max_dim: int = max(grid_width, grid_height)
	cell_size = min(MAX_cell_size, MAX_GRID_PIXELS / max_dim)


func _update_size() -> void:
	custom_minimum_size = Vector2(grid_width * cell_size, grid_height * cell_size)
	size = custom_minimum_size


# ─── 座標変換 ──────────────────────────────────────────────────
func local_pos_to_cell(local_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(local_pos.x) / cell_size,
		int(local_pos.y) / cell_size
	)


func cell_to_local_pos(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size, cell.y * cell_size)


# ─── プレビュー ────────────────────────────────────────────────
func set_preview(item: ItemData, shape: Array[Vector2i], local_pos: Vector2) -> void:
	_preview_item = item
	_preview_shape = shape

	# アイテムの中心をマウス位置に合わせたオリジン計算
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
		# 範囲外チェック
		if world_cell.x < 0 or world_cell.x >= grid_width:
			return false
		if world_cell.y < 0 or world_cell.y >= grid_height:
			return false
		# ブロックマスチェック
		if world_cell in blocked_cells:
			return false
		# 重複チェック
		if cell_map.has(world_cell):
			return false
	return true


func place_item(item: ItemData, shape: Array[Vector2i], origin: Vector2i) -> bool:
	if not can_place(shape, origin):
		item_rejected.emit()
		return false

	for cell in shape:
		var world_cell := Vector2i(origin.x + cell.x, origin.y + cell.y)
		cell_map[world_cell] = item

	_preview_clear()
	item_placed.emit(item, origin)
	queue_redraw()
	return true


## グリッドに置かれたアイテムを全て除去（Resetボタン用）
func clear_all_items() -> void:
	cell_map.clear()
	_preview_clear()
	queue_redraw()


## アイテム未配置かつブロックでもない空きセル数を返す
func get_empty_cell_count() -> int:
	var count := 0
	for row in range(grid_height):
		for col in range(grid_width):
			var cell := Vector2i(col, row)
			if not cell_map.has(cell) and cell not in blocked_cells:
				count += 1
	return count


## ランダムな空きセルを呪われたセル（封印不能マス）に追加する
## 戻り値: 追加できた場合 true
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
	queue_redraw()
	return true


## 指定アイテムが占めているセル数を返す（SAN計算用）
func get_item_cell_count(item: ItemData) -> int:
	var count := 0
	for v in cell_map.values():
		if v == item:
			count += 1
	return count


## 全配置済みアイテムをユニークリストで返す
func get_placed_items() -> Array[ItemData]:
	var seen: Dictionary = {}
	var result: Array[ItemData] = []
	for v in cell_map.values():
		if not seen.has(v):
			seen[v] = true
			result.append(v)
	return result


# ─── 描画 ─────────────────────────────────────────────────────
func _draw() -> void:
	_draw_background()
	_draw_placed_items()
	_draw_preview()
	_draw_grid_lines()


func _draw_background() -> void:
	# 全体背景
	var bg_rect := Rect2(Vector2.ZERO, size)
	if _bg_texture:
		draw_texture_rect(_bg_texture, bg_rect, false)
	else:
		draw_rect(bg_rect, Color(0.12, 0.12, 0.15, 1.0))

	# ブロックマス
	for cell in blocked_cells:
		var rect := Rect2(cell.x * cell_size, cell.y * cell_size, cell_size, cell_size)
		draw_rect(rect, BLOCKED_COLOR)
		# バツ印
		var p1 := Vector2(rect.position.x + 8, rect.position.y + 8)
		var p2 := Vector2(rect.end.x - 8, rect.end.y - 8)
		var p3 := Vector2(rect.end.x - 8, rect.position.y + 8)
		var p4 := Vector2(rect.position.x + 8, rect.end.y - 8)
		draw_line(p1, p2, Color(0.5, 0.3, 0.1, 0.8), 2.0)
		draw_line(p3, p4, Color(0.5, 0.3, 0.1, 0.8), 2.0)


func _draw_placed_items() -> void:
	# アイテムごとにセルをグループ化
	var item_cells: Dictionary = {}  # ItemData -> Array[Vector2i]
	for world_cell in cell_map:
		var item: ItemData = cell_map[world_cell]
		if not item_cells.has(item):
			item_cells[item] = []
		item_cells[item].append(world_cell)

	for raw_item in item_cells:
		var item := raw_item as ItemData
		var cells: Array = item_cells[raw_item]
		var c: Color = item.color
		var fill_color := Color(c.r, c.g, c.b, 0.80)
		var border_color := Color(c.r * 0.6, c.g * 0.6, c.b * 0.6, 1.0)

		# 配置セルのバウンディングボックスを求める
		var min_col: int = cells[0].x
		var min_row: int = cells[0].y
		var max_col: int = cells[0].x
		var max_row: int = cells[0].y
		for cell in cells:
			min_col = min(min_col, cell.x)
			min_row = min(min_row, cell.y)
			max_col = max(max_col, cell.x)
			max_row = max(max_row, cell.y)
		var bb_w: int = max_col - min_col + 1
		var bb_h: int = max_row - min_row + 1

		for world_cell in cells:
			var rect := Rect2(
				world_cell.x * cell_size + 1,
				world_cell.y * cell_size + 1,
				cell_size - 2,
				cell_size - 2
			)

			if item.texture:
				var tex_size := item.texture.get_size()
				var local_col: int = world_cell.x - min_col
				var local_row: int = world_cell.y - min_row
				var src_rect := Rect2(
					float(local_col) / float(bb_w) * tex_size.x,
					float(local_row) / float(bb_h) * tex_size.y,
					tex_size.x / float(bb_w),
					tex_size.y / float(bb_h)
				)
				draw_texture_rect_region(item.texture, rect, src_rect)
				draw_rect(rect, border_color, false, 1.5)
			else:
				draw_rect(rect, fill_color)
				draw_rect(rect, border_color, false, 1.5)

			# danger dot（左上）
			for d in range(item.danger):
				var dot_x := float(world_cell.x * cell_size + 10 + d * 14)
				var dot_y := float(world_cell.y * cell_size + 10)
				draw_circle(Vector2(dot_x, dot_y), 5.0, Color(1, 0.3, 0.3, 0.9))


func _draw_preview() -> void:
	if _preview_item == null or _preview_shape.is_empty():
		return
	if _preview_origin.x < 0:
		return

	var color := PREVIEW_OK_COLOR if _preview_valid else PREVIEW_NG_COLOR

	for cell in _preview_shape:
		var world_cell := Vector2i(_preview_origin.x + cell.x, _preview_origin.y + cell.y)
		# グリッド外は描画しない
		if world_cell.x < 0 or world_cell.x >= grid_width:
			continue
		if world_cell.y < 0 or world_cell.y >= grid_height:
			continue

		var rect := Rect2(
			world_cell.x * cell_size + 1,
			world_cell.y * cell_size + 1,
			cell_size - 2,
			cell_size - 2
		)
		draw_rect(rect, color)
		draw_rect(rect, Color(color.r, color.g, color.b, 0.9), false, 2.0)


func _draw_grid_lines() -> void:
	# 縦線
	for col in range(grid_width + 1):
		var x := col * cell_size
		draw_line(Vector2(x, 0), Vector2(x, grid_height * cell_size), BORDER_COLOR, 1.5)
	# 横線
	for row in range(grid_height + 1):
		var y := row * cell_size
		draw_line(Vector2(0, y), Vector2(grid_width * cell_size, y), BORDER_COLOR, 1.5)


# ─── マウス（クリック配置モード用） ────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			# クリック配置モードの確定はMainGameが行う
			# ここではシグナルを出さず、MainGameがset_preview済みのoriginを使う
			pass
