extends Control

const FONT_PATH := "res://resources/fonts/HGRME.TTC"

@onready var title_label: Label = $ScrollContainer/OuterMargin/Content/TitleLabel
@onready var case_id_label: Label = $ScrollContainer/OuterMargin/Content/CaseIDLabel
@onready var evidence_label: Label = $ScrollContainer/OuterMargin/Content/EvidenceLabel
@onready var overview_text: Label = $ScrollContainer/OuterMargin/Content/OverviewText
@onready var note_text: Label = $ScrollContainer/OuterMargin/Content/NoteText

func _ready() -> void:
	_apply_font()
	var day := GameManager.current_day
	var data := ScenarioManager.get_case_file(day)
	var case_title: String = data.get("case_title", "")
	title_label.text = "【事件資料】　" + case_title
	case_id_label.text = "管理番号：" + data.get("case_id", "")
	evidence_label.text = "搬入物：" + data.get("evidence_items", "")
	overview_text.text = data.get("overview", "")
	note_text.text = data.get("preservation_note", "")

func _apply_font() -> void:
	if not ResourceLoader.exists(FONT_PATH):
		return
	var font: FontFile = load(FONT_PATH)
	title_label.add_theme_font_override("font", font)
	case_id_label.add_theme_font_override("font", font)
	evidence_label.add_theme_font_override("font", font)
	overview_text.add_theme_font_override("font", font)
	note_text.add_theme_font_override("font", font)

func _input(event: InputEvent) -> void:
	var tapped := false
	if event is InputEventScreenTouch:
		if (event as InputEventScreenTouch).pressed:
			tapped = true
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			tapped = true
	if tapped:
		AudioManager.play_se("enter")
		get_tree().change_scene_to_file("res://scenes/main_game/main_game.tscn")
