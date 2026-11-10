# build.gd
# The build screen. Left side: one row per part, one button per version.
# Right side: the mission dashboard, updated every time a button is clicked.
# Every part, version and number comes from data/game_data.json.
extends Control

@onready var title_label: Label = %Title
@onready var parts_column: VBoxContainer = %Parts
@onready var dashboard: PanelContainer = %Dashboard
@onready var review_button: Button = %ReviewButton

var words: Dictionary   # the build_screen text from story.json


func _ready() -> void:
	# Safety net: if we press Play on this screen directly, nobody has
	# picked a character or mission yet, so use the first ones in the data.
	if GameState.character_id == "":
		GameState.character_id = Data.game_data["setup"]["default_character"]
	if GameState.mission_id == "":
		GameState.mission_id = Data.missions.keys()[0]

	words = Data.story["build_screen"]
	title_label.text = words["title"]
	review_button.text = words["review_button"]
	review_button.pressed.connect(_on_review_pressed)

	GameState.fill_default_choices()
	make_part_rows()
	refresh_dashboard()


# Makes one row for each part: its name, then a button for each version.
func make_part_rows() -> void:
	for part_id in Data.parts:
		var part: Dictionary = Data.parts[part_id]

		var name_label := Label.new()
		name_label.text = part["name"]
		name_label.theme_type_variation = &"HeadingText"   # text style from the theme
		parts_column.add_child(name_label)

		var button_row := HBoxContainer.new()
		button_row.add_theme_constant_override("separation", 12)
		parts_column.add_child(button_row)

		# A ButtonGroup makes the buttons work like radio buttons:
		# pressing one un-presses the others in the same group.
		var group := ButtonGroup.new()

		for version_id in part["versions"]:
			var version: Dictionary = part["versions"][version_id]
			var button := Button.new()
			button.text = version["name"]
			button.toggle_mode = true
			button.button_group = group
			button.custom_minimum_size = Vector2(100, 50)   # at least 100 wide, wider if the text needs it
			button.theme_type_variation = &"SmallButton"
			button.tooltip_text = GameState.effects_text(version["effects"], "\n")
			button.button_pressed = GameState.choices[part_id] == version_id
			button.pressed.connect(_on_version_picked.bind(part_id, version_id))
			button_row.add_child(button)


# GameState adds up the six totals; the dashboard draws them.
func refresh_dashboard() -> void:
	dashboard.show_values(GameState.get_totals())


# Runs when the player clicks a version button.
func _on_version_picked(part_id: String, version_id: String) -> void:
	GameState.choices[part_id] = version_id
	print("Picked ", part_id, " = ", version_id)
	refresh_dashboard()


func _on_review_pressed() -> void:
	StageManager.go_next()
