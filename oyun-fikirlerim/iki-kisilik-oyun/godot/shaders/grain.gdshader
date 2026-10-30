shader_type canvas_item;
uniform float amount = 0.07;

float rnd(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	float g = rnd(floor(UV * vec2(1280.0, 720.0)) + floor(TIME * 24.0) * 17.0);
	COLOR = vec4(vec3(g), amount);
}
