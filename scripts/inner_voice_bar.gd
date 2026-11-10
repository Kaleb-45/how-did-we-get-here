# inner_voice_bar.gd
# The bar at the bottom of the screen where the inner voice talks.
# Any screen can use it: add the inner_voice_bar scene, then call
#     %InnerVoiceBar.say("some text")
extends PanelContainer

# How many letters appear per second (the "typing" effect).
const LETTERS_PER_SECOND := 60.0

@onready var speaker_label: Label = %Speaker
@onready var line_label: Label = %Line
@onready var next_button: Button = %NextButton

var typing: Tween   # the running typing animation, if any


func _ready() -> void:
	speaker_label.text = Data.voice["speaker_name"]
	line_label.text = ""
	next_button.visible = false
	next_button.text = Data.story["setup_next_button"]
	next_button.pressed.connect(_on_next_pressed)


# Shows a new line, typed out letter by letter.
func say(text: String) -> void:
	line_label.text = text
	line_label.visible_ratio = 0.0   # 0 = no letters showing, 1 = all showing

	# Stop the old typing if a new line arrives before it finished.
	if typing:
		typing.kill()

	# A Tween changes a value smoothly over time.
	# Here: visible_ratio goes from 0 to 1, so the letters appear one by one.
	typing = create_tween()
	typing.tween_property(line_label, "visible_ratio", 1.0, text.length() / LETTERS_PER_SECOND)


# Used by the setup questions. The voice reacts, then a Next button shows.
# The player reads at their own pace and clicks Next to go on.
func say_then_next(text: String) -> void:
	say(text)
	next_button.visible = true
	next_button.disabled = false
	next_button.grab_focus()


# Lock the button at once, so a double click cannot skip two screens.
func _on_next_pressed() -> void:
	next_button.disabled = true
	StageManager.go_next()
