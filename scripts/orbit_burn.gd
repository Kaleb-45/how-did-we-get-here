# orbit_burn.gd
# Stage 4, first part: the orbit burn. The ship fires its engine to slow down
# and drop into orbit around Mars. It is ONE timed press with the E key
# (or a click). Then the Arrival walk starts (the mission clock, the shadow
# pass and Reroute Power, exactly as before).
#   Perfect or Good: no loss.
#   Miss: a cost is added to GameState.damage (lost fuel). It is only stored,
#         like the launch costs. A miss never ends the mission.
# The numbers are in data/timing.json ("orbit_burn"). The levels change nothing.
# NOTE: we do NOT call GameState.start_launch() here, because it would erase
# the damage from the launch.
extends Control

@onready var title_label: Label = %Title
@onready var hint_label: Label = %Hint
@onready var press: Control = %TimedPress
@onready var summary_box: PanelContainer = %SummaryBox
@onready var summary_title: Label = %SummaryTitle
@onready var summary_lines: VBoxContainer = %SummaryLines
@onready var next_button: Button = %NextButton
@onready var inner_voice: PanelContainer = %InnerVoiceBar

var words: Dictionary         # "orbit_burn_screen" from story.json
var voice_lines: Dictionary   # "orbit_burn" from inner_voice.json


func _ready() -> void:
	# Safety net for pressing Play on this screen directly.
	if GameState.character_id == "":
		GameState.character_id = Data.game_data["setup"]["default_character"]
	if GameState.mission_id == "":
		GameState.mission_id = Data.missions.keys()[0]
	GameState.fill_default_choices()

	words = Data.story["orbit_burn_screen"]
	voice_lines = Data.voice["orbit_burn"]
	title_label.text = words["title"]
	hint_label.text = words["hint"]
	next_button.text = words["next_button"]
	next_button.pressed.connect(_on_next_pressed)
	summary_box.visible = false

	inner_voice.say(voice_lines["start"])
	run_burn()


# One ring, one result, then the summary.
func run_burn() -> void:
	var numbers: Dictionary = Data.timing["orbit_burn"]
	press.show_waiting(words["get_ready"])
	await get_tree().create_timer(numbers["ready_seconds"]["value"]).timeout
	press.start(words["burn_label"], numbers["press_speed"]["value"], numbers["press_tightness"]["value"], press.ACTION_E)
	var result: String = await press.finished

	GameState.record_press("orbit_burn", "orbit_burn", result)
	var cost: Dictionary = GameState.scaled_cost(numbers["miss_cost"])   # a better engine loses less fuel
	if result == "Miss":
		GameState.add_damage(cost["kind"], cost["amount"])
	inner_voice.say(voice_lines["results"][result])
	await get_tree().create_timer(numbers["between_seconds"]["value"]).timeout
	show_summary(result, cost)


func show_summary(result: String, cost: Dictionary) -> void:
	press.visible = false
	summary_title.text = words["summary_title"]
	var line := Label.new()
	line.theme_type_variation = &"SmallText"
	if result == "Miss":
		var cost_text: String = Data.story["launch_screen"]["cost_kinds"][cost["kind"]].format({"amount": GameState.fmt(cost["amount"])})
		line.text = words["cost_line"].format({"cost": cost_text})
		inner_voice.say(voice_lines["summary_costs"])
	else:
		line.text = words["no_loss"]
		inner_voice.say(voice_lines["summary_clean"])
	summary_lines.add_child(line)
	summary_box.visible = true
	# No focus on Next: a kid still pressing E must not skip the summary.


# Lock the button at once, so a double click cannot skip two screens.
func _on_next_pressed() -> void:
	next_button.disabled = true
	StageManager.go_next()
