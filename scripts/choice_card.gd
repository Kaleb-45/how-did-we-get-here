# choice_card.gd
# One card with a title, a small line, a description and a button.
# We use the same card for characters and missions (and later, more).
# Build it once, reuse it everywhere.
extends PanelContainer

# Our own signal. The card shouts "chosen!" when its button is pressed.
# The screen that made the card listens for it.
signal chosen

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
