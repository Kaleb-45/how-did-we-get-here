# timed_press_test.gd
# A small test bench for the timed-press scene. Press F6 to run it alone.
# Click "Start ring", press the key when the ring closes on the target, and
# the result shows. Click the key button to switch between Space and E.
extends Control

@onready var title_label: Label = %Title
@onready var press: Control = %TimedPress
@onready var start_button: Button = %StartButton
@onready var key_button: Button = %KeyButton
@onready var hint_label: Label = %Hint
@onready var result_label: Label = %Result
@onready var windows_label: Label = %Windows

var words: Dictionary
var key_id: String = "space"   # "space" or "e"


func _ready() -> void:
	words = Data.story["timed_press_test"]
	title_label.text = words["title"]
	start_button.text = words["start_button"]
	result_label.text = words["result_none"]
	press.finished.connect(_on_finished)
	start_button.pressed.connect(_on_start_pressed)
	key_button.pressed.connect(_on_key_pressed)
	show_key()


func current_action() -> String:
	return press.ACTION_SPACE if key_id == "space" else press.ACTION_E


func show_key() -> void:
	var key_name: String = words["key_names"][key_id]
	key_button.text = words["key_button"].format({"key": key_name})
	hint_label.text = words["hint"].format({"key": key_name})


func _on_key_pressed() -> void:
	key_id = "e" if key_id == "space" else "space"
	show_key()


func _on_start_pressed() -> void:
	result_label.text = words["result_none"]
	press.start(words["label"], 1.0, 1.0, current_action())
	windows_label.text = words["windows_line"].format({
		"perfect": "%.2f" % press.perfect_seconds,
		"good": "%.2f" % press.good_seconds,
	})


func _on_finished(result: String) -> void:
	result_label.text = words["result_line"].format({"result": words["results"][result]})
