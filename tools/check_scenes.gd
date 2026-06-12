extends SceneTree

func _initialize() -> void:
	var scenes := [
		"res://scenes/title_screen/title_screen.tscn",
		"res://scenes/settings/settings.tscn",
		"res://scenes/main_game/main_game.tscn",
	]
	var failed := false
	for path in scenes:
		var packed: PackedScene = load(path)
		if packed == null:
			print("LOAD FAIL: ", path)
			failed = true
			continue
		var inst := packed.instantiate()
		if inst == null:
			print("INSTANTIATE FAIL: ", path)
			failed = true
			continue
		root.add_child(inst)
		await process_frame  # _ready を走らせて @onready 欠落を検出
		inst.queue_free()
		await process_frame
		print("OK: ", path)
	print("RESULT: ", "FAILED" if failed else "ALL_OK")
	quit()
