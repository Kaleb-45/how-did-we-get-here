# launch.gd
# Stage 2: Launch. The player cannot move. The rocket has a few launch
# moments, and each one is a timed press with the Space key (or a click).
#   Perfect or Good: no loss.
#   Miss: a cost is added to GameState.damage (lost fuel or a damaged part).
#         A miss never ends the mission.
# The number of moments and how tight the windows are come from the rocket
# the player picked (data/timing.json). The levels change nothing here.
extends Control

@onready var title_label: Label = %Title
@onready var hint_label: Label = %Hint
@onready var timeline: HBoxContainer = %Timeline
@onready var rocket_view: Control = %RocketView
@onready var press: Control = %TimedPress
@onready var summary_box: PanelContainer = %SummaryBox
@onready var summary_title: Label = %SummaryTitle
@onready var summary_lines: VBoxContainer = %SummaryLines
@onready var next_button: Button = %NextButton
@onready var inner_voice: PanelContainer = %InnerVoiceBar

var words: Dictionary             # launch_screen text from story.json
var voice_lines: Dictionary       # "launch" lines from inner_voice.json
var moment_ids: Array = []        # for example ["liftoff", "stage_separation", "engine_cutoff"]
var moment_labels: Array = []     # one Label per moment in the timeline
var tightness: float = 1.0


func _ready() -> void:
	# Safety net for pressing Play on this screen directly.
	if GameState.character_id == "":
		GameState.character_id = Data.game_data["setup"]["default_character"]
	if GameState.mission_id == "":
		GameState.mission_id = Data.missions.keys()[0]
	GameState.fill_default_choices()

	words = Data.story["launch_screen"]
	voice_lines = Data.voice["launch"]
	title_label.text = words["title"]
	hint_label.text = words["hint"]
	next_button.text = words["next_button"]
	next_button.pressed.connect(_on_next_pressed)
	summary_box.visible = false

	# The rocket the player picked sets the moments and the window tightness.
	var rocket: Dictionary = Data.timing["launch_vehicles"][GameState.get_launch_vehicle_id()]
	moment_ids = rocket["moment_ids"]
	tightness = rocket["window_tightness"]

	GameState.start_launch()   # a new launch starts with no damage and no results
	build_timeline()
	rocket_view.set_progress(0, moment_ids.size())
	inner_voice.say(voice_lines["start"])
	run_launch()


# One small label per moment: its name, and its result under it.
func build_timeline() -> void:
	for moment_id in moment_ids:
		var label := Label.new()
		label.theme_type_variation = &"SmallText"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(190, 0)
		label.text = words["moments"][moment_id] + "\n" + words["waiting"]
		timeline.add_child(label)
		moment_labels.append(label)


# Goes through the moments one by one, then shows the summary.
func run_launch() -> void:
	var numbers: Dictionary = Data.timing["launch"]
	for i in moment_ids.size():
		var moment_id: String = moment_ids[i]
		moment_labels[i].theme_type_variation = &"AccentText"   # the current one is orange
		await get_tree().create_timer(numbers["ready_seconds"]).timeout
		press.start(words["moments"][moment_id], 1.0, tightness, press.ACTION_SPACE)
		var result: String = await press.finished

		GameState.record_press("launch", moment_id, result)
		if result == "Miss":
			var cost: Dictionary = Data.timing["launch_moments"][moment_id]["miss_cost"]
			GameState.add_damage(cost["kind"], cost["amount"])
		moment_labels[i].text = words["moments"][moment_id] + "\n" + words["results"][result]
		moment_labels[i].theme_type_variation = &"SmallText"
		rocket_view.set_progress(i + 1, moment_ids.size())
		var lines: Array = voice_lines["results"][result]
		inner_voice.say(lines[i % lines.size()])
		await get_tree().create_timer(numbers["between_seconds"]).timeout
	show_summary()


# After the last moment: no losses, or the list of costs. Then a Next button.
func show_summary() -> void:
	press.visible = false
	summary_title.text = words["summary_title"]
	var any_cost := false
	for entry in GameState.timing_results:
		if entry["result"] != "Miss":
			continue
		any_cost = true
		var cost: Dictionary = Data.timing["launch_moments"][entry["moment"]]["miss_cost"]
		var cost_text: String = words["cost_kinds"][cost["kind"]].format({"amount": GameState.fmt(cost["amount"])})
		add_line(words["cost_line"].format({"moment": words["moments"][entry["moment"]], "cost": cost_text}))
	if any_cost:
		summary_lines.move_child(add_line(words["costs_title"]), 0)
		inner_voice.say(voice_lines["summary_costs"])
	else:
		add_line(words["no_losses"])
		inner_voice.say(voice_lines["summary_clean"])
	summary_box.visible = true
	next_button.grab_focus()


func add_line(text: String) -> Label:
	var line := Label.new()
	line.theme_type_variation = &"SmallText"
	line.text = text
	summary_lines.add_child(line)
	return line


# Lock the button at once, so a double click cannot skip two screens.
func _on_next_pressed() -> void:
	next_button.disabled = true
	StageManager.go_next()
