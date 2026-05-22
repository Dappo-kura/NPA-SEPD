class_name ItemTray
extends ScrollContainer

## アイテムトレイ（横スクロール）。同一アイテムの複数表示に対応。

@onready var hbox: HBoxContainer = $HBoxContainer

signal item_drag_started(item: ItemData, shape: Array[Vector2i], screen_pos: Vector2)
signal item_click_selected(item: ItemData, shape: Array[Vector2i])

# 各エントリ: {item: ItemData, visual: ItemVisual, spacer: Control}
var _item_entries: Array = []


func _ready() -> void:
	pass


func populate(items: Array[ItemData]) -> void:
	for child in hbox.get_children():
		child.queue_free()
	_item_entries.clear()
	for item in items:
		_add_item_visual(item)


func _add_item_visual(item: ItemData) -> void:
	var iv := ItemVisual.new()
	iv.setup(item)
	iv.show_danger = true
	iv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	iv.drag_started.connect(_on_item_drag_started)
	iv.item_clicked.connect(_on_item_clicked)
	hbox.add_child(iv)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(8, 0)
	hbox.add_child(spacer)

	_item_entries.append({"item": item, "visual": iv, "spacer": spacer})


## 同一アイテムが複数ある場合は最初の1つだけ削除する
func remove_item(item: ItemData) -> void:
	for i in range(_item_entries.size()):
		if _item_entries[i]["item"] == item:
			_item_entries[i]["visual"].queue_free()
			_item_entries[i]["spacer"].queue_free()
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
