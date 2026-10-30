shader_type canvas_item;
uniform float strength = 0.62;

void fragment() {
	vec2 p = UV - 0.5;
	float v = smoothstep(0.30, 0.78, length(p * vec2(1.0, 0.92)) * 1.25);
	COLOR = vec4(0.0, 0.0, 0.0, v * strength);
}
