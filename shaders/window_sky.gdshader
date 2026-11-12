// window_sky.gdshader
// The dawn sky: peach near the horizon, dusk blue higher up, plus a soft pale
// sun glow. It is drawn in code on a huge ball that surrounds the room
// (we see it through the tall window and over the walls). No picture file.
// The colours depend on the height in the world, so they do not slide when
// the camera moves.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

uniform vec3 peach_color : source_color = vec3(0.9647, 0.7255, 0.5412);   // #F6B98A
uniform vec3 dusk_color : source_color = vec3(0.1686, 0.2471, 0.4196);    // #2B3F6B
uniform float horizon_y = 6.0;     // world height where the sky is all peach
uniform float top_y = 34.0;        // world height where the sky is all dusk blue

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float t = clamp((world_pos.y - horizon_y) / (top_y - horizon_y), 0.0, 1.0);
	vec3 col = mix(peach_color, dusk_color, smoothstep(0.0, 1.0, sqrt(t)));
	// a soft sun glow low in the sky, behind the window
	vec3 dir = normalize(world_pos);
	float glow = smoothstep(0.35, 1.0, dot(dir, normalize(vec3(-0.15, 0.04, -1.0))));
	col += vec3(1.0, 0.85, 0.65) * glow * 0.3;
	ALBEDO = col;
}
