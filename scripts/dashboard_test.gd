# dashboard_test.gd
# A test bench: shows the dashboard by itself, with the values from
# GameState. Run this scene with Cmd+R to check the dashboard alone.
extends Control

@onready var dashboard: PanelContainer = %Dashboard


func _ready() -> void:
	# Nobody picked anything yet, so use the first character, mission
	# and part versions from the data files.
	if GameState.character_id == "":
		GameState.character_id = Data.game_data["setup"]["default_character"]
	if GameState.mission_id == "":
		GameState.mission_id = Data.missions.keys()[0]
	GameState.fill_default_choices()

	dashboard.show_values(GameState.get_totals())
