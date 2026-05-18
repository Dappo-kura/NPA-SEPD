class_name NightmareEvent
extends Panel

## 封印後に表示するナイトメアイベント画面

@onready var text_label: RichTextLabel = $VBoxContainer/TextLabel
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var san_damage_label: Label = $VBoxContainer/SANDamageLabel

signal event_dismissed()

var _san_damage: int = 0


func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue_pressed)


func show_event(nightmare_text: String, san_damage: int) -> void:
	_san_damage = san_damage
	text_label.text = nightmare_text

	if san_damage > 0:
		san_damage_label.text = "SAN -" + str(san_damage)
		san_damage_label.modulate = Color(1.0, 0.3, 0.3)
	else:
		san_damage_label.text = "SANは無事だ"
		san_damage_label.modulate = Color(0.3, 1.0, 0.3)

	visible = true


func _on_continue_pressed() -> void:
	visible = false
	event_dismissed.emit()
