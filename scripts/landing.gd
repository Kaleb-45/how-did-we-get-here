# landing.gd
# Stage 4 for a SURFACE destination (Jezero, Gale, Arcadia): the landing.
# The player cannot move, so it works like the Launch: a chain of timed
# presses with the SPACE key (or a click):
#   heat shield off, parachute out, landing engine on, touchdown.
#   Perfect or Good: no loss.
#   Miss: a cost is added to GameState.damage (lost fuel, a damaged part, or
#         distance from the target). A miss never ends the mission.
# The presses and costs are in data/timing.json ("landing", "landing_moments").
# Each site also has a landing_window_tightness in data/destinations.json.
# NOTE: we do NOT call GameState.start_launch() here, because it would erase
# the damage from the launch.
extends Control

@onready var title_label: Label = %Title
@onready var hint_label: Label = %Hint
@onready var timeline: HBoxContainer = %Timeline
@onready var press: Control = %TimedPress
@onready var summary_box: PanelContainer = %SummaryBox
@onready var summary_title: Label = %SummaryTitle
@onready var summary_lines: VBoxContainer = %SummaryLines
@onready var next_button: Button = %NextButton
@onready var inner_voice: PanelContainer = %InnerVoiceBar

var words: Dictionary             # "landing_screen" from story.json
var voice_lines: Dictionary       # "landing" from inner_voice.json
var moment_ids: Array = []
var moment_labels: Array = []     # one Label per moment in the timeline
var tightness: float = 1.0
var result_counts: Dictionary = {}   # how many Perfect / Good / Miss so far


func _ready() -> void:
	# Safety net for pressing Play on this screen directly.
	if GameState.character_id == "":
		GameState.character_id = Data.game_data["setup"]["default_character"]
	if GameState.mission_id == "":
		GameState.mission_id = Data.missions.keys()[0]
	GameState.fill_default_choices()

	words = Data.story["landing_screen"]
	voice_lines = Data.voice["landing"]
	title_label.text = words["title"]
	hint_label.text = words["hint"]
	next_button.text = words["next_button"]
	next_button.pressed.connect(_on_next_pressed)
	summary_box.visible = false

	var numbers: Dictionary = Data.timing["landing"]
	moment_ids = numbers["moment_ids"]
	# The press tightness times the site's own tightness (a rough site is harder).
	var site: Dictionary = GameState.get_destination()
	var site_tightness: float = float(site.get("landing_window_tightness", {}).get("value", 1.0))
	tightness = float(numbers["press_tightness"]["value"]) * site_tightness

	build_timeline()
	inner_voice.say(voice_lines["start"])
	run_landing()


# One small label per moment: its name, and its result under it.
func build_timeline() -> void:
	for moment_id in moment_ids:
		var label := Label.new()
		label.theme_type_variation = &"SmallText"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(200, 0)
		label.text = words["moments"][moment_id] + "\n" + words["waiting"]
		timeline.add_child(label)
		moment_labels.append(label)


# Goes through the moments one by one, then shows the summary.
func run_landing() -> void:
	var numbers: Dictionary = Data.timing["landing"]
	for i in moment_ids.size():
		var moment_id: String = moment_ids[i]
		moment_labels[i].theme_type_variation = &"AccentText"   # the current one is orange
		press.show_waiting(words["get_ready"])
		await get_tree().create_timer(numbers["ready_seconds"]["value"]).timeout
		press.start(words["moments"][moment_id], numbers["press_speed"]["value"], tightness, press.ACTION_SPACE)
		var result: String = await press.finished

		GameState.record_press("landing", moment_id, result)
		if result == "Miss":
			var cost: Dictionary = Data.timing["landing_moments"][moment_id]["miss_cost"]
			GameState.add_damage(cost["kind"], cost["amount"])
		moment_labels[i].text = words["moments"][moment_id] + "\n" + words["results"][result]
		moment_labels[i].theme_type_variation = &"SmallText"
		# Use a count for each result type, so "Perfect again!" never comes first.
		var lines: Array = voice_lines["results"][result]
		inner_voice.say(lines[result_counts.get(result, 0) % lines.size()])
		result_counts[result] = result_counts.get(result, 0) + 1
		if i + 1 < moment_ids.size():
			press.show_waiting(words["get_ready"])
		await get_tree().create_timer(numbers["between_seconds"]["value"]).timeout
	show_summary()


# After the last moment: no losses, or the list of costs. Then a Next button.
func show_summary() -> void:
	press.visible = false
	summary_title.text = words["summary_title"]
	var any_cost := false
	for entry in GameState.timing_results:
		if entry["stage"] != "landing" or entry["result"] != "Miss":
			continue
		any_cost = true
		var cost: Dictionary = Data.timing["landing_moments"][entry["moment"]]["miss_cost"]
		var cost_text: String = Data.story["launch_screen"]["cost_kinds"][cost["kind"]].format({"amount": GameState.fmt(cost["amount"])})
		add_line(words["cost_line"].format({"moment": words["moments"][entry["moment"]], "cost": cost_text}))
	if any_cost:
		summary_lines.move_child(add_line(words["costs_title"]), 0)
		inner_voice.say(voice_lines["summary_costs"])
	else:
		add_line(words["no_losses"])
		inner_voice.say(voice_lines["summary_clean"])
	summary_box.visible = true
	# No focus on Next: a kid still pressing Space must not skip the summary.


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
