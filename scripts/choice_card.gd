# choice_card.gd
# One card with a title, a small line, a description and a button.
# We use the same card for characters and missions (and later, more).
# Build it once, reuse it everywhere.
extends PanelContainer

# Our own signal. The card shouts "chosen!" when its button is pressed.
# The screen that made the card listens for it.
signal chosen

@onready var picture_frame: VBoxContainer = %PictureFrame
@onready var picture: TextureRect = %Picture
@onready var missing_label: Label = %Missing
@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle
@onready var description_label: Label = %Description
@onready var choose_button: Button = %ChooseButton


func _ready() -> void:
	# When our button is pressed, send our own "chosen" signal.
	choose_button.pressed.connect(chosen.emit)


# Fill the card with words. Call this AFTER the card is added to the screen.
func setup(title: String, subtitle: String, description: String, button_text: String) -> void:
	title_label.text = title
	subtitle_label.text = subtitle
	subtitle_label.visible = subtitle != ""   # hide the line if it's empty
	description_label.text = description
	choose_button.text = button_text


# Optional: show a picture on the card. If the file is not there yet, the
# card says where to put it, instead of the game crashing.
func set_picture(path: String, missing_text: String) -> void:
	picture_frame.visible = true
	if ResourceLoader.exists(path):
		picture.texture = load(path)
		picture.visible = true
		missing_label.visible = false
	else:
		picture.visible = false
		missing_label.visible = true
		missing_label.text = missing_text + "\n" + path.trim_prefix("res://")


# Turn the button off (after an answer is picked) or back on.
func set_locked(locked: bool) -> void:
	choose_button.disabled = locked
