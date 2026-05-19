extends Node

var _days: Dictionary = {}
var _case_files: Dictionary = {}


func _ready() -> void:
	_load_json("res://resources/scenarios/day_scenarios.json", _days)
	_load_json("res://resources/scenarios/case_files.json", _case_files)


func _load_json(path: String, target: Dictionary) -> void:
	if not FileAccess.file_exists(path):
		push_error("ScenarioManager: JSON not found: " + path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ScenarioManager: Cannot open JSON")
		return
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		push_error("ScenarioManager: JSON parse failed: " + path)
		return
	for day_data in parsed.get("days", []):
		target[int(day_data.get("day", 0))] = day_data


## day 番号に対応するシナリオデータを返す。存在しない場合は空の Dictionary。
func get_day(day: int) -> Dictionary:
	return _days.get(day, {})


## day 番号に対応する事件資料データを返す。存在しない場合は空の Dictionary。
func get_case_file(day: int) -> Dictionary:
	return _case_files.get(day, {})
