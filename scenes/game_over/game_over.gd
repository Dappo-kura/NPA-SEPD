extends Control

@onready var return_button: Button = $VBoxContainer/ReturnButton


func _ready() -> void:
	return_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/title_screen/title_screen.tscn")
	)
