# destination.gd
# Question 3: "Where are we going?"
# One card for each destination in data/destinations.json (all five).
# Only a destination whose arrival type is built can be picked
# (game_data.json, setup -> pickable_arrival_types). The others are grey
# with a "coming soon" line, so the game never breaks.
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
	# Sizes are in game_data.json ("destination_screen_layout"): five cards fit in one row.
	var layout: Dictionary = Data.game_data["destination_screen_layout"]
	cards_row.custom_minimum_size = Vector2(layout["row_width"], 0)
	cards_row.add_theme_constant_override("separation", layout["row_gap"])

	for destination_id in Data.destinations:
		var facts: Dictionary = Data.destinations[destination_id]   # from destinations.json
		var words: Dictionary = Data.story["destinations"][destination_id]   # from story.json

		# The small line under the name, for example "Arrival: orbit   Crew: yes".
		var crew_word: String = screen_text["crew_yes"] if facts["crew"]["value"] else screen_text["crew_no"]
		var facts_line: String = screen_text["facts_line"].format({
			"arrival": screen_text["arrival_names"][facts["arrival_type"]["value"]],
			"crew": crew_word,
		})

		var card = CHOICE_CARD.instantiate()
		card.custom_minimum_size = Vector2(layout["card_min_width"], 0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cards_row.add_child(card)
		card.setup(words["name"], facts_line, words["description"], words["button"])
		card.set_extra(extra_lines(facts, screen_text))
		card.choose_button.custom_minimum_size = Vector2(layout["button_min_width"], layout["button_height"])   # a smaller button, so the card can be narrow
		card.subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # so a narrow card can wrap it
		card.extra_label.theme_type_variation = &"SmallText"   # five cards: smaller words
		cards.append(card)
		card.chosen.connect(_on_destination_chosen.bind(destination_id))

		# A trip type that is not built yet: grey card, and its button is off and says "Coming soon".
		if not is_pickable(destination_id):
			card.theme_type_variation = &"LockedPanel"   # grey colors from the theme
			card.choose_button.tooltip_text = screen_text["coming_soon_line"]
			card.choose_button.text = screen_text["coming_soon_button"]
			card.set_locked(true)


# Can the player pick this destination? Only if its arrival type is built.
func is_pickable(destination_id: String) -> bool:
	var built: Array = Data.game_data["setup"]["pickable_arrival_types"]["value"]
	return built.has(Data.destinations[destination_id]["arrival_type"]["value"])


# The facts under the description: sunlight, radio delay, materials.
func extra_lines(facts: Dictionary, screen_text: Dictionary) -> String:
	var delay: Dictionary = facts["signal_delay_minutes"]["value"]
	var lines: Array = [
		screen_text["sun_line"].format({"percent": GameState.fmt(facts["sunlight_vs_earth"]["value"] * 100.0)}),
		screen_text["delay_line"].format({"min": GameState.fmt(delay["min"]), "max": GameState.fmt(delay["max"])}),
	]
	var names: Array = []
	for material_id in facts["materials"]["value"]:
		names.append(Data.story["destination_materials"][material_id])
	if not names.is_empty():
		lines.append(screen_text["materials_line"].format({"list": ", ".join(names)}))
	return "\n".join(lines)


func _on_destination_chosen(destination_id: String) -> void:
	if not is_pickable(destination_id):
		return   # safety net: a greyed card can never be picked
	GameState.destination_id = destination_id

	for card in cards:
		card.set_locked(true)
	inner_voice.say_then_next(Data.voice["setup"]["destination"][destination_id][GameState.level])
