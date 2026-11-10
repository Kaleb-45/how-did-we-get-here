# destination.gd
# Question 3: "Where are we going?"
# One card for each destination in data/destinations.json.
# (Right now there is only one: Mars orbit.)
# The answer is saved in GameState.destination_id.
extends Control

const CHOICE_CARD = preload("res://scenes/choice_card.tscn")

@onready var title_label: Label = %Title
@onready var cards_row: HBoxContainer = %Cards
@onready var inner_voice: PanelContainer = %InnerVoiceBar

var cards: Array = []


func _ready() -> void:
	var screen_text: Dictionary = Data.story["destination_screen"]
	title_label.text = screen_text["title"]

	for destination_id in Data.destinations:
		var facts: Dictionary = Data.destinations[destination_id]   # from destinations.json
		var words: Dictionary = Data.story["destinations"][destination_id]   # from story.json

		# The small line under the name, for example "Arrival: orbit   Crew: yes".
		var crew_word: String = screen_text["crew_yes"] if facts["crew"]["value"] else screen_text["crew_no"]
		var facts_line: String = "%s: %s    %s: %s" % [
			screen_text["arrival_word"], facts["arrival_type"]["value"],
			screen_text["crew_word"], crew_word,
		]

		var card = CHOICE_CARD.instantiate()
		cards_row.add_child(card)
		card.setup(words["name"], facts_line, words["description"], words["button"])
		cards.append(card)
		card.chosen.connect(_on_destination_chosen.bind(destination_id))


func _on_destination_chosen(destination_id: String) -> void:
	GameState.destination_id = destination_id
	print("Destination chosen: ", destination_id)

	for card in cards:
		card.set_locked(true)
	inner_voice.say_then_next(Data.voice["setup"]["destination"][destination_id][GameState.level])
