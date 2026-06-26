class_name ItemVisual
extends Control

## アイテムの形状を描画し、ドラッグ開始シグナルを発行するコンポーネント。
## トレイ内・ドラッグゴースト・図鑑プレビューのいずれでも使用する。

const DEFAULT_CELL_SIZE: int = 120
const MIN_CELL_SIZE: int = 32

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
var is_selected: bool = false     # trueのとき選択ハイライトを描画
var display_cell_size: int = DEFAULT_CELL_SIZE:
	set(v):
		display_cell_size = max(MIN_CELL_SIZE, v)
		_recalculate_size()
		queue_redraw()

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
		custom_minimum_size = Vector2(display_cell_size, display_cell_size)
		return
	var bb := item_data.get_bounding_box(current_shape)
	custom_minimum_size = Vector2(bb.x * display_cell_size, bb.y * display_cell_size)
	size = custom_minimum_size


func _draw() -> void:
	if item_data == null or current_shape.is_empty():
		return

	var base_color := item_data.color
	var fill_color := Color(base_color.r, base_color.g, base_color.b,
			0.78 if is_ghost else 0.96)
	var outer_border := Color(0.02, 0.02, 0.025, 0.90 if is_ghost else 1.0)
	var inner_border := Color(1.0, 0.84, 0.45, 0.72 if is_ghost else 0.95)
	var bb := item_data.get_bounding_box(current_shape)
	var border_width: float = maxf(1.5, float(display_cell_size) * 0.045)
	var inset: float = maxf(1.0, float(display_cell_size) * 0.025)

	for cell in current_shape:
		var rect := Rect2(
			cell.x * display_cell_size + inset,
			cell.y * display_cell_size + inset,
			display_cell_size - inset * 2.0,
			display_cell_size - inset * 2.0
		)
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.34))
		if item_data.texture:
			_draw_texture_cell(item_data.texture, cell, rect.grow(-border_width), bb,
					Color(1.0, 1.0, 1.0, 0.82 if is_ghost else 1.0))
			draw_rect(rect, Color(base_color.r, base_color.g, base_color.b,
					0.18 if is_ghost else 0.24))
		else:
			draw_rect(rect.grow(-border_width), fill_color)
		draw_rect(rect, outer_border, false, border_width)
		draw_rect(rect.grow(-border_width), inner_border, false, max(1.0, border_width * 0.55))

	if show_danger and item_data.danger > 0:
		_draw_danger_badge()

	if is_selected:
		var outline := Rect2(-5, -5, bb.x * display_cell_size + 10, bb.y * display_cell_size + 10)
		draw_rect(outline, Color(1.0, 0.85, 0.1, 0.95), false, 4.0)


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


func _draw_danger_badge() -> void:
	# 未収納時のSANダメージ（= セル数 × danger）を表示する。
	# danger単体ではなく実ダメージ値にすることで盤面の損失が直感的に分かる。
	var damage: int = item_data.shape.size() * maxi(1, item_data.danger)
	var label := str(damage)
	var font_size: int = maxi(18, int(float(display_cell_size) * 0.34))
	var badge_size := Vector2(float(font_size) * (0.70 + 0.55 * label.length()),
			float(font_size) * 1.20)
	var badge_rect := Rect2(Vector2(4, 4), badge_size)
	draw_rect(badge_rect, Color(0.08, 0.0, 0.0, 0.86))
	draw_rect(badge_rect, Color(1.0, 0.25, 0.18, 0.95), false, 1.5)
	draw_string(ThemeDB.fallback_font, badge_rect.position + Vector2(6, badge_size.y - 6),
			label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			Color.WHITE)


# ─── マウスイベント ─────────────────────────────────────────────
var _drag_threshold: float = 16.0
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
