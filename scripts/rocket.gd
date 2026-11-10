# rocket.gd
# Question 5: "What kind of rocket?"
# One card for each rocket in game_data.json ("launch_vehicles"). Each card
# shows its cost (game_data.json), its launch moments and window tightness
# (timing.json). The answer is saved in GameState.launch_vehicle_id.
extends Control

const CHOICE_CARD = preload("res://scenes/choice_card.tscn")

@onready var title_label: Label = %Title
@onready var cards_row: HBoxContainer = %Cards
@onready var inner_voice: PanelContainer = %InnerVoiceBar

var cards: Array = []


func _ready() -> void:
	var screen_text: Dictionary = Data.story["rocket_screen"]
	title_label.text = screen_text["title"]

	for vehicle_id in Data.game_data["launch_vehicles"]["vehicles"]:
		var cost: float = Data.game_data["launch_vehicles"]["vehicles"][vehicle_id]["cost"]
		var timing: Dictionary = Data.timing["launch_vehicles"][vehicle_id]
		var words: Dictionary = Data.story["launch_vehicles"][vehicle_id]

		# The three numbers, one per line.
		var numbers_text: String = "%s: %s %s\n%s: %s\n%s: %s" % [
			screen_text["cost_word"], GameState.fmt(cost), Data.resources["budget"]["unit"],
			screen_text["moments_word"], GameState.fmt(timing["moments"]),
			screen_text["tightness_word"], GameState.fmt(timing["window_tightness"]),
		]

		var card = CHOICE_CARD.instantiate()
		cards_row.add_child(card)
		card.setup(words["name"], "", words["description"], words["button"])
		card.set_extra(numbers_text)
		cards.append(card)
		card.chosen.connect(_on_rocket_chosen.bind(vehicle_id))


func _on_rocket_chosen(vehicle_id: String) -> void:
	GameState.launch_vehicle_id = vehicle_id
	print("Rocket chosen: ", vehicle_id)

	for card in cards:
		card.set_locked(true)
	inner_voice.say(Data.voice["setup"]["rocket"][vehicle_id][GameState.level])
	StageManager.go_next_after_reaction()
