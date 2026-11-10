# inner_voice_bar.gd
# The bar at the bottom of the screen where the inner voice talks.
# Any screen can use it: add the inner_voice_bar scene, then call
#     %InnerVoiceBar.say("some text")
extends PanelContainer

# How many letters appear per second (the "typing" effect).
const LETTERS_PER_SECOND := 60.0

@onready var speaker_label: Label = %Speaker
@onready var line_label: Label = %Line

var typing: Tween   # the running typing animation, if any


func _ready() -> void:
	speaker_label.text = Data.voice["speaker_name"]
	line_label.text = ""


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
