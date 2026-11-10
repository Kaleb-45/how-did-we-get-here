# mission_select.gd
# Same idea as character_select.gd: one card for each mission in the data.
extends Control

const CHOICE_CARD = preload("res://scenes/choice_card.tscn")

@onready var title_label: Label = %Title
@onready var cards_row: HBoxContainer = %Cards


func _ready() -> void:
	title_label.text = Data.story["mission_screen"]["title"]

	for mission_id in Data.missions:
		var words: Dictionary = Data.story["missions"][mission_id]

		var card = CHOICE_CARD.instantiate()
		cards_row.add_child(card)
		# No subtitle line for missions, so we pass "" and the card hides it.
		card.setup(words["name"], "", words["description"], words["button"])
		card.chosen.connect(_on_mission_chosen.bind(mission_id))


func _on_mission_chosen(mission_id: String) -> void:
	GameState.mission_id = mission_id
	print("Mission chosen: ", mission_id, "  (character: ", GameState.character_id, ")")
	StageManager.go_next()
