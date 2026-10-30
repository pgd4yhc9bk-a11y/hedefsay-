shader_type canvas_item;
uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float speed = 0.012;
uniform float scroll = 0.0;
uniform float strength = 0.5;
uniform float band_top = 0.0;
uniform float band_bottom = 1.0;

void fragment() {
	vec2 uv = vec2(UV.x * 2.0 + TIME * speed + scroll, UV.y * 1.0);
	float n = texture(noise_tex, uv).r;
	n = smoothstep(0.38, 0.85, n);
	float band = smoothstep(band_top, band_top + 0.35, UV.y) * smoothstep(band_bottom, band_bottom - 0.35, UV.y);
	COLOR = vec4(0.9, 0.91, 0.93, n * band * strength);
}
