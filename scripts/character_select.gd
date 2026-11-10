# character_select.gd
# Makes one card for EACH character in game_data.json.
# Right now that's only the janitor. Add a character to the data files,
# and a new card shows up here with no code changes.
extends Control

# The card "blueprint". preload() reads the scene file once.
const CHOICE_CARD = preload("res://scenes/choice_card.tscn")

@onready var title_label: Label = %Title
@onready var cards_row: HBoxContainer = %Cards


func _ready() -> void:
	var screen_text: Dictionary = Data.story["character_screen"]
	title_label.text = screen_text["title"]

	# Loop over every character id, for example "janitor".
	for character_id in Data.characters:
		var numbers: Dictionary = Data.characters[character_id]   # from game_data.json
		var words: Dictionary = Data.story["characters"][character_id]  # from story.json

		var card = CHOICE_CARD.instantiate()   # make a new card from the blueprint
		cards_row.add_child(card)              # put it on the screen
		card.setup(
			words["name"],
			screen_text["difficulty_word"] + ": " + numbers["difficulty"],
			words["description"],
			words["button"]
		)

		# When this card is chosen, call _on_character_chosen with its id.
		# bind() attaches the id, so we know WHICH card was clicked.
		card.chosen.connect(_on_character_chosen.bind(character_id))


func _on_character_chosen(character_id: String) -> void:
	GameState.character_id = character_id
	print("Character chosen: ", character_id)
	get_tree().change_scene_to_file("res://scenes/mission_select.tscn")
