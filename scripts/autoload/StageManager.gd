# StageManager.gd
# Moves the player from one screen to the next. It is an autoload,
# so any script can call it by name, for example:  StageManager.go_next()
#
# The screen order is NOT in this file. It lives in data/game_data.json
# under "stages". To change the order, change that list.
extends Node


# The id of the screen we are on now, for example "build".
# It is the scene's file name without ".tscn".
func get_current() -> String:
	return get_tree().current_scene.scene_file_path.get_file().get_basename()


# Go to the next screen in the list.
# If this screen ends with a checkpoint (game_data.json, stages -> checkpoints),
# the whole game state is saved first.
func go_next() -> void:
	GameState.save_checkpoint_after(get_current())
	var order: Array = Data.game_data["stages"]["order"]
	var next_index: int = order.find(get_current()) + 1
	if next_index <= 0 or next_index >= order.size():
		push_error("StageManager: there is no screen after '" + get_current() + "'")
		return
	go_to(order[next_index])


# Go to one named screen, for example go_to("build").
# Used by the Back button and by Try again.
func go_to(stage_id: String) -> void:
	var stages: Dictionary = Data.game_data["stages"]
	if not stages["order"].has(stage_id):
		push_error("StageManager: '" + stage_id + "' is not in the stages list")
		return
	get_tree().change_scene_to_file(stages["scene_folder"] + stage_id + ".tscn")


# "Retry from checkpoint": put the newest checkpoint back and go to the screen
# AFTER the one that saved it (for example checkpoint 3 -> the orbit burn).
# Gives false if there is no checkpoint yet.
func retry_from_checkpoint() -> bool:
	var number: int = GameState.get_latest_checkpoint()
	if number == 0 or not GameState.load_checkpoint(number):
		return false
	var order: Array = Data.game_data["stages"]["order"]
	var saved_when_leaving: Dictionary = Data.game_data["stages"]["checkpoints"]["saved_when_leaving"]
	for stage_id in saved_when_leaving:
		if int(saved_when_leaving[stage_id]) == number:
			go_to(order[order.find(stage_id) + 1])
			return true
	return false
