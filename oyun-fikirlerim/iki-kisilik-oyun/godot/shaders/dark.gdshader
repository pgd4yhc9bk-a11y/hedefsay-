shader_type canvas_item;
uniform vec2 light_px = vec2(640.0, 360.0);
uniform float radius = 270.0;
uniform float darkness = 0.97;
uniform float flicker = 0.0;

void fragment() {
	vec2 p = UV * vec2(1280.0, 720.0);
	float d = distance(p, light_px) / (radius * (1.0 + flicker));
	float a = smoothstep(0.45, 1.0, d) * darkness;
	COLOR = vec4(0.015, 0.015, 0.02, a);
}
