# player.gd
# First-person walking: WASD to move, mouse to look around.
# The player is a CharacterBody3D, a body that walks and bumps into walls.
# Its "Head" holds the camera, so the camera turns up and down
# while the body turns left and right.
extends CharacterBody3D

# @export makes these show up in the Inspector, so you can tune them
# without opening the script. (They are controls, not mission numbers.)
@export var walk_speed: float = 4.0
@export var mouse_sensitivity: float = 0.003
@export var jump_speed: float = 4.5   # upward speed when you jump (about 1 m high)

@onready var head: Node3D = $Head

# How strong gravity is, from Project Settings.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	# A "group" is a name tag. The parts' reach zones check for this tag,
	# so they know it's the player walking in (not a wall or a part).
	add_to_group("player")
	make_input_actions()
	# Hide the mouse and lock it to the window, so moving it turns the view.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Godot works with "actions" (like "move_forward") instead of raw keys.
# Then the game asks "is move_forward pressed?" and doesn't care which key it is.
# Usually you set these up in Project Settings > Input Map. We make them here
# in code, so the project works without that setup step.
func make_input_actions() -> void:
	var keys := {
		"move_forward": [KEY_W, KEY_UP],
		"move_back":    [KEY_S, KEY_DOWN],
		"move_left":    [KEY_A, KEY_LEFT],
		"move_right":   [KEY_D, KEY_RIGHT],
		"interact":     [KEY_E],
		"jump":         [KEY_SPACE],
		"toggle_dashboard": [KEY_TAB],
	}
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)


# Runs for every mouse move, click and key press.
func _unhandled_input(event: InputEvent) -> void:
	# Mouse moved while captured: turn the body (left/right) and head (up/down).
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		# Stop the head from flipping over: limit looking up/down to 85 degrees.
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))

	# Esc frees the mouse. Clicking in the window grabs it again.
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Runs 60 times a second, for movement and physics.
func _physics_process(delta: float) -> void:
	# Fall if we're not standing on something.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump: only when standing on something (no jumping in mid-air).
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_speed

	# Which way do the keys point? (x = left/right, y = forward/back)
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# Turn that into a direction in the world, based on where we're facing.
	var direction := (transform.basis * Vector3(input.x, 0, input.y)).normalized()

	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed

	# Move, and slide along walls instead of getting stuck.
	move_and_slide()
