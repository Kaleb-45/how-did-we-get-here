# name.gd
# Question 1: "What is your name?"
# The Next button stays off until the player types something (spaces
# alone do not count). The name is saved in GameState.player_name, and
# the mission report shows it later.
extends Control

@onready var title_label: Label = %Title
@onready var name_box: LineEdit = %NameBox
@onready var next_button: Button = %NextButton
@onready var inner_voice: PanelContainer = %InnerVoiceBar


func _ready() -> void:
	var words: Dictionary = Data.story["name_screen"]
	title_label.text = words["title"]
	name_box.placeholder_text = words["placeholder"]
	name_box.max_length = Data.game_data["setup"]["name_max_length"]
	next_button.text = words["button"]
	next_button.disabled = true

	name_box.text_changed.connect(_on_text_changed)
	name_box.text_submitted.connect(_on_text_submitted)   # the Enter key
	next_button.pressed.connect(_on_next_pressed)
	name_box.grab_focus()


# strip_edges() cuts the spaces off both ends, so "   " becomes "".
func _on_text_changed(new_text: String) -> void:
	next_button.disabled = new_text.strip_edges() == ""


func _on_text_submitted(_text: String) -> void:
	if not next_button.disabled:
		_on_next_pressed()


func _on_next_pressed() -> void:
	GameState.player_name = name_box.text.strip_edges()
	print("Name: ", GameState.player_name)

	# Lock the screen, let the inner voice react, then go on.
	next_button.disabled = true
	name_box.editable = false
	var line: String = Data.voice["setup"]["name"]
	inner_voice.say(line.format({ "name": GameState.player_name }))
	StageManager.go_next_after_reaction()
