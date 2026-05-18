extends Node

var _days: Dictionary = {}


func _ready() -> void:
	_load_json()


func _load_json() -> void:
	var path := "res://resources/scenarios/day_scenarios.json"
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
		push_error("ScenarioManager: JSON parse failed")
		return
	for day_data in parsed.get("days", []):
		_days[int(day_data.get("day", 0))] = day_data


## day 番号に対応するシナリオデータを返す。存在しない場合は空の Dictionary。
func get_day(day: int) -> Dictionary:
	return _days.get(day, {})
