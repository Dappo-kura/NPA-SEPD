class_name ItemVisual
extends Control

## アイテムの形状を描画し、ドラッグ開始シグナルを発行するコンポーネント。
## トレイ内・ドラッグゴースト・図鑑プレビューのいずれでも使用する。

const CELL_SIZE: int = 120
const BORDER_WIDTH: float = 1.5

@export var item_data: ItemData = null:
	set(v):
		item_data = v
		if v:
			current_shape.assign(v.shape)
		else:
			current_shape.clear()
		_recalculate_size()
		queue_redraw()

var current_shape: Array[Vector2i] = []
var is_ghost: bool = false        # trueのときは半透明で描画
var show_danger: bool = false     # danger数値を表示するか

signal drag_started(item: ItemData, shape: Array[Vector2i], screen_pos: Vector2)
signal item_clicked(item: ItemData, shape: Array[Vector2i])


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup(data: ItemData, ghost: bool = false) -> void:
	is_ghost = ghost
	item_data = data  # セッターが current_shape の代入と redraw を処理する


func set_shape(shape: Array[Vector2i]) -> void:
	current_shape = shape
	_recalculate_size()
	queue_redraw()


func _recalculate_size() -> void:
	if item_data == null or current_shape.is_empty():
		custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		return
	var bb := item_data.get_bounding_box(current_shape)
	custom_minimum_size = Vector2(bb.x * CELL_SIZE, bb.y * CELL_SIZE)
	size = custom_minimum_size


func _draw() -> void:
	if item_data == null or current_shape.is_empty():
		return

	var base_color := item_data.color
	var fill_color := Color(base_color.r, base_color.g, base_color.b,
			0.55 if is_ghost else 0.85)
	var border_color := Color(base_color.r * 0.6, base_color.g * 0.6, base_color.b * 0.6,
			0.7 if is_ghost else 1.0)

	if item_data.texture:
		var bb := item_data.get_bounding_box(current_shape)
		var tex_alpha := 0.55 if is_ghost else 1.0
		# テクスチャをバウンディングボックス全体に1枚描画（セルでマスクしない）
		var full_rect := Rect2(Vector2.ZERO, Vector2(bb.x * CELL_SIZE, bb.y * CELL_SIZE))
		draw_texture_rect(item_data.texture, full_rect, false, Color(1.0, 1.0, 1.0, tex_alpha))
		for cell in current_shape:
			var dest_rect := Rect2(
				cell.x * CELL_SIZE + 1,
				cell.y * CELL_SIZE + 1,
				CELL_SIZE - 2,
				CELL_SIZE - 2
			)
			draw_rect(dest_rect, border_color, false, BORDER_WIDTH)
	else:
		for cell in current_shape:
			var rect := Rect2(
				cell.x * CELL_SIZE + 1,
				cell.y * CELL_SIZE + 1,
				CELL_SIZE - 2,
				CELL_SIZE - 2
			)
			draw_rect(rect, fill_color)
			draw_rect(rect, border_color, false, BORDER_WIDTH)

	if show_danger and item_data.danger > 0:
		var label_pos := Vector2(4, 4)
		draw_string(ThemeDB.fallback_font, label_pos,
				str(item_data.danger), HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
				Color.WHITE)


# ─── マウスイベント ─────────────────────────────────────────────
var _drag_threshold: float = 6.0
var _mouse_down: bool = false
var _mouse_down_pos: Vector2 = Vector2.ZERO
var _dragging: bool = false


func _gui_input(event: InputEvent) -> void:
	if item_data == null:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_mouse_down = true
				_dragging = false
				_mouse_down_pos = mb.global_position
			else:
				if _mouse_down and not _dragging:
					# クリック確定
					item_clicked.emit(item_data, current_shape.duplicate())
				_mouse_down = false
				_dragging = false

	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _mouse_down and not _dragging:
			var dist := (mm.global_position - _mouse_down_pos).length()
			if dist >= _drag_threshold:
				_dragging = true
				_mouse_down = false
				drag_started.emit(item_data, current_shape.duplicate(), mm.global_position)
