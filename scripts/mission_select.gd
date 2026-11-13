# mission_select.gd
# Question 4: "What is the mission for?"
# Same idea as character_select.gd: one card for each mission in the data.
# Each card also shows the mission's goal rules as a checklist. The numbers
# in the checklist are read from the mission's limits, never copied.
extends Control

const CHOICE_CARD = preload("res://scenes/choice_card.tscn")

@onready var title_label: Label = %Title
@onready var cards_row: HBoxContainer = %Cards
@onready var inner_voice: PanelContainer = %InnerVoiceBar

var cards: Array = []


func _ready() -> void:
	title_label.text = Data.story["mission_screen"]["title"]

	for mission_id in Data.missions:
		var words: Dictionary = Data.story["missions"][mission_id]

		var card = CHOICE_CARD.instantiate()
		cards_row.add_child(card)
		# No subtitle line for missions, so we pass "" and the card hides it.
		var arrival: String = GameState.get_arrival_type()
		if arrival == "orbit":
			card.setup(words["name"], "", words["description"], words["button"])
			card.set_extra(make_checklist(mission_id))
		else:
			# A landing or a flyby has its own goal (game_data.json "arrival_goals").
			var goal_words: Dictionary = Data.story["arrival_goals"][arrival]
			card.setup(goal_words["name"], "", goal_words["description"], words["button"])
			card.set_extra(make_arrival_checklist(arrival))
		card.custom_minimum_size.x = 860   # only one mission, so the card can be wide
		cards.append(card)
		card.chosen.connect(_on_mission_chosen.bind(mission_id))


# Builds the checklist text, for example:
#   The mission is a success if:
#   [ ] Send home at least 4 Gb/day
# Which limits are goal rules: game_data.json, "goal_rules".
# The wording: story.json. The numbers: the mission's limits.
func make_checklist(mission_id: String) -> String:
	var screen_text: Dictionary = Data.story["mission_screen"]
	var rule_words: Dictionary = Data.story["missions"][mission_id]["goal_rules"]
	var limits: Dictionary = Data.missions[mission_id]["limits"]

	var lines: PackedStringArray = [screen_text["goal_heading"]]
	for res_id in Data.missions[mission_id]["goal_rules"]["resources"]:
		var sentence: String = rule_words[res_id].format({
			"value": GameState.fmt(limits[res_id]["value"]),
			"unit": Data.resources[res_id]["unit"],
		})
		lines.append(screen_text["checklist_mark"] + " " + sentence)
	return "\n".join(lines)


# The checklist for a landing or a flyby, for example:
#   The mission is a success if:
#   [ ] Send home at least 20 Gb of data
func make_arrival_checklist(arrival: String) -> String:
	var screen_text: Dictionary = Data.story["mission_screen"]
	var lines: PackedStringArray = [screen_text["goal_heading"]]
	for rule_id in Data.story["arrival_goals"][arrival]["rules"]:
		var sentence: String = Data.story["arrival_goals"][arrival]["rules"][rule_id].format({
			"gb": GameState.fmt(Data.events["flyby_pass"]["planned_gb"]["value"]),
		})
		lines.append(screen_text["checklist_mark"] + " " + sentence)
	return "\n".join(lines)


func _on_mission_chosen(mission_id: String) -> void:
	GameState.mission_id = mission_id
	GameState.goal_id = mission_id   # for now, each mission has one goal with the same id
	print("Mission chosen: ", mission_id, "  (character: ", GameState.character_id, ")")

	for card in cards:
		card.set_locked(true)
	inner_voice.say_then_next(Data.voice["setup"]["goal"][mission_id][GameState.level])
