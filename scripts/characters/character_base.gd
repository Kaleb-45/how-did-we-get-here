@tool
# character_base.gd
# A cute toy-like person made only from Godot's built-in shapes (no model files).
# Change the numbers in the Inspector and the person rebuilds itself.
#
# The nodes (all inside "Rig", which sits on the floor):
#   Rig            the whole person. Squash Rig's Y scale to make the person crouch.
#   Rig/Head       the head with the jaw. Turn Head's Y rotation to look around.
#   Rig/Head/LidHinge/Lid   the top of the head. It hinges at the BACK and flips
#                  open when the person talks. Eyes, brows, hair and hats are on it.
#   Rig/ArmL, Rig/ArmR      the two arms. Each one turns around a SHOULDER ball
#                  that is stuck on the body. Turn ArmR to point.
#   Rig/LegL, Rig/LegR      the two legs (a leg and its boot turn together at the hip).
# WALKING: call walk(true) to start a simple walk cycle (legs swing, body bobs,
# arms swing more) and walk(false) to stop. The animation does this with a method track.
# The person faces forward (the -Z direction).
#
# FACE: talk(seconds) flaps the lid. blink() closes the eyes for a moment (it also
# happens by itself every few seconds). express("neutral" / "surprised" / "worried" /
# "angry") moves the brows and eyes smoothly.
#
# COLOURS (all from the material library in res://materials, see materials/README.md):
#   skin_material    the face, head and hands
#   top_material     the upper body (jacket, lab coat, hoodie) and the arms
#   bottom_material  the lower body (trousers) and the legs
# Pick them in the Inspector, or in the character's own scene file.
# The look is "slightly faceted": the shapes use few segments on purpose.
#
# EACH ROLE has a small script that extends this one and fills in _build_extras()
# (hat, hair, props). The helper functions at the bottom make that easy.
extends Node3D

@export var height: float = 1.8:
	set(v):
		height = v
		_queue_rebuild()
@export var top_width: float = 0.5:
	set(v):
		top_width = v
		_queue_rebuild()
@export var bottom_width: float = 0.5:
	set(v):
		bottom_width = v
		_queue_rebuild()
@export var skin_material: Material:
	set(v):
		skin_material = v
		_queue_rebuild()
@export var top_material: Material:
	set(v):
		top_material = v
		_queue_rebuild()
@export var bottom_material: Material:
	set(v):
		bottom_material = v
		_queue_rebuild()
# How far the lid flips open when talking (radians) and how long one flap takes.
@export var mouth_open_angle: float = 0.5
@export var talk_flap_seconds: float = 0.2
# Idle bobbing: the person moves up and down a tiny bit so they look alive.
# Turn it off with idle_bob. It only moves Rig's position and sway, so it does
# not fight the animation tracks (Rig scale for crouching, Head turns, arms).
@export var idle_bob: bool = true
@export var bob_height: float = 0.012
@export var bob_speed: float = 2.2
# Arm sway: the arms swing a tiny bit. It stops on the right arm while it points.
@export var arm_sway: float = 0.05
# Walk cycle (only while walk(true) is on): how fast, how far the legs swing
# (radians) and how high the body bobs (meters).
@export var walk_speed: float = 9.0
@export var walk_leg_swing: float = 0.6
@export var walk_bob_height: float = 0.05
# Blinking: the eyes close for a moment at a random time between these two numbers
# (seconds). Turn it off with auto_blink.
@export var auto_blink: bool = true
@export var blink_min_seconds: float = 2.0
@export var blink_max_seconds: float = 5.0

# Art numbers (shape proportions). They are looks, not game numbers.
const LEG_FRACTION := 0.18      # legs are this part of the height
const DOME_FRACTION := 0.8      # head dome height compared to its radius
const JAW_FRACTION := 0.35      # jaw height compared to the head radius
const BOTTOM_CAP_FRACTION := 0.4
const SPLIT_FRACTION := 0.5     # where the top colour block meets the bottom block
const FACETS := 10              # side segments of every faceted shape (soft facets)
const SMALL_FACETS := 8         # side segments of small shapes (arms, hands, eyes)

# The faces. Each expression is [brow lift, brow tilt, eye size].
#   brow lift: how far the brows move up (as a part of the head radius; minus = down)
#   brow tilt: positive = the middle ends go UP (worried); minus = DOWN (angry)
#   eye size:  1.0 is normal; more is wide open
const EXPRESSIONS := {
	"neutral": [0.0, 0.0, 1.0],
	"surprised": [0.16, 0.0, 1.3],
	"worried": [0.06, 0.38, 0.88],
	"angry": [-0.07, -0.42, 0.95],
}

var top_r: float
var bottom_r: float
var dome_h: float
var jaw_h: float
var arm_len: float
var arm_r: float
var tube_bottom: float      # where the straight part of the body starts (height in meters)
var head_base_y: float      # where the body ends and the head starts
var shoulder_x: float       # how far to the side the shoulder balls are
var shoulder_y: float       # how high the shoulder balls are
var finger: Node3D          # the General's pointing finger (null for everybody else)

var _talk_tween: Tween
var _point_tween: Tween
var _face_tween: Tween
var _blink_tween: Tween
var _rebuild_queued := false
var _bob_time := 0.0
var _bob_phase := 0.0
var _walking := false
var _walk_time := 0.0
var _leg_l: Node3D
var _leg_r: Node3D
var _arm_busy := false   # true while the right arm points (no sway then)
var _arm_tilt := 0.15

# Face parts (made in _rebuild). The "pivot" nodes move; their child holds the shape.
var _eye_pivots: Array[Node3D] = []
var _eye_shapes: Array[Node3D] = []
var _brow_pivots: Array[Node3D] = []
var _brow_base_pos: Array[Vector3] = []
var _brow_base_basis: Array[Basis] = []
var _mouth_patches: Array[Node3D] = []   # dark patches, only seen while the lid is open
# The face numbers that the tweens change.
var _brow_lift := 0.0
var _brow_tilt := 0.0
var _eye_size := 1.0
var _blink := 0.0            # 0 = eyes open, 1 = eyes shut
var _blink_left := 3.0

@onready var rig: Node3D = $Rig
@onready var head: Node3D = $Rig/Head
@onready var lid_hinge: Node3D = $Rig/Head/LidHinge
@onready var lid: Node3D = $Rig/Head/LidHinge/Lid
@onready var arm_l: Node3D = $Rig/ArmL
@onready var arm_r_node: Node3D = $Rig/ArmR


func _ready() -> void:
	_bob_phase = randf() * TAU   # each person bobs at a different moment
	_blink_left = randf_range(blink_min_seconds, blink_max_seconds)
	_rebuild()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_update_face(delta)
	if _walking:
		_walk_cycle(delta)
		return
	if not idle_bob:
		rig.position.y = 0.0
		rig.rotation.z = 0.0
		return
	_bob_time += delta
	var wave := _bob_time * bob_speed + _bob_phase
	rig.position.y = (sin(wave) * 0.5 + 0.5) * bob_height
	rig.rotation.z = sin(wave * 0.5) * 0.012
	# A small arm sway (turns around the X axis only, so it never fights the
	# pointing tween or the rest tilt that is set on the Z axis).
	arm_l.rotation.x = sin(wave * 0.7 + 1.0) * arm_sway
	if not _arm_busy:
		arm_r_node.rotation.x = sin(wave * 0.7 + 3.1) * arm_sway


# Every frame: count down to the next blink, show the face numbers, and show the
# dark mouth patches only while the lid is open.
func _update_face(delta: float) -> void:
	if auto_blink:
		_blink_left -= delta
		if _blink_left <= 0.0:
			_blink_left = randf_range(blink_min_seconds, blink_max_seconds)
			blink()
	_apply_face()
	var open := lid_hinge.rotation.x > 0.02
	for patch in _mouth_patches:
		patch.visible = open


# One step of the walk cycle: legs swing in opposite directions, the body bobs
# twice per full stride, and the arms swing against the legs.
func _walk_cycle(delta: float) -> void:
	_walk_time += delta * walk_speed
	var swing := sin(_walk_time)
	if _leg_l:
		_leg_l.rotation.x = swing * walk_leg_swing
		_leg_r.rotation.x = -swing * walk_leg_swing
	rig.position.y = (1.0 - absf(swing)) * walk_bob_height   # highest when the legs pass under the body
	rig.rotation.z = 0.0
	arm_l.rotation.x = -swing * walk_leg_swing * 0.8
	if not _arm_busy:
		arm_r_node.rotation.x = swing * walk_leg_swing * 0.8


# Start or stop walking. Called by the animation (a method track).
func walk(on: bool) -> void:
	_walking = on
	if not on:
		if _leg_l:
			_leg_l.rotation.x = 0.0
			_leg_r.rotation.x = 0.0
		rig.position.y = 0.0
		arm_l.rotation.x = 0.0
		if not _arm_busy:
			arm_r_node.rotation.x = 0.0


func _queue_rebuild() -> void:
	if not is_node_ready() or _rebuild_queued:
		return
	_rebuild_queued = true
	_rebuild.call_deferred()


# ---------- public jobs ----------

# Flip the lid open and closed quickly for "seconds", then stay closed.
func talk(seconds: float) -> void:
	if _talk_tween:
		_talk_tween.kill()
	var flaps := maxi(1, int(seconds / talk_flap_seconds))
	_talk_tween = create_tween()
	for i in flaps:
		# a little variety so it does not look like a machine
		var open := mouth_open_angle * (0.65 + 0.35 * float((i * 3) % 4) / 3.0)
		_talk_tween.tween_property(lid_hinge, "rotation:x", open, talk_flap_seconds * 0.45)
		_talk_tween.tween_property(lid_hinge, "rotation:x", 0.0, talk_flap_seconds * 0.55)
	_talk_tween.tween_callback(func() -> void: lid_hinge.rotation.x = 0.0)


# Close the eyes for a moment. It happens by itself too (auto_blink).
func blink() -> void:
	if not is_inside_tree():
		return
	if _blink_tween:
		_blink_tween.kill()
	_blink_tween = create_tween()
	_blink_tween.tween_property(self, "_blink", 1.0, 0.05)
	_blink_tween.tween_property(self, "_blink", 0.0, 0.10)


# Change the face smoothly. name is "neutral", "surprised", "worried" or "angry".
func express(expression_name: String, seconds: float = 0.25) -> void:
	if not EXPRESSIONS.has(expression_name):
		push_warning("Unknown expression: " + expression_name)
		return
	var look: Array = EXPRESSIONS[expression_name]
	if _face_tween:
		_face_tween.kill()
	if not is_inside_tree():
		_brow_lift = look[0]
		_brow_tilt = look[1]
		_eye_size = look[2]
		return
	_face_tween = create_tween().set_parallel(true)
	_face_tween.tween_property(self, "_brow_lift", float(look[0]), seconds)
	_face_tween.tween_property(self, "_brow_tilt", float(look[1]), seconds)
	_face_tween.tween_property(self, "_eye_size", float(look[2]), seconds)


# Lift the right arm and point it forward (the person should face the camera).
# If this person has a pointing finger (the General), the finger sticks out too.
func point_at_camera() -> void:
	if _point_tween:
		_point_tween.kill()
	_arm_busy = true
	_point_tween = create_tween().set_parallel(true)
	_point_tween.tween_property(arm_r_node, "rotation", Vector3(1.5, 0.0, 0.0), 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if finger:
		_point_tween.tween_property(finger, "scale", Vector3.ONE, 0.3).set_delay(0.15)


# Put the arm down again. The finger curls back into the hand.
func lower_arm() -> void:
	if _point_tween:
		_point_tween.kill()
	_arm_busy = true
	_point_tween = create_tween().set_parallel(true)
	_point_tween.tween_property(arm_r_node, "rotation", Vector3(0.0, 0.0, _arm_tilt), 0.3)
	if finger:
		_point_tween.tween_property(finger, "scale", Vector3.ONE * FINGER_CURLED, 0.2)
	_point_tween.chain().tween_callback(func() -> void: _arm_busy = false)


const FINGER_CURLED := 0.05   # the finger is this part of its size while curled in the hand


# ---------- building the shapes ----------

func _rebuild() -> void:
	_rebuild_queued = false
	for n: Node3D in [rig, head, lid_hinge, lid, arm_l, arm_r_node]:
		_clear(n)
	lid_hinge.rotation = Vector3.ZERO
	finger = null
	_eye_pivots.clear()
	_eye_shapes.clear()
	_brow_pivots.clear()
	_brow_base_pos.clear()
	_brow_base_basis.clear()
	_mouth_patches.clear()
	top_r = top_width * 0.5
	bottom_r = bottom_width * 0.5
	dome_h = top_r * DOME_FRACTION
	jaw_h = top_r * JAW_FRACTION
	arm_r = 0.035 * height + 0.01
	arm_len = 0.2 * height

	var skin: Material = skin_material if skin_material else load("res://materials/skin_light.tres")
	var top: Material = top_material if top_material else load("res://materials/cloth_slate.tres")
	var bottom: Material = bottom_material if bottom_material else load("res://materials/cloth_dark_gray.tres")
	var dark: Material = load("res://materials/mouth_dark.tres")

	# --- body: a tapered tube in two colour blocks (top and bottom), rounded bottom ---
	var leg_h := LEG_FRACTION * height
	var cap_h := BOTTOM_CAP_FRACTION * bottom_r
	head_base_y = height - dome_h - jaw_h
	tube_bottom = leg_h + cap_h
	var tube_h := maxf(head_base_y - tube_bottom, 0.1)
	var split_r := lerpf(bottom_r, top_r, SPLIT_FRACTION)
	var low_h := tube_h * SPLIT_FRACTION
	var up_h := tube_h - low_h
	var low_tube := CylinderMesh.new()
	low_tube.top_radius = split_r
	low_tube.bottom_radius = bottom_r
	low_tube.height = low_h
	low_tube.radial_segments = FACETS
	low_tube.rings = 1
	_add(rig, low_tube, bottom, Vector3(0, tube_bottom + low_h * 0.5, 0))
	var up_tube := CylinderMesh.new()
	up_tube.top_radius = top_r
	up_tube.bottom_radius = split_r
	up_tube.height = up_h
	up_tube.radial_segments = FACETS
	up_tube.rings = 1
	_add(rig, up_tube, top, Vector3(0, tube_bottom + low_h + up_h * 0.5, 0))
	var cap := SphereMesh.new()
	cap.radius = bottom_r
	cap.height = bottom_r
	cap.is_hemisphere = true
	cap.radial_segments = FACETS
	cap.rings = 4
	_add(rig, cap, bottom, Vector3(0, tube_bottom, 0), Vector3(1, BOTTOM_CAP_FRACTION, 1), Vector3(PI, 0, 0))

	# --- legs and boots (each leg is a pivot at the hip, so it can swing) ---
	# The boot is half a ball with a flat bottom. Its flat bottom is at y = 0, so the
	# person stands ON the floor.
	var leg_r := 0.045 * height + 0.01
	var boot_r := leg_r * 1.4
	for side in [-1, 1]:
		var x: float = side * bottom_r * 0.45
		var pivot := Node3D.new()
		pivot.name = "LegL" if side < 0 else "LegR"
		pivot.set_meta("gen", true)
		rig.add_child(pivot)
		pivot.position = Vector3(x, leg_h, 0)
		if side < 0:
			_leg_l = pivot
		else:
			_leg_r = pivot
		var leg := CapsuleMesh.new()
		leg.radius = leg_r
		leg.height = leg_h * 1.1
		leg.radial_segments = SMALL_FACETS
		leg.rings = 2
		_add(pivot, leg, bottom, Vector3(0, leg_h * 0.5 + 0.03 - leg_h, 0))
		var boot := SphereMesh.new()
		boot.radius = boot_r
		boot.height = boot_r
		boot.is_hemisphere = true
		boot.radial_segments = SMALL_FACETS
		boot.rings = 3
		var boot_mat: Material = _boot_material()
		_add(pivot, boot, boot_mat, Vector3(0, -leg_h, -boot_r * 0.35), Vector3(1, 0.95, 1.5))
		if _boot_has_stripe():
			# a thin orange stripe on the outside of the sneaker
			var stripe := BoxMesh.new()
			stripe.size = Vector3(boot_r * 0.08, boot_r * 0.28, boot_r * 1.5)
			_add(pivot, stripe, load("res://materials/accent_orange.tres"),
				Vector3(side * boot_r * 0.94, -leg_h + boot_r * 0.36, -boot_r * 0.35))

	# --- shoulders and arms ---
	# A small ball sits on each side of the body (the shoulder joint). The arm
	# turns around the middle of that ball, so there is never a gap.
	shoulder_y = head_base_y - arm_r * 1.6
	var r_shoulder := body_radius_at(shoulder_y)
	var r_tip := body_radius_at(shoulder_y - arm_len)
	shoulder_x = r_shoulder * 0.95 + arm_r * 0.25
	_arm_tilt = clampf(atan2(r_tip + arm_r * 1.6 - shoulder_x, arm_len), 0.12, 0.9)
	for pair in [[arm_l, -1], [arm_r_node, 1]]:
		var arm: Node3D = pair[0]
		var s: int = pair[1]
		var ball := SphereMesh.new()
		ball.radius = arm_r * 1.25
		ball.height = arm_r * 2.5
		ball.radial_segments = SMALL_FACETS
		ball.rings = 4
		_add(rig, ball, top, Vector3(s * shoulder_x, shoulder_y, 0))
		arm.position = Vector3(s * shoulder_x, shoulder_y, 0)
		arm.rotation = Vector3(0, 0, s * _arm_tilt)
		var capsule := CapsuleMesh.new()
		capsule.radius = arm_r
		capsule.height = arm_len
		capsule.radial_segments = SMALL_FACETS
		capsule.rings = 2
		_add(arm, capsule, top, Vector3(0, -arm_len * 0.5, 0))
		var hand := SphereMesh.new()
		hand.radius = arm_r * 1.4
		hand.height = arm_r * 2.8
		hand.radial_segments = SMALL_FACETS
		hand.rings = 4
		_add(arm, hand, skin, hand_position())

	# --- head: jaw (stays), then the lid on a back hinge ---
	# The lid is the top of the head. Closed, it sits flat on the jaw (no seam).
	# Open, you see the dark mouth: one dark patch on the jaw top and one under the
	# lid, both only at the FRONT, and both hidden while the lid is closed.
	head.position = Vector3(0, head_base_y, 0)
	var jaw := CylinderMesh.new()
	jaw.top_radius = top_r
	jaw.bottom_radius = top_r
	jaw.height = jaw_h
	jaw.radial_segments = FACETS
	jaw.rings = 1
	_add(head, jaw, skin, Vector3(0, jaw_h * 0.5, 0))
	lid_hinge.position = Vector3(0, jaw_h, top_r)
	lid.position = Vector3(0, 0, -top_r)
	var dome := SphereMesh.new()
	dome.radius = top_r
	dome.height = top_r
	dome.is_hemisphere = true
	dome.radial_segments = FACETS
	dome.rings = 5
	_add(lid, dome, skin, Vector3.ZERO, Vector3(1, DOME_FRACTION, 1))
	# the flat underside of the lid (skin coloured, so you never see through the lid)
	var underside := CylinderMesh.new()
	underside.top_radius = top_r * 0.98
	underside.bottom_radius = top_r * 0.98
	underside.height = 0.004
	underside.radial_segments = FACETS
	underside.rings = 1
	_add(lid, underside, skin, Vector3(0, -0.002, 0))
	# the two dark mouth patches
	for patch_info in [[head, jaw_h + 0.004], [lid, -0.005]]:
		var patch := CylinderMesh.new()
		patch.top_radius = top_r * 0.62
		patch.bottom_radius = top_r * 0.62
		patch.height = 0.004
		patch.radial_segments = FACETS
		patch.rings = 1
		var patch_node := _add(patch_info[0], patch, dark, Vector3(0, patch_info[1], -top_r * 0.3), Vector3(1.0, 1, 0.8))
		patch_node.visible = false
		_mouth_patches.append(patch_node)

	# --- face: black oval eyes and brows on the lid ---
	# Each eye and brow is a small "pivot" node with the shape inside it, so the
	# expressions can move the pivot and the blink can squash the shape.
	var eye_mat: Material = load("res://materials/eye_black.tres")
	var eye_scale := _eye_size_factor()
	for side in [-1, 1]:
		var eye_pivot := Node3D.new()
		eye_pivot.name = "EyeL" if side < 0 else "EyeR"
		eye_pivot.set_meta("gen", true)
		lid.add_child(eye_pivot)
		# the eye sits a little INSIDE the dome surface, so it is flush (no floating)
		eye_pivot.transform = Transform3D(dome_basis(side * 0.36, 0.42), dome_point(side * 0.36, 0.42, -top_r * 0.05))
		var eye := SphereMesh.new()
		eye.radius = 1.0
		eye.height = 2.0
		eye.radial_segments = SMALL_FACETS
		eye.rings = 4
		var eye_shape := _add(eye_pivot, eye, eye_mat, Vector3.ZERO, Vector3(0.12, 0.19, 0.07) * top_r * eye_scale)
		eye_shape.name = "Eyeball"
		_eye_pivots.append(eye_pivot)
		_eye_shapes.append(eye_shape)

		var brow_pivot := Node3D.new()
		brow_pivot.name = "BrowL" if side < 0 else "BrowR"
		brow_pivot.set_meta("gen", true)
		lid.add_child(brow_pivot)
		var brow_basis := dome_basis(side * 0.38, 0.62)
		var brow_pos := dome_point(side * 0.38, 0.62, -top_r * 0.01)
		brow_pivot.transform = Transform3D(brow_basis, brow_pos)
		var brow := BoxMesh.new()
		brow.size = Vector3(0.3, 0.05, 0.04) * top_r * _brow_scale()
		_add(brow_pivot, brow, eye_mat)
		_brow_pivots.append(brow_pivot)
		_brow_base_pos.append(brow_pos)
		_brow_base_basis.append(brow_basis)

	_build_extras()
	_apply_face()


# Move the brows and eyes to the current face numbers (see EXPRESSIONS and blink).
func _apply_face() -> void:
	for i in _brow_pivots.size():
		var side := -1 if i == 0 else 1
		var tilt := Basis(Vector3.BACK, side * -_brow_tilt)
		var brow_basis := _brow_base_basis[i] * tilt
		var up := _brow_base_basis[i].y
		_brow_pivots[i].transform = Transform3D(brow_basis, _brow_base_pos[i] + up * _brow_lift * top_r)
	for i in _eye_pivots.size():
		_eye_pivots[i].scale = Vector3.ONE * _eye_size
		# blink: squash the eye flat (to 10 percent of its height)
		_eye_shapes[i].scale.y = 0.19 * top_r * _eye_size_factor() * lerpf(1.0, 0.1, _blink)


# ---------- things a role can change ----------

# Subclasses (General, Janitor, ...) add their clothes, hair, hat and props here.
func _build_extras() -> void:
	pass

# The shoe material. The Student wears white sneakers.
func _boot_material() -> Material:
	return load("res://materials/shoe_dark.tres")

func _boot_has_stripe() -> bool:
	return false

# Eye size: 1.0 is normal. The Student has bigger eyes.
func _eye_size_factor() -> float:
	return 1.0

# Brow size (length, thickness, depth). The General has heavy brows.
func _brow_scale() -> Vector3:
	return Vector3.ONE


# ---------- helpers for the shapes ----------

# Where the hand is, in the arm's own space (the arm hangs down from the shoulder).
func hand_position() -> Vector3:
	return Vector3(0, -arm_len - arm_r * 0.3, 0)


# How wide the body is at a height (meters). The body is a tapered tube.
func body_radius_at(y: float) -> float:
	var t := clampf(inverse_lerp(tube_bottom, head_base_y, y), 0.0, 1.0)
	return lerpf(bottom_r, top_r, t)


# Put a flat detail ON the body surface (a badge, a medal, a strap, a pocket).
#   y     = height on the body (meters)
#   x     = how far to the side of the middle (meters; minus = the person's left)
#   out   = how far to push it out (use half its thickness)
#   back  = true puts it on the back instead of the front
# The detail turns to follow the round body, and leans with the body's slope.
func add_on_body(mesh: Mesh, material: Material, y: float, x: float = 0.0, out: float = 0.01,
		back: bool = false, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var r := body_radius_at(y)
	var a := asin(clampf(x / r, -0.95, 0.95))
	var slope := atan((body_radius_at(y - 0.1) - body_radius_at(y + 0.1)) / 0.2)
	var dist := r * 0.96 + out
	var pos := Vector3(sin(a) * dist, y, (cos(a) if back else -cos(a)) * dist)
	var turn := (a + PI) if back else -a
	var node := _add(rig, mesh, material, pos)
	node.basis = Basis(Vector3.UP, turn) * Basis(Vector3.RIGHT, slope) * Basis.from_scale(scl)
	return node


# A belt around the body (a ring), with its middle at height y.
func add_belt(material: Material, y: float, belt_h: float) -> MeshInstance3D:
	var ring := CylinderMesh.new()
	ring.top_radius = body_radius_at(y + belt_h * 0.5) * 1.04
	ring.bottom_radius = body_radius_at(y - belt_h * 0.5) * 1.04
	ring.height = belt_h
	ring.radial_segments = FACETS
	ring.rings = 1
	return _add(rig, ring, material, Vector3(0, y, 0))


# The height where the top colour meets the bottom colour (the waist).
func waist_y() -> float:
	return tube_bottom + (head_base_y - tube_bottom) * SPLIT_FRACTION


# A short hair cap on the lid. "tilt" tips it back so the forehead shows
# (bigger = more forehead). "grow" is how much bigger than the head it is.
func add_hair_cap(material: Material, tilt: float = 0.9, grow: float = 1.06) -> MeshInstance3D:
	var cap := SphereMesh.new()
	cap.radius = top_r * grow
	cap.height = top_r * grow
	cap.is_hemisphere = true
	cap.radial_segments = FACETS
	cap.rings = 5
	return add_shape(lid, cap, material, Vector3(0, dome_h * 0.04, top_r * 0.1),
		Vector3(1, DOME_FRACTION * 1.05, 1), Vector3(tilt, 0, 0))


# A headset on the head: a dark band over the top, an ear cup on each side, and a
# small microphone with a cyan tip. It sits on the HEAD, not on the lid.
func add_headset() -> void:
	var band_mat: Material = load("res://materials/cloth_dark_gray.tres")
	var cyan: Material = load("res://materials/accent_cyan.tres")
	var pieces := 7
	var rx := top_r * 1.05
	var ry := dome_h * 1.08
	var prev := Vector3(rx, 0, 0)
	for i in range(1, pieces + 1):
		var a := PI * float(i) / float(pieces)
		var cur := Vector3(cos(a) * rx, sin(a) * ry, 0)
		var seg := BoxMesh.new()
		seg.size = Vector3(top_r * 0.1, (cur - prev).length() * 1.15, top_r * 0.14)
		var middle := (prev + cur) * 0.5
		var node := add_shape(head, seg, band_mat, Vector3(middle.x, jaw_h + middle.y, 0))
		node.rotation.z = atan2((cur - prev).y, (cur - prev).x) - PI * 0.5
		prev = cur
	for side in [-1, 1]:
		var cup := SphereMesh.new()
		cup.radius = top_r * 0.2
		cup.height = top_r * 0.4
		cup.radial_segments = SMALL_FACETS
		cup.rings = 4
		add_shape(head, cup, band_mat, Vector3(side * top_r * 1.02, jaw_h * 0.9, 0), Vector3(0.6, 1, 1))
	# microphone: a thin arm from the left ear cup toward the mouth, cyan tip
	var boom := CapsuleMesh.new()
	boom.radius = top_r * 0.04
	boom.height = top_r * 0.8
	boom.radial_segments = 6
	boom.rings = 2
	var boom_node := add_shape(head, boom, band_mat, Vector3(-top_r * 0.74, jaw_h * 0.55, -top_r * 0.5))
	boom_node.rotation = Vector3(PI * 0.5, 0, 0.9)
	var tip := SphereMesh.new()
	tip.radius = top_r * 0.07
	tip.height = top_r * 0.14
	tip.radial_segments = 6
	tip.rings = 3
	add_shape(head, tip, cyan, Vector3(-top_r * 0.5, jaw_h * 0.4, -top_r * 0.82))


# Two gray mustache halves just above the mouth line (they ride on the lid, so the
# mustache lifts with the top lip when the person talks).
# "size" 1.0 is normal; 1.5 is large and droopy. "spread" is how far apart the
# two halves are (smaller = they meet in the middle).
func add_mustache(size: float, spread: float = 0.3, yf: float = 0.17) -> void:
	var mat: Material = load("res://materials/hair_gray.tres")
	for side in [-1, 1]:
		var m := SphereMesh.new()
		m.radius = 1.0
		m.height = 2.0
		m.radial_segments = SMALL_FACETS
		m.rings = 4
		var node := _add(lid, m, mat, dome_point(side * spread * size, yf, 0.0))
		node.basis = dome_basis(side * spread * size, yf) \
			* Basis(Vector3.BACK, side * 0.35 * size) \
			* Basis.from_scale(Vector3(0.42, 0.14 * size, 0.14) * top_r * Vector3(size, 1, 1))


# Give this person ONE pointing finger on the right hand. point_at_camera() makes
# it stick out; lower_arm() curls it back into the hand.
func add_pointer_finger() -> void:
	var skin: Material = skin_material if skin_material else load("res://materials/skin_light.tres")
	finger = Node3D.new()
	finger.name = "Finger"
	finger.set_meta("gen", true)
	arm_r_node.add_child(finger)
	finger.position = hand_position()
	finger.scale = Vector3.ONE * FINGER_CURLED
	var capsule := CapsuleMesh.new()
	capsule.radius = arm_r * 0.5
	capsule.height = arm_r * 6.0
	capsule.radial_segments = 6
	capsule.rings = 2
	_add(finger, capsule, skin, Vector3(0, -arm_r * 3.0, 0))
	finger.rotation.x = 0.35   # the finger tips up a little, so it can be seen from the front


# A point on the dome surface. xf is across the face (-1 left .. 1 right),
# yf is up the dome (0 mouth line .. 1 top). "out" pushes the point outward.
func dome_point(xf: float, yf: float, out: float = 0.0) -> Vector3:
	var z := -sqrt(maxf(0.0, 1.0 - xf * xf - yf * yf))
	var p := Vector3(xf * top_r, yf * dome_h, z * top_r)
	return p + dome_normal(xf, yf) * out


func dome_normal(xf: float, yf: float) -> Vector3:
	var z := -sqrt(maxf(0.0, 1.0 - xf * xf - yf * yf))
	var n := Vector3(xf / top_r, yf / dome_h, z / top_r)
	return n.normalized()


# A rotation whose front (-Z) points straight out of the dome at that spot.
func dome_basis(xf: float, yf: float) -> Basis:
	var n := dome_normal(xf, yf)
	var up := Vector3.UP if absf(n.y) < 0.95 else Vector3.BACK
	return Basis.looking_at(n, up)


# Add one shape under a parent. Remembers it so a rebuild can delete it.
func add_shape(parent: Node3D, mesh: Mesh, material: Material, pos := Vector3.ZERO,
		scl := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
	return _add(parent, mesh, material, pos, scl, rot)


func _add(parent: Node3D, mesh: Mesh, material: Material, pos := Vector3.ZERO,
		scl := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.set_meta("gen", true)
	parent.add_child(mi)
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	return mi


func _clear(node: Node3D) -> void:
	for child in node.get_children():
		if child.has_meta("gen"):
			node.remove_child(child)
			child.queue_free()
