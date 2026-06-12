extends Node

# セーブファイルパス
const SAVE_PATH := "user://save.json"

# セーブデータ構造
var story_cleared_days: int = 0          # ストーリーモードでクリアした最大日数
var gallery_unlocked: Array[int] = []    # アンロック済みギャラリーID (event番号)
var infinite_best_wave: int = 0          # 無限モードのベストウェーブ数

# 進行中のストーリーラン（「続きから」用）。day 0 = ランなし
var story_run_day: int = 0
var story_run_san: int = 100

# 音量設定（0.0〜1.0）
var bgm_volume: float = 1.0
var se_volume: float = 1.0

# ─── 初期化 ───────────────────────────────────────────────
func _ready() -> void:
	load_data()
	# AutoLoad順は AudioManager → SaveManager なのでここから音量を反映する
	AudioManager.set_bgm_volume(bgm_volume)
	AudioManager.set_se_volume(se_volume)


# ─── セーブ ───────────────────────────────────────────────
func save_data() -> void:
	var data := {
		"story_cleared_days": story_cleared_days,
		"gallery_unlocked": gallery_unlocked,
		"infinite_best_wave": infinite_best_wave,
		"story_run_day": story_run_day,
		"story_run_san": story_run_san,
		"bgm_volume": bgm_volume,
		"se_volume": se_volume,
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
	story_run_day = int(parsed.get("story_run_day", 0))
	story_run_san = int(parsed.get("story_run_san", 100))
	bgm_volume = clampf(parsed.get("bgm_volume", 1.0), 0.0, 1.0)
	se_volume = clampf(parsed.get("se_volume", 1.0), 0.0, 1.0)

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


# ─── 進行中ストーリーラン（「続きから」） ──────────────────
## 各Day開始時に呼び、Day番号とその時点のSANを記録する
func save_story_run(day: int, san: int) -> void:
	story_run_day = day
	story_run_san = san
	save_data()


## ゲームオーバー・クリア時に呼び、進行中ランを消す
func clear_story_run() -> void:
	story_run_day = 0
	story_run_san = 100
	save_data()


func has_story_run() -> bool:
	return story_run_day >= 1


# ─── 音量設定 ─────────────────────────────────────────────
func save_volume_settings(bgm: float, se: float) -> void:
	bgm_volume = clampf(bgm, 0.0, 1.0)
	se_volume = clampf(se, 0.0, 1.0)
	save_data()
