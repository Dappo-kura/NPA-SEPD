class_name GalleryScreen
extends Control

@onready var grid_container: GridContainer = $ScrollContainer/GridContainer
@onready var back_button: Button = $BackButton
@onready var fullscreen_layer: CanvasLayer = $FullscreenLayer
@onready var fullscreen_image: TextureRect = $FullscreenLayer/FullscreenImage
@onready var fullscreen_title: Label = $FullscreenLayer/TitleLabel
@onready var close_button: Button = $FullscreenLayer/CloseButton

# ロック中に表示するダミーテクスチャ（黒）
var locked_placeholder: ImageTexture


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	close_button.pressed.connect(_on_close_fullscreen)
	fullscreen_layer.visible = false
	_build_locked_placeholder()
	_populate_gallery()


func _build_locked_placeholder() -> void:
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	img.fill(Color(0.1, 0.1, 0.1))
	locked_placeholder = ImageTexture.create_from_image(img)


func _populate_gallery() -> void:
	for day_num in range(1, 22):
		var data := ScenarioManager.get_day(day_num)
		if data.is_empty():
			continue
		var id: int = data.get("event_cg_id", day_num)
		var path: String = data.get("event_cg_path", "")
		var title: String = data.get("gallery_title", "Day %d" % day_num)
		var is_unlocked: bool = SaveManager.is_gallery_unlocked(id)

		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(280, 360)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		panel.add_child(vbox)

		var thumb := TextureRect.new()
		thumb.custom_minimum_size = Vector2(240, 300)
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

		if is_unlocked and path != "" and ResourceLoader.exists(path):
			var tex: Texture2D = load(path)
			thumb.texture = tex
			# タップで全画面表示
			thumb.gui_input.connect(
				func(event: InputEvent) -> void:
					if event is InputEventMouseButton:
						var mb := event as InputEventMouseButton
						if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
							_show_fullscreen(tex, title)
			)
			thumb.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			thumb.texture = locked_placeholder
			thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE

		vbox.add_child(thumb)

		var label := Label.new()
		label.text = title if is_unlocked else "???"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.theme_override_font_sizes = {"font_size": 28}
		vbox.add_child(label)

		grid_container.add_child(panel)


func _show_fullscreen(tex: Texture2D, title: String) -> void:
	fullscreen_image.texture = tex
	fullscreen_title.text = title
	fullscreen_layer.visible = true


func _on_close_fullscreen() -> void:
	fullscreen_layer.visible = false


func _on_back_pressed() -> void:
	AudioManager.play_se("enter")
	get_tree().change_scene_to_file("res://scenes/title_screen/title_screen.tscn")
