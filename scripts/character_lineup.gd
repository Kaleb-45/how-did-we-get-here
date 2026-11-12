# character_lineup.gd
# A test scene: all 8 characters in a row, each standing on a round stand that turns
# slowly, under plain even light. Press F6 to play this scene on its own.
# It is only for looking at the people (it is not part of the game).
#
# Every few seconds all of them change their face (neutral, surprised, worried,
# angry) and talk for a moment, so you can check the face and the mouth.
#
# KEYS (while it plays):
#   1 2 3 4   neutral, surprised, worried, angry  (stops the automatic changes)
#   T         everybody talks for 2 seconds
#   B         everybody blinks
#   P         stop or start the turning
#   A         point (General's arm); press again to lower it
#   SPACE     turn the automatic face changes back on
extends Node3D

@export var turn_speed: float = 0.5            # how fast the stands turn (radians per second)
@export var auto_faces: bool = true            # change the faces by themselves
@export var seconds_per_face: float = 3.0      # how long each face stays

const FACE_NAMES := ["neutral", "surprised", "worried", "angry"]

var _face_index := 0
var _face_time := 0.0
var _turning := true
var _pointing := false

@onready var stands: Node3D = $Stands


func _ready() -> void:
	_show_face(FACE_NAMES[0])


func _process(delta: float) -> void:
	if _turning:
		var n := 0
		for stand in stands.get_children():
			# each stand turns a little differently, so the row does not look like a machine
			stand.rotation.y += turn_speed * delta * (1.0 + 0.15 * float(n % 3))
			n += 1
	if auto_faces:
		_face_time += delta
		if _face_time >= seconds_per_face:
			_face_time = 0.0
			_face_index = (_face_index + 1) % FACE_NAMES.size()
			_show_face(FACE_NAMES[_face_index])
			_everybody_talks(1.2)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	var key := (event as InputEventKey).keycode
	match key:
		KEY_1, KEY_2, KEY_3, KEY_4:
			auto_faces = false
			_show_face(FACE_NAMES[key - KEY_1])
		KEY_T:
			_everybody_talks(2.0)
		KEY_B:
			for c in _characters():
				c.blink()
		KEY_P:
			_turning = not _turning
		KEY_A:
			_pointing = not _pointing
			for c in _characters():
				if _pointing:
					c.point_at_camera()
				else:
					c.lower_arm()
		KEY_SPACE:
			auto_faces = true


# Every character is the only child of its stand that is not the disc.
func _characters() -> Array[Node]:
	var list: Array[Node] = []
	for stand in stands.get_children():
		for child in stand.get_children():
			if child.has_method("express"):
				list.append(child)
	return list


func _show_face(face_name: String) -> void:
	for c in _characters():
		c.express(face_name)


func _everybody_talks(seconds: float) -> void:
	for c in _characters():
		c.talk(seconds)
