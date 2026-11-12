// blob_shadow.gdshader
// A soft dark round spot that sits on the floor under a person or a console.
// It fakes a "contact shadow" (the Compatibility renderer has none).
// Change shadow_strength to make all the spots darker or lighter.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform float shadow_strength : hint_range(0.0, 1.0) = 0.38;

void fragment() {
	// UV goes 0..1 across the square. d is 0 in the middle and 1 at the edge.
	float d = length(UV - vec2(0.5)) * 2.0;
	ALBEDO = vec3(0.02, 0.04, 0.09);
	ALPHA = (1.0 - smoothstep(0.1, 1.0, d)) * shadow_strength;
}
