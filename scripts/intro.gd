# intro.gd
# The first screen: the story, the general's line, a Continue button,
# and pictures of the General (left) and the janitor (right).
# All the words come from data/story.json, so writers can change them
# without touching this script.
extends Control

# "@onready" means: find these nodes when the screen starts.
# The "%" finds a node by its unique name in the scene tree.
@onready var story_text: Label = %StoryText
@onready var general_line: Label = %GeneralLine
@onready var continue_button: Button = %ContinueButton
@onready var general_picture: TextureRect = %GeneralPicture
@onready var general_missing: Label = %GeneralMissing
@onready var general_caption: Label = %GeneralCaption
@onready var janitor_picture: TextureRect = %JanitorPicture
@onready var janitor_missing: Label = %JanitorMissing
@onready var janitor_caption: Label = %JanitorCaption


func _ready() -> void:
	var intro: Dictionary = Data.story["intro"]

	# Put the story lines on screen, with a blank line between each one.
	story_text.text = "\n\n".join(PackedStringArray(intro["lines"]))

	# The general's line, for example:  The General: "You're in charge now."
	general_line.text = intro["general_name"] + ": \"" + intro["general_says"] + "\""

	continue_button.text = intro["button"]

	# The two pictures. Which files to use is in story.json.
	show_picture(general_picture, general_missing, intro["general_picture"])
	show_picture(janitor_picture, janitor_missing, intro["janitor_picture"])
	general_caption.text = intro["general_name"]
	janitor_caption.text = intro["janitor_caption"]

	# When the button is clicked, run the function below.
	continue_button.pressed.connect(_on_continue_pressed)


func _on_continue_pressed() -> void:
	# Swap this whole screen for the next one.
	StageManager.go_next()


# Puts a picture file in a frame. If the file isn't there yet, the frame
# says where to put it, instead of the game crashing.
func show_picture(picture: TextureRect, missing: Label, path: String) -> void:
	if ResourceLoader.exists(path):
		picture.texture = load(path)
		missing.visible = false
	else:
		picture.visible = false
		missing.visible = true
		missing.text = Data.story["intro"]["missing_picture"] + "\n" + path.trim_prefix("res://")
