# station_panel.gd
# A small 2D panel for a Life Support station that needs a choice
# (for now: the Food station's "Start rationing" button).
# It has a title, a few words, and ONE button. All the words are given to
# open() by life_support.gd, which reads them from data/story.json.
extends PanelContainer

# Sent when the player clicks the button.
signal action_pressed

@onready var title: Label = %Title
@onready var close_hint: Label = %CloseHint
@onready var body: Label = %Body
@onready var action_button: Button = %ActionButton


func _ready() -> void:
	action_button.pressed.connect(_on_action_pressed)
	visible = false


func open(title_text: String, body_text: String, button_text: String, close_text: String) -> void:
	title.text = title_text
	title.add_theme_color_override("font_color", get_theme_color("font_color", &"AccentText"))
	body.text = body_text
	action_button.text = button_text
	close_hint.text = close_text
	action_button.disabled = false
	visible = true
	action_button.grab_focus()


func close() -> void:
	visible = false


func _on_action_pressed() -> void:
	action_button.disabled = true   # one click only
	action_pressed.emit()
