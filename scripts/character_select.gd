# character_select.gd
# Question 2: "Who are you?"
# Makes one card for EACH character in game_data.json (Scientist, Janitor,
# Student). Add a character to the data files, and a new card shows up
# here with no code changes.
# The character sets the level. GameState.level is looked up from the
# character, so they can never disagree.
extends Control

# The card "blueprint". preload() reads the scene file once.
const CHOICE_CARD = preload("res://scenes/choice_card.tscn")

@onready var title_label: Label = %Title
@onready var cards_row: HBoxContainer = %Cards
@onready var inner_voice: PanelContainer = %InnerVoiceBar

var cards: Array = []


func _ready() -> void:
	var screen_text: Dictionary = Data.story["character_screen"]
	title_label.text = screen_text["title"]

	# Loop over every character id, for example "janitor".
	# (Ids that start with "_" are notes for writers, not characters.)
	for character_id in Data.characters:
		if not Data.story["characters"].has(character_id):
			continue
		var level_id: String = Data.characters[character_id]["level"]   # from game_data.json
		var words: Dictionary = Data.story["characters"][character_id]  # from story.json

		var card = CHOICE_CARD.instantiate()   # make a new card from the blueprint
		cards_row.add_child(card)              # put it on the screen
		card.setup(
			words["name"],
			screen_text["difficulty_word"] + ": " + level_id,
			words["description"],
			words["button"]
		)
		card.set_picture(words["picture"], Data.story["intro"]["missing_picture"])
		cards.append(card)

		# When this card is chosen, call _on_character_chosen with its id.
		# bind() attaches the id, so we know WHICH card was clicked.
		card.chosen.connect(_on_character_chosen.bind(character_id))


func _on_character_chosen(character_id: String) -> void:
	GameState.character_id = character_id
	print("Character chosen: ", character_id, "  (level: ", GameState.level, ")")

	# Lock every card, let the inner voice react, then go on.
	for card in cards:
		card.set_locked(true)
	inner_voice.say(Data.voice["setup"]["character"][character_id])
	StageManager.go_next_after_reaction()
