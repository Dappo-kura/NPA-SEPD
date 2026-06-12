class_name TitleScreen
extends Control

@onready var story_button: Button = $ButtonContainer/StoryButton
@onready var continue_button: Button = $ButtonContainer/ContinueButton
@onready var infinite_button: Button = $ButtonContainer/InfiniteButton
@onready var gallery_button: Button = $ButtonContainer/GalleryButton
@onready var settings_button: Button = $ButtonContainer/SettingsButton
@onready var quit_button: Button = $ButtonContainer/QuitButton


func _ready() -> void:
	AudioManager.play_bgm()
	story_button.pressed.connect(_on_story_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	infinite_button.pressed.connect(_on_infinite_pressed)
	gallery_button.pressed.connect(_on_gallery_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	# ブラウザでは quit() が無効のためボタンごと隠す
	if OS.has_feature("web"):
		quit_button.visible = false

	# 進行中のストーリーランがあれば「続きから」を表示
	# （その場合ストーリーボタンは「最初から」表記にして上書きを明示する）
	if SaveManager.has_story_run():
		continue_button.text = "続きから（Day %d）" % SaveManager.story_run_day
		continue_button.visible = true
		story_button.text = "最初から（α版）"


func _on_story_pressed() -> void:
	AudioManager.play_se("enter")
	GameManager.start_story()
	get_tree().change_scene_to_file("res://scenes/day_intro/day_intro.tscn")


func _on_continue_pressed() -> void:
	AudioManager.play_se("enter")
	GameManager.continue_story()
	get_tree().change_scene_to_file("res://scenes/day_intro/day_intro.tscn")


func _on_infinite_pressed() -> void:
	AudioManager.play_se("enter")
	GameManager.start_infinite()
	get_tree().change_scene_to_file("res://scenes/main_game/main_game.tscn")


func _on_gallery_pressed() -> void:
	AudioManager.play_se("enter")
	get_tree().change_scene_to_file("res://scenes/gallery/gallery.tscn")


func _on_settings_pressed() -> void:
	AudioManager.play_se("enter")
	get_tree().change_scene_to_file("res://scenes/settings/settings.tscn")


func _on_quit_pressed() -> void:
	AudioManager.play_se("enter")
	get_tree().quit()
