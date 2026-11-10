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
func go_next() -> void:
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


# Wait a few seconds, then go to the next screen. The setup questions use
# this: the inner voice reacts to the answer, and then the next question
# appears. The wait time is in game_data.json ("setup" / "reaction_seconds").
func go_next_after_reaction() -> void:
	await get_tree().create_timer(Data.game_data["setup"]["reaction_seconds"]).timeout
	go_next()
