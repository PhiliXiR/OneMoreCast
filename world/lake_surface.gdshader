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
uniform vec3 cast_entry_center = vec3(0.0);
uniform float cast_entry_strength : hint_range(0.0, 1.0) = 0.0;
uniform float cast_entry_radius : hint_range(0.0, 4.0) = 0.0;
uniform float cast_entry_elapsed : hint_range(0.0, 3.0) = 3.0;
uniform vec3 waiting_lure_center = vec3(0.0);
uniform float waiting_lure_active : hint_range(0.0, 1.0) = 0.0;
uniform vec3 ambient_sign_center = vec3(0.0);
uniform float ambient_sign_strength : hint_range(0.0, 1.0) = 0.0;
uniform float ambient_sign_radius : hint_range(0.0, 4.0) = 0.0;
uniform float ambient_sign_elapsed : hint_range(0.0, 3.0) = 3.0;
uniform vec3 lure_sign_center = vec3(0.0);
uniform float lure_sign_strength : hint_range(0.0, 1.0) = 0.0;
uniform float lure_sign_radius : hint_range(0.0, 4.0) = 0.0;
uniform float lure_sign_elapsed : hint_range(0.0, 3.0) = 3.0;
uniform vec3 bite_center = vec3(0.0);
uniform float bite_strength : hint_range(0.0, 1.0) = 0.0;
uniform float bite_radius : hint_range(0.0, 4.0) = 0.0;
uniform float bite_elapsed : hint_range(0.0, 3.0) = 3.0;
uniform vec3 fight_center = vec3(0.0);
uniform float fight_strength : hint_range(0.0, 1.0) = 0.0;
uniform float fight_radius : hint_range(0.0, 4.0) = 0.0;
uniform vec3 fight_direction = vec3(0.0, 0.0, 1.0);
uniform float fight_phase : hint_range(-1.0, 2.0) = -1.0;
uniform vec3 landing_center = vec3(0.0);
uniform float landing_strength : hint_range(0.0, 1.0) = 0.0;
uniform float landing_radius : hint_range(0.0, 5.0) = 0.0;
uniform float landing_elapsed : hint_range(0.0, 3.0) = 3.0;

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
	float cast_distance = distance(world_position.xz, cast_entry_center.xz);
	float cast_lifetime = 1.0 - smoothstep(0.72, 1.15, cast_entry_elapsed);
	float cast_wave = cast_entry_elapsed * (1.65 + cast_entry_radius * 0.35);
	float cast_ring = 1.0 - smoothstep(0.025, 0.075, abs(cast_distance - cast_wave));
	float cast_inner_ring = 1.0 - smoothstep(0.02, 0.055, abs(cast_distance - max(cast_wave - 0.32, 0.08)));
	float cast_reaction = (cast_ring + cast_inner_ring * 0.65) * cast_lifetime * cast_entry_strength;
	float cast_splash = (1.0 - smoothstep(0.03, 0.18, cast_distance)) * (1.0 - smoothstep(0.0, 0.28, cast_entry_elapsed)) * cast_entry_strength;
	float waiting_distance = distance(world_position.xz, waiting_lure_center.xz);
	float waiting_radius = 0.26 + sin(TIME * 2.5) * 0.06;
	float waiting_ring = 1.0 - smoothstep(0.018, 0.052, abs(waiting_distance - waiting_radius));
	float waiting_reaction = waiting_ring * waiting_lure_active * 0.28;
	float ambient_distance = distance(world_position.xz, ambient_sign_center.xz);
	float ambient_life = 1.0 - smoothstep(0.58, 0.95, ambient_sign_elapsed);
	float ambient_ring = 1.0 - smoothstep(0.018, 0.055, abs(ambient_distance - (0.16 + ambient_sign_elapsed * 0.36) * ambient_sign_radius));
	float ambient_reaction = ambient_ring * ambient_life * ambient_sign_strength * 0.22;
	float lure_distance = distance(world_position.xz, lure_sign_center.xz);
	float lure_life = 1.0 - smoothstep(0.42, 0.72, lure_sign_elapsed);
	float lure_ring = 1.0 - smoothstep(0.018, 0.06, abs(lure_distance - (0.13 + lure_sign_elapsed * 0.58) * lure_sign_radius));
	float lure_reaction = lure_ring * lure_life * lure_sign_strength * 0.42;
	float bite_distance = distance(world_position.xz, bite_center.xz);
	float bite_life = 1.0 - smoothstep(0.58, 0.9, bite_elapsed);
	float bite_radius_now = (0.1 + bite_elapsed * 1.25) * bite_radius;
	float bite_ring = 1.0 - smoothstep(0.025, 0.085, abs(bite_distance - bite_radius_now));
	float bite_splash = (1.0 - smoothstep(0.06, 0.24, bite_distance)) * (1.0 - smoothstep(0.0, 0.22, bite_elapsed));
	float bite_reaction = (bite_ring + bite_splash * 0.8) * bite_life * bite_strength;
	float fight_distance = distance(world_position.xz, fight_center.xz);
	vec2 fight_direction_xz = normalize(fight_direction.xz + vec2(0.0001, 0.0001));
	vec2 fight_offset = world_position.xz - fight_center.xz;
	float fight_forward = dot(fight_offset, fight_direction_xz);
	float fight_lateral = abs(dot(fight_offset, vec2(-fight_direction_xz.y, fight_direction_xz.x)));
	float fight_motion = 0.18 + fight_phase * 0.13 + sin(TIME * (2.4 + fight_phase * 1.5) + dot(world_position.xz - fight_center.xz, vec2(4.0, 2.0))) * 0.05;
	float fight_wake_distance = abs(fight_forward - fight_motion * fight_radius);
	float fight_wake_width = mix(0.12, 0.32, clamp(fight_phase * 0.5, 0.0, 1.0)) * fight_radius;
	float fight_wake = (1.0 - smoothstep(0.035, 0.11, fight_wake_distance)) * (1.0 - smoothstep(fight_wake_width, fight_wake_width * 1.9, fight_lateral));
	float fight_splash = (1.0 - smoothstep(0.04, 0.32, fight_distance)) * max(fight_phase - 0.7, 0.0) * 0.35;
	float fight_reaction = (fight_wake * (0.22 + fight_phase * 0.19) + fight_splash) * fight_strength * step(0.0, fight_phase);
	float landing_distance = distance(world_position.xz, landing_center.xz);
	float landing_life = 1.0 - smoothstep(0.92, 1.35, landing_elapsed);
	float landing_radius_now = (0.1 + landing_elapsed * 1.45) * landing_radius;
	float landing_ring = 1.0 - smoothstep(0.03, 0.1, abs(landing_distance - landing_radius_now));
	float landing_inner_ring = 1.0 - smoothstep(0.02, 0.075, abs(landing_distance - max(landing_radius_now - 0.38, 0.08)));
	float landing_splash = (1.0 - smoothstep(0.08, 0.42, landing_distance)) * (1.0 - smoothstep(0.0, 0.32, landing_elapsed));
	float landing_reaction = (landing_ring + landing_inner_ring * 0.65 + landing_splash) * landing_life * landing_strength;
	water_color.rgb = mix(water_color.rgb, highlight_color.rgb, clamp(cast_splash * 0.5 + cast_reaction * 0.7 + waiting_reaction + ambient_reaction + lure_reaction + bite_reaction + fight_reaction + landing_reaction, 0.0, 0.88));
	ALBEDO = water_color.rgb;
	ROUGHNESS = mix(roughness, 0.08, view_highlight);
	SPECULAR = 0.8;
	METALLIC = 0.0;
	ALPHA = clamp(water_color.a - clarity * 0.3, 0.35, 0.96);
}
