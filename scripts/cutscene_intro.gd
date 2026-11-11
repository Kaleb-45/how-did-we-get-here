# cutscene_intro.gd
# The intro cutscene in the mission control war room (about 27.5 seconds).
# The AnimationPlayer node plays one animation called "intro" by itself
# (Autoplay). The animation moves the camera and the people, shows and
# hides the subtitles, shakes the camera and fades in and out.
# The people are character scenes (scenes/characters). The animation also
# calls talk() and point_at_camera() on them, and turns their heads.
#
# SHOT LIST (each shot is a hard cut; the times are in the animation):
#   Shot 0   0.0  fade in from black
#   Shot 1   0.0  high wide shot of the war room, slow push in
#   Shot 2   3.0  low angle on the Commander, snap zoom on "I quit!"
#   Shot 3   5.0  door shot from the walkway, the door slides, he leaves
#   Shot 4   7.3  close up of the General, held still (silent pause)
#   Shot 5   8.1  low angle medium shot of the General: "Who will run it?"
#   Shot 6  12.0  three quick cuts: Staff 1 ducks, Staff 2 ducks, Staff 3 dives
#                 into the closet, then a wide beat of the empty consoles
#   Shot 7  14.6  over the General's shoulder: "I need somebody. Anybody!"
#   Shot 8  17.4  same shot held, pause, his head turns toward us
#   Shot 9  18.2  front close up, punch in and shake: "You. I want you."
#   Shot 10 21.0  front three shot: Assistant Scientist, Janitor, Student
#   Shot 11 25.5  fade to black, then the name screen
#
# This script does three small jobs:
#   1. show_subtitle() / hide_subtitle(): speaker name (amber) and line (white).
#   2. shake_camera(): a quick camera shake that the animation can call.
#   3. When the animation ends, it goes to the name screen.
# The words come from data/story.json ("cutscene_intro").
extends Node3D

var _shake_left := 0.0
var _shake_total := 0.0
var _shake_strength := 0.0

@onready var subtitle_box: VBoxContainer = $CanvasLayer/BarBottom/SubtitleBox
@onready var speaker: Label = $CanvasLayer/BarBottom/SubtitleBox/Speaker
@onready var subtitle: Label = $CanvasLayer/BarBottom/SubtitleBox/Subtitle
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	# When the animation is over, move on to the next screen.
	animation_player.animation_finished.connect(_on_animation_finished)
	subtitle_box.visible = false


# The animation calls this (a "method track") to show one subtitle line.
func show_subtitle(key: String) -> void:
	var lines: Dictionary = Data.story.get("cutscene_intro", {}).get("subtitles", {})
	var line: Dictionary = lines.get(key, {})
	speaker.text = line.get("speaker", "")
	subtitle.text = line.get("text", "MISSING: " + key)
	subtitle_box.visible = true


func hide_subtitle() -> void:
	subtitle_box.visible = false


# The animation calls this to shake the camera for "seconds".
# "strength" is how far the picture jumps (0.02 is small).
func shake_camera(seconds: float, strength: float) -> void:
	_shake_left = seconds
	_shake_total = seconds
	_shake_strength = strength


# The shake moves the camera's h_offset and v_offset, so it never fights the
# animation tracks that move the camera's position and rotation.
func _process(delta: float) -> void:
	if _shake_left > 0.0:
		_shake_left -= delta
		var fade := clampf(_shake_left / _shake_total, 0.0, 1.0)
		camera.h_offset = randf_range(-1.0, 1.0) * _shake_strength * fade
		camera.v_offset = randf_range(-1.0, 1.0) * _shake_strength * fade
	elif camera.h_offset != 0.0 or camera.v_offset != 0.0:
		camera.h_offset = 0.0
		camera.v_offset = 0.0


# Go to the name screen. StageManager is the same way every other screen
# moves on (the screen list is in data/game_data.json, "stages").
func _on_animation_finished(_animation_name: StringName) -> void:
	StageManager.go_to("name")
