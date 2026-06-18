class_name ItemTray
extends ScrollContainer

## アイテムトレイ（3列グリッドの縦スクロール）。同一アイテムの複数表示に対応。

const TRAY_COLUMNS: int = 3
const TRAY_CELL_SIZE: int = 58
const TRAY_SLOT_SIZE: Vector2 = Vector2(300, 196)

@onready var grid: GridContainer = $MarginContainer/GridContainer

signal item_drag_started(item: ItemData, shape: Array[Vector2i], screen_pos: Vector2)
signal item_click_selected(item: ItemData, shape: Array[Vector2i])

# 各エントリ: {item: ItemData, visual: ItemVisual, slot: PanelContainer}
var _item_entries: Array = []


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	grid.columns = TRAY_COLUMNS


func populate(items: Array[ItemData]) -> void:
	for child in grid.get_children():
		child.queue_free()
	_item_entries.clear()
	for item in items:
		_add_item_visual(item)


func _add_item_visual(item: ItemData) -> void:
	var slot := _create_slot()
	var iv := ItemVisual.new()
	iv.setup(item)
	iv.display_cell_size = TRAY_CELL_SIZE
	iv.show_danger = true
	iv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	iv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	iv.drag_started.connect(_on_item_drag_started)
	iv.item_clicked.connect(_on_item_clicked)
	slot.add_child(iv)
	grid.add_child(slot)

	_item_entries.append({"item": item, "visual": iv, "slot": slot})


func _create_slot() -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = TRAY_SLOT_SIZE
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.014, 0.018, 0.70)
	style.border_color = Color(0.72, 0.54, 0.30, 0.62)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	slot.add_theme_stylebox_override("panel", style)
	return slot


## 同一アイテムが複数ある場合は最初の1つだけ削除する
func remove_item(item: ItemData) -> void:
	for i in range(_item_entries.size()):
		if _item_entries[i]["item"] == item:
			_item_entries[i]["slot"].queue_free()
			_item_entries.remove_at(i)
			return


func restore_item(item: ItemData) -> void:
	_add_item_visual(item)


## トレイ内のピースをその場で回転する
func rotate_item(item: ItemData) -> void:
	for entry in _item_entries:
		if entry["item"] == item:
			var iv := entry["visual"] as ItemVisual
			var new_shape := item.get_rotated_shape(iv.current_shape)
			iv.set_shape(new_shape)
			return


## 指定アイテムのビジュアル形状を外部から設定する（回転後の同期用）
func update_item_shape(item: ItemData, shape: Array[Vector2i]) -> void:
	for entry in _item_entries:
		if entry["item"] == item:
			(entry["visual"] as ItemVisual).set_shape(shape)
			return


## 指定アイテムを選択状態にする（他はすべて解除）
func select_item(item: ItemData) -> void:
	for entry in _item_entries:
		var iv := entry["visual"] as ItemVisual
		iv.is_selected = entry["item"] == item
		iv.queue_redraw()


## 全アイテムの選択状態を解除する
func deselect_all() -> void:
	for entry in _item_entries:
		var iv := entry["visual"] as ItemVisual
		if iv.is_selected:
			iv.is_selected = false
			iv.queue_redraw()


func _on_item_drag_started(item: ItemData, shape: Array[Vector2i], screen_pos: Vector2) -> void:
	item_drag_started.emit(item, shape, screen_pos)


func _on_item_clicked(item: ItemData, shape: Array[Vector2i]) -> void:
	item_click_selected.emit(item, shape)
