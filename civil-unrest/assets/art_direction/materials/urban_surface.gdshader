shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 base_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.85;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.0;
uniform float variation : hint_range(0.0, 0.5) = 0.12;
uniform float grain_scale = 50.0;
uniform float weathering : hint_range(0.0, 1.0) = 0.0;
varying vec3 world_point;
float hash21(vec2 p) {
 vec3 q = fract(vec3(p.xyx) * 0.1031);
 q += dot(q, q.yzx + 33.33);
 return fract((q.x + q.y) * q.z);
}
float noise2(vec2 p) {
 vec2 i = floor(p);
 vec2 f = fract(p);
 f = f * f * (3.0 - 2.0 * f);
 return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
 mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0)), f.x), f.y);
}
void vertex() { world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 vec2 p = vec2(world_point.x + world_point.z * 0.73, world_point.y + world_point.z * 0.41);
 float broad = noise2(p * 1.7);
 float fine = noise2(p * grain_scale);
 float damp = (1.0 - smoothstep(0.0, 2.2, world_point.y)) * noise2(p * vec2(2.0, 0.8));
 float tone = 1.0 + (broad - 0.5) * variation + (fine - 0.5) * variation * 0.55;
 ALBEDO = base_color.rgb * tone * (1.0 - damp * weathering * 0.26);
 ROUGHNESS = clamp(roughness_value + (fine - 0.5) * 0.08, 0.05, 1.0);
 METALLIC = metallic_value;
}
