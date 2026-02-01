shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

uniform float pulse_time = -1.0; // set to 0 on trigger; advance in code; keep <0 to disable
uniform float pulse_duration = 1.0;
uniform float pulse_amplitude = 0.02;
uniform float pulse_width = 0.03;
uniform float pulse_repeat = 1.2;
uniform vec2 pulse_center = vec2(0.5, 0.5);

void fragment() {
	vec2 uv = UV;
	vec2 to_center = uv - pulse_center;
	float dist = length(to_center);
	float t = pulse_time;
	float progress = clamp(t / max(pulse_duration, 0.0001), 0.0, 1.0);
	float active = step(0.0, t) * step(t, pulse_duration);
	float radius = progress * pulse_repeat;
	float band = exp(-pow((dist - radius) / max(pulse_width, 0.0001), 2.0));
	float offset = band * pulse_amplitude * active;

	if (dist > 0.0001) {
		uv += (to_center / dist) * offset;
	}

	COLOR = texture(TEXTURE, uv);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
