# rocket_view.gd
# A plain gray side view of the rocket, drawn with rectangles only.
# All colors come from the shared theme (type name RocketView).
# The launch screen tells it how far the launch has gone.
extends Control

var moments_done: int = 0    # how many launch moments are finished
var moments_total: int = 3   # how many moments this rocket has


func set_progress(done: int, total: int) -> void:
	moments_done = done
	moments_total = total
	queue_redraw()


func _draw() -> void:
	var sky: Color = get_theme_color("sky_color", &"RocketView")
	var ground: Color = get_theme_color("ground_color", &"RocketView")
	var body: Color = get_theme_color("body_color", &"RocketView")
	var nose: Color = get_theme_color("nose_color", &"RocketView")
	var fin: Color = get_theme_color("fin_color", &"RocketView")
	var flame: Color = get_theme_color("flame_color", &"RocketView")
	var stage_line: Color = get_theme_color("stage_line_color", &"RocketView")

	draw_rect(Rect2(Vector2.ZERO, size), sky)
	var ground_height := 40.0
	draw_rect(Rect2(0, size.y - ground_height, size.x, ground_height), ground)

	# After liftoff the rocket rises a little more with every moment.
	var rise: float = 0.0
	if moments_done > 0:
		rise = 70.0 * float(moments_done) / float(maxi(moments_total, 1))
	var middle_x: float = size.x / 2.0
	var bottom: float = size.y - ground_height - 30.0 - rise   # the bottom of the body

	# The body: two stages, with a line between them.
	var body_width := 60.0
	var stage_height := 80.0
	draw_rect(Rect2(middle_x - body_width / 2.0, bottom - stage_height, body_width, stage_height), body)
	draw_rect(Rect2(middle_x - body_width / 2.0, bottom - stage_height * 2.0, body_width, stage_height), body)
	draw_rect(Rect2(middle_x - body_width / 2.0, bottom - stage_height - 2.0, body_width, 4.0), stage_line)
	# The nose (a narrower rectangle on top).
	draw_rect(Rect2(middle_x - 20.0, bottom - stage_height * 2.0 - 36.0, 40.0, 36.0), nose)
	# Two fins at the bottom.
	draw_rect(Rect2(middle_x - body_width / 2.0 - 16.0, bottom - 30.0, 16.0, 30.0), fin)
	draw_rect(Rect2(middle_x + body_width / 2.0, bottom - 30.0, 16.0, 30.0), fin)
	# A flame under the rocket once it has lifted off.
	if moments_done > 0:
		draw_rect(Rect2(middle_x - 16.0, bottom, 32.0, 30.0), flame)
