extends Node

# セーブファイルパス
const SAVE_PATH := "user://save.json"

# セーブデータ構造
var story_cleared_days: int = 0          # ストーリーモードでクリアした最大日数
var gallery_unlocked: Array[int] = []    # アンロック済みギャラリーID (event番号)
var infinite_best_wave: int = 0          # 無限モードのベストウェーブ数

# ─── 初期化 ───────────────────────────────────────────────
func _ready() -> void:
	load_data()


# ─── セーブ ───────────────────────────────────────────────
func save_data() -> void:
	var data := {
		"story_cleared_days": story_cleared_days,
		"gallery_unlocked": gallery_unlocked,
		"infinite_best_wave": infinite_best_wave,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: セーブファイルを開けませんでした")
		return
	file.store_string(JSON.stringify(data))
	file.close()


# ─── ロード ───────────────────────────────────────────────
func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		push_warning("SaveManager: セーブデータのパースに失敗しました")
		return

	story_cleared_days = parsed.get("story_cleared_days", 0)
	infinite_best_wave = parsed.get("infinite_best_wave", 0)

	var raw_gallery = parsed.get("gallery_unlocked", [])
	gallery_unlocked.clear()
	for v in raw_gallery:
		gallery_unlocked.append(int(v))


# ─── ストーリー進行更新 ────────────────────────────────────
## ストーリーモードで day をクリアした時に呼ぶ
func on_story_day_cleared(day: int) -> void:
	if day > story_cleared_days:
		story_cleared_days = day
	# day に対応するイベント画像をアンロック
	if day not in gallery_unlocked:
		gallery_unlocked.append(day)
		gallery_unlocked.sort()
	save_data()


# ─── 無限モードスコア更新 ──────────────────────────────────
func on_infinite_wave_cleared(wave: int) -> void:
	if wave > infinite_best_wave:
		infinite_best_wave = wave
		save_data()


# ─── ギャラリー判定 ───────────────────────────────────────
func is_gallery_unlocked(event_id: int) -> bool:
	return event_id in gallery_unlocked
