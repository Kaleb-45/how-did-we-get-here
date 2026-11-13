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


# Makes one row for each part that is allowed at this destination
# (game_data.json "allowed_at"): its name, then a button for each allowed version.
# Mars orbit shows the same three rows as before. A surface trip or Europa shows
# more rows, so the dashboard is made narrower (and with many rows, the name and the buttons sit side by side).
func make_part_rows() -> void:
	show_destination_notes()
	var slots: Array = []
	for part_id in Data.parts:
		if not GameState.get_allowed_versions(part_id).is_empty():
			slots.append(part_id)
	# More than three rows: the dashboard gets narrower so everything fits on screen.
	# More than four rows (a surface trip): the name and the buttons also sit side by side.
	if slots.size() > 3:
		narrow_dashboard()
	var side_by_side: bool = slots.size() > 4

	for part_id in slots:
		var part: Dictionary = Data.parts[part_id]
		var allowed: Array = GameState.get_allowed_versions(part_id)

		var name_label := Label.new()
		name_label.text = GameState.get_part_name(part_id)
		name_label.theme_type_variation = &"HeadingText"   # text style from the theme

		var button_row := HBoxContainer.new()
		button_row.add_theme_constant_override("separation", 12)
		if side_by_side:
			name_label.custom_minimum_size = Vector2(240, 0)
			var line := HBoxContainer.new()
			parts_column.add_child(line)
			line.add_child(name_label)
			line.add_child(button_row)
		else:
			parts_column.add_child(name_label)
			parts_column.add_child(button_row)

		# A ButtonGroup makes the buttons work like radio buttons:
		# pressing one un-presses the others in the same group.
		var group := ButtonGroup.new()

		for version_id in allowed:
			var version: Dictionary = part["versions"][version_id]
			var button := Button.new()
			button.text = version["name"]
			button.toggle_mode = true
			button.button_group = group
			button.custom_minimum_size = Vector2(100, 50)   # at least 100 wide, wider if the text needs it
			button.theme_type_variation = &"SmallButton"
			button.tooltip_text = GameState.effects_text(GameState.get_version_effects(part_id, version_id), "\n")
			button.button_pressed = GameState.choices[part_id] == version_id
			button.pressed.connect(_on_version_picked.bind(part_id, version_id))
			button_row.add_child(button)


# Narrower dashboard rows (sizes in pixels), so the longer parts list and the dashboard fit together.
func narrow_dashboard() -> void:
	for res_id in dashboard.rows:
		var row = dashboard.rows[res_id]
		row.name_label.custom_minimum_size.x = 120
		row.value_label.custom_minimum_size.x = 125
		row.limit_label.custom_minimum_size.x = 125
		row.bar.custom_minimum_size.x = 60


# Far from Mars the parts change (less sunlight, slower radio). Say so (only when something changes).
func show_destination_notes() -> void:
	if is_equal_approx(GameState.get_sunlight_factor(), 1.0) and is_equal_approx(GameState.get_distance_factor(), 1.0):
		return
	var note := Label.new()
	note.text = words["far_note"].format({
		"sun": GameState.fmt(GameState.get_sunlight_factor() * 100.0),
		"far": GameState.fmt(GameState.get_distance_factor() * 100.0),
	})
	note.theme_type_variation = &"SmallText"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(500, 0)
	# The note sits under the dashboard (on the right), so the parts list keeps its height.
	var right_column := VBoxContainer.new()
	right_column.add_theme_constant_override("separation", 16)
	parts_column.get_parent().add_child(right_column)
	dashboard.reparent(right_column)
	right_column.add_child(note)


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
