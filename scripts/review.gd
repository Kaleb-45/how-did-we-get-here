# review.gd
# The review screen: a table of the six resources, with each one marked
# OK (green) or a problem (red). The inner voice comments at the bottom.
extends Control

const OK_COLOR := Color(0.45, 0.9, 0.55)
const BAD_COLOR := Color(1, 0.38, 0.38)

@onready var title_label: Label = %Title
@onready var table: GridContainer = %Table
@onready var back_button: Button = %BackButton
@onready var launch_button: Button = %LaunchButton
@onready var inner_voice: PanelContainer = %InnerVoiceBar

var words: Dictionary   # the review_screen text from story.json


func _ready() -> void:
	# Safety net for pressing Play on this screen directly.
	if GameState.character_id == "":
		GameState.character_id = Data.game_data["setup"]["default_character"]
	if GameState.mission_id == "":
		GameState.mission_id = Data.missions.keys()[0]
	GameState.fill_default_choices()

	words = Data.story["review_screen"]
	title_label.text = words["title"]
	back_button.text = words["back_button"]
	launch_button.text = words["launch_button"]
	back_button.pressed.connect(_on_back_pressed)
	launch_button.pressed.connect(_on_launch_pressed)

	fill_table()
	inner_voice_comment()


# The table has 4 columns. A GridContainer fills cells left to right,
# then starts a new row, so we just add 4 labels per row.
func fill_table() -> void:
	# Header row
	for key in ["header_resource", "header_have", "header_limit", "header_status"]:
		add_cell(words[key], get_theme_color("font_color", &"AccentText"))   # orange, from the theme

	var totals: Dictionary = GameState.get_totals()
	var limits: Dictionary = GameState.get_limits()

	# One row per resource
	for res_id in Data.resources:
		var resource: Dictionary = Data.resources[res_id]
		var limit: Dictionary = limits[res_id]
		var ok: bool = GameState.is_ok(totals[res_id], limit)
		var rule_word: String = Data.story["build_screen"]["max_word"] if limit["rule"] == "max" else Data.story["build_screen"]["min_word"]

		var status: String = words["ok_word"]
		if not ok:
			status = words["over_word"] if limit["rule"] == "max" else words["under_word"]
		var color: Color = OK_COLOR if ok else BAD_COLOR

		add_cell(resource["name"], color)
		add_cell(GameState.fmt(totals[res_id]) + " " + resource["unit"], color)
		add_cell(rule_word + " " + GameState.fmt(limit["value"]), Color.WHITE)
		add_cell(status, color)


func add_cell(text: String, color: Color) -> void:
	var cell := Label.new()
	cell.text = text
	cell.theme_type_variation = &"BodyText"
	cell.add_theme_color_override("font_color", color)
	table.add_child(cell)


# What the inner voice says about this build.
func inner_voice_comment() -> void:
	var failed: Array = GameState.get_failed_resources()
	if failed.is_empty():
		inner_voice.say(Data.voice["review"]["all_good"])
	else:
		# "Something is in the red..." plus the first problem, with numbers filled in.
		var first: String = failed[0]
		var what: String = GameState.fill_blanks(Data.voice["resource_failures"][first]["what"], first)
		inner_voice.say(Data.voice["review"]["some_over"] + " " + what)


func _on_back_pressed() -> void:
	StageManager.go_to("build")   # Back goes to Build


func _on_launch_pressed() -> void:
	# Launch = go walk around the spacecraft in 3D.
	StageManager.go_next()
