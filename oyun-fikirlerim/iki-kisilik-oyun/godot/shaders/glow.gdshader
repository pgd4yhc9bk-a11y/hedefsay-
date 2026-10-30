shader_type canvas_item;
render_mode blend_add;
uniform vec2 light_px = vec2(640.0, 360.0);
uniform float radius = 270.0;
uniform float flicker = 0.0;

void fragment() {
	vec2 p = UV * vec2(1280.0, 720.0);
	float d = distance(p, light_px) / (radius * (1.0 + flicker));
	float g = (1.0 - smoothstep(0.0, 0.9, d));
	COLOR = vec4(vec3(1.0, 0.55, 0.2) * g * g * 0.22, 1.0);
}
