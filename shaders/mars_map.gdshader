// mars_map.gdshader
// A small Mars map drawn in code for the war room screens. No image files.
// It draws: a blue grid, a Mars disc, orbit lines, a moving dot on one orbit,
// a blinking amber marker and a slow scan line.
// Each screen uses its own "seed" number so the five screens look different.
shader_type spatial;
render_mode unshaded;

uniform float seed = 0.0;
uniform vec3 blue_color : source_color = vec3(0.2, 0.5, 1.0);
uniform vec3 amber_color : source_color = vec3(1.0, 0.6, 0.1);
uniform vec3 background_color : source_color = vec3(0.01, 0.03, 0.1);
// The screen is 5.6 wide and 3 tall (meters), so we use those to draw the map.
uniform vec2 screen_size = vec2(5.6, 3.0);

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float line(float d, float width) {
	return smoothstep(width, 0.0, abs(d));
}

void fragment() {
	vec2 p = local_pos.xy;                 // meters, (0,0) is the screen center
	float t = TIME + seed * 3.7;
	vec3 col = background_color;
	col += blue_color * 0.04 * (0.5 - p.y / screen_size.y);

	// grid
	vec2 g = abs(fract(p / 0.35 + 0.5) - 0.5);
	float grid = max(smoothstep(0.03, 0.0, g.x), smoothstep(0.03, 0.0, g.y));
	col += blue_color * grid * 0.25;

	// Mars disc, placed a little differently on each screen
	vec2 c = vec2(sin(seed * 2.1) * 0.9, cos(seed * 1.3) * 0.2);
	vec2 q = p - c;
	float r = length(q);
	float R = 0.85;
	if (r < R) {
		float h = sqrt(max(R * R - r * r, 0.0)) / R;   // 1 in the middle, 0 at the edge
		vec3 mars = amber_color * vec3(0.45, 0.3, 0.12) * (0.3 + 0.7 * h);
		float lat = abs(fract(q.y / R * 3.0 + 0.5) - 0.5);
		float lon = abs(fract(asin(clamp(q.x / R, -1.0, 1.0)) / 0.5 + t * 0.05) - 0.5);
		mars += blue_color * 0.15 * (smoothstep(0.04, 0.0, lat) + smoothstep(0.04, 0.0, lon));
		col = mix(col, mars, 0.9);
	}
	col += amber_color * line(r - R, 0.025) * 0.9;

	// three orbit lines, tilted, with dashes
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float a = 1.25 + fi * 0.55;
		float b = 0.55 + fi * 0.28;
		float tilt = 0.35 + fi * 0.6 + seed * 0.5;
		vec2 rq = vec2(cos(tilt) * q.x + sin(tilt) * q.y, -sin(tilt) * q.x + cos(tilt) * q.y);
		float e = length(vec2(rq.x / a, rq.y / b)) - 1.0;
		float ang = atan(rq.y, rq.x);
		float dash = step(0.35, fract(ang * 3.0 + fi * 0.3));
		col += blue_color * line(e * 0.5, 0.012) * (0.35 + 0.5 * dash);
		// a small dot moving on this orbit
		float s = t * (0.5 - fi * 0.12) + fi * 2.0;
		vec2 dot_rot = vec2(cos(s) * a, sin(s) * b);
		vec2 dp = vec2(cos(tilt) * dot_rot.x - sin(tilt) * dot_rot.y, sin(tilt) * dot_rot.x + cos(tilt) * dot_rot.y);
		float dd = length(q - dp);
		col += (fi == 0.0 ? amber_color : blue_color) * smoothstep(0.07, 0.02, dd);
	}

	// blinking amber marker with little brackets
	vec2 m = c + vec2(0.25 + 0.2 * sin(seed), 0.2);
	vec2 md = abs(p - m);
	float blink = step(0.45, fract(t * 0.9));
	float ring = line(length(p - m) - 0.13, 0.012);
	float corner = step(md.x, 0.2) * step(md.y, 0.2) * (1.0 - step(md.x, 0.17) * step(md.y, 0.17));
	col += amber_color * (smoothstep(0.06, 0.0, length(p - m)) * blink * 1.3 + ring * 0.8 + corner * 0.5);

	// a thin amber scan line that moves down the screen
	float scan = fract(t * 0.15);
	col += amber_color * line(p.y / screen_size.y + 0.5 - scan, 0.006) * 0.35;

	// dark edge so the map sits inside the screen
	vec2 e2 = abs(p) / (screen_size * 0.5);
	col *= smoothstep(1.0, 0.9, max(e2.x, e2.y));

	ALBEDO = col;
}
