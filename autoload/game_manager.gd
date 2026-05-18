extends Node

# ─── 定数 ─────────────────────────────────────────────────────
const MODE_STORY := "story"
const MODE_INFINITE := "infinite"

# ─── 状態変数 ───────────────────────────────────────────────
var game_mode: String = MODE_STORY
var current_day: int = 1
var san_value: int = 100
var stages: Array[StageData] = []
var unplaced_items: Array[ItemData] = []   # トレイにあるアイテム
var carried_items: Array[ItemData] = []    # グリッドに配置済みアイテム（封印前）

# 無限モード用
var infinite_wave: int = 0                # 現在のウェーブ数（1始まり）

# 現在アクティブなステージ（story/infinite 共通で参照可能）
var active_stage: StageData = null

# ─── シグナル ─────────────────────────────────────────────────
signal san_changed(new_value: int)
signal day_changed(new_day: int)
signal game_over()
signal game_cleared()

# ─── 初期化 ───────────────────────────────────────────────────
func _ready() -> void:
	_load_stages()


func _load_stages() -> void:
	stages.clear()
	for i in range(1, 22):
		var path := "res://resources/stages/day_%02d.tres" % i
		if ResourceLoader.exists(path):
			var s: StageData = load(path)
			stages.append(s)


# ─── ゲームフロー ─────────────────────────────────────────────
func start_story() -> void:
	game_mode = MODE_STORY
	current_day = 1
	san_value = 100
	unplaced_items.clear()
	carried_items.clear()
	_setup_day()


func start_infinite() -> void:
	game_mode = MODE_INFINITE
	infinite_wave = 0
	san_value = 100
	unplaced_items.clear()
	carried_items.clear()
	_setup_infinite_wave()


## 後方互換: 旧 start_game() を story 開始として維持
func start_game() -> void:
	start_story()


func _setup_day() -> void:
	unplaced_items.clear()
	active_stage = get_current_stage()
	if active_stage == null:
		return
	for item in active_stage.available_items:
		unplaced_items.append(item)
	day_changed.emit(current_day)


func _setup_infinite_wave() -> void:
	infinite_wave += 1
	unplaced_items.clear()
	carried_items.clear()
	# ステージをランダムに選択してウェーブとして使用
	if stages.is_empty():
		return
	var idx := randi() % stages.size()
	active_stage = stages[idx]
	for item in active_stage.available_items:
		unplaced_items.append(item)
	# 無限モードではウェーブ番号を day_changed で通知（HUD流用）
	day_changed.emit(infinite_wave)


func advance_day() -> void:
	if game_mode == MODE_INFINITE:
		SaveManager.on_infinite_wave_cleared(infinite_wave)
		_setup_infinite_wave()
		return
	# ストーリーモード
	SaveManager.on_story_day_cleared(current_day)
	if current_day >= stages.size():
		game_cleared.emit()
		return
	current_day += 1
	carried_items.clear()
	_setup_day()


func reset_game() -> void:
	if game_mode == MODE_INFINITE:
		start_infinite()
	else:
		start_story()


# ─── SAN 管理 ─────────────────────────────────────────────────
func apply_san_damage(amount: int) -> void:
	san_value = max(0, san_value - amount)
	san_changed.emit(san_value)
	if san_value <= 0:
		game_over.emit()


func heal_san(amount: int) -> void:
	san_value = min(100, san_value + amount)
	san_changed.emit(san_value)


## グリッドに残った未封印アイテムのSANダメージを計算する
## 1セル未配置 = 1ダメージ
## items: Array of {item: ItemData, cell_count: int}
func calculate_total_san_damage(item_records: Array) -> int:
	var total := 0
	for rec in item_records:
		var cell_count: int = rec["cell_count"]
		total += cell_count
	return total


# ─── アクセサ ─────────────────────────────────────────────────
func get_current_stage() -> StageData:
	var idx := current_day - 1
	if idx < 0 or idx >= stages.size():
		return null
	return stages[idx]


func get_san_ratio() -> float:
	return float(san_value) / 100.0


## day番号に応じた制限時間（秒）を返す。0 = 時間制限なし
func get_time_limit() -> float:
	var day := current_day if game_mode == MODE_STORY else infinite_wave
	if game_mode == MODE_STORY:
		if day <= 2: return 0.0    # チュートリアル
		if day <= 4: return 60.0
		if day <= 10: return 90.0
		if day <= 15: return 80.0
		return 120.0
	else:
		# 無限モード: ウェーブが進むほど短くなる
		var base := 90.0 - (day - 1) * 3.0
		return max(30.0, base)
