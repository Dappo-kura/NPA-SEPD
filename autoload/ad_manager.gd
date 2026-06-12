extends Node

## 広告管理AutoLoad。
## 現状はスタブ実装（デモ広告画面）。リリース時はAdMob等の実SDKに差し替える。
## 差し替え箇所は is_rewarded_ad_available() / show_rewarded() の2つだけ。
##
## AdMob本接続時のメモ:
## - Poing Studios製 Godot AdMob Plugin（AAR）を godot_android_build/libs に追加
## - AndroidManifest.xml に com.google.android.gms.ads.APPLICATION_ID を追加
## - is_rewarded_ad_available() → ロード済みリワード広告の有無を返す
## - show_rewarded() → 実広告を表示し、報酬付与時に callback.call(true)

const STUB_AD_DURATION := 5  # デモ広告の秒数

var _showing := false


## リワード広告が表示可能か（スタブでは常にtrue）
func is_rewarded_ad_available() -> bool:
	return true


## リワード広告を表示する。視聴完了で callback.call(true)、失敗で callback.call(false)
func show_rewarded(callback: Callable) -> void:
	if _showing:
		callback.call(false)
		return
	_show_stub_ad(callback)


# ─── スタブ広告（デモ画面） ─────────────────────────────────
func _show_stub_ad(callback: Callable) -> void:
	_showing = true

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.09, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title := Label.new()
	title.text = "─　広告　─"
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var note := Label.new()
	note.text = "（デモ広告：リリース時にAdMobへ差し替え）"
	note.add_theme_font_size_override("font_size", 28)
	note.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(note)

	var countdown := Label.new()
	countdown.add_theme_font_size_override("font_size", 44)
	countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(countdown)

	var close_button := Button.new()
	close_button.text = "閉じて報酬を受け取る"
	close_button.custom_minimum_size = Vector2(480, 96)
	close_button.add_theme_font_size_override("font_size", 36)
	close_button.visible = false
	vbox.add_child(close_button)

	close_button.pressed.connect(func() -> void:
		layer.queue_free()
		_showing = false
		callback.call(true)
	)

	# カウントダウン（視聴強制）→ 完了後に閉じるボタンを出す
	for i in range(STUB_AD_DURATION, 0, -1):
		countdown.text = "残り %d 秒" % i
		await get_tree().create_timer(1.0).timeout
	countdown.text = "視聴完了"
	close_button.visible = true
