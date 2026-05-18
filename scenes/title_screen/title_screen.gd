class_name TitleScreen
extends Control

@onready var story_button: Button = $ButtonContainer/StoryButton
@onready var infinite_button: Button = $ButtonContainer/InfiniteButton
@onready var gallery_button: Button = $ButtonContainer/GalleryButton
@onready var quit_button: Button = $ButtonContainer/QuitButton


func _ready() -> void:
	AudioManager.play_bgm()
	story_button.pressed.connect(_on_story_pressed)
	infinite_button.pressed.connect(_on_infinite_pressed)
	gallery_button.pressed.connect(_on_gallery_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_story_pressed() -> void:
	AudioManager.play_se("enter")
	GameManager.start_story()
	get_tree().change_scene_to_file("res://scenes/day_intro/day_intro.tscn")


func _on_infinite_pressed() -> void:
	AudioManager.play_se("enter")
	GameManager.start_infinite()
	get_tree().change_scene_to_file("res://scenes/main_game/main_game.tscn")


func _on_gallery_pressed() -> void:
	AudioManager.play_se("enter")
	get_tree().change_scene_to_file("res://scenes/gallery/gallery.tscn")


func _on_quit_pressed() -> void:
	AudioManager.play_se("enter")
	get_tree().quit()
