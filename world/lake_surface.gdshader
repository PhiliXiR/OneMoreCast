shader_type spatial;
render_mode blend_mix, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.08, 0.48, 0.48, 0.58);
uniform vec4 deep_color : source_color = vec4(0.015, 0.12, 0.24, 0.91);
uniform vec4 highlight_color : source_color = vec4(0.63, 0.91, 0.89, 1.0);
uniform float wave_height : hint_range(0.0, 0.2) = 0.055;
uniform float wave_speed : hint_range(0.0, 2.0) = 0.32;
uniform float roughness : hint_range(0.0, 1.0) = 0.22;
uniform vec3 tackle_clarity_center = vec3(0.0);
uniform float tackle_clarity_radius : hint_range(0.0, 5.0) = 0.0;
uniform float tackle_clarity_strength : hint_range(0.0, 1.0) = 0.0;

varying vec3 world_position;
varying float depth_mix;

float wave(vec2 position, vec2 direction, float frequency, float phase) {
	return sin(dot(position, direction) * frequency + TIME * wave_speed * phase);
}

float lake_height(vec2 point) {
	float broad_wave = wave(point, normalize(vec2(1.0, 0.42)), 0.72, 1.0);
	float crossing_wave = wave(point, normalize(vec2(-0.35, 1.0)), 1.13, 1.37);
	float detail_wave = wave(point, normalize(vec2(0.73, -0.68)), 2.25, 0.61);
	return (broad_wave * 0.5 + crossing_wave * 0.34 + detail_wave * 0.16) * wave_height;
}

void vertex() {
	vec2 point = VERTEX.xz;
	float center_height = lake_height(point);
	VERTEX.y += center_height;
	float sample_step = 0.08;
	float height_x = lake_height(point + vec2(sample_step, 0.0));
	float height_z = lake_height(point + vec2(0.0, sample_step));
	NORMAL = normalize(vec3((center_height - height_x) / sample_step, 1.0, (center_height - height_z) / sample_step));
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	depth_mix = smoothstep(-7.0, 7.0, point.y);
}

void fragment() {
	float view_highlight = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 3.2);
	float clarity_distance = distance(world_position.xz, tackle_clarity_center.xz);
	float clarity = (1.0 - smoothstep(0.0, max(tackle_clarity_radius, 0.001), clarity_distance)) * tackle_clarity_strength;
	vec4 water_color = mix(shallow_color, deep_color, depth_mix);
	water_color.rgb = mix(water_color.rgb, highlight_color.rgb, view_highlight * 0.42);
	ALBEDO = water_color.rgb;
	ROUGHNESS = mix(roughness, 0.08, view_highlight);
	SPECULAR = 0.8;
	METALLIC = 0.0;
	ALPHA = clamp(water_color.a - clarity * 0.3, 0.35, 0.96);
}
