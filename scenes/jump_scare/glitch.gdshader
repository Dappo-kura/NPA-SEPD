shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.85;
uniform float speed : hint_range(1.0, 40.0) = 25.0;

float rand(float x) {
	return fract(sin(x * 127.1) * 43758.5453);
}

void fragment() {
	float t = TIME * speed;

	// 水平ブロック単位でずらすグリッチ
	float block_y = floor(UV.y * 28.0);
	float block_time = floor(t * 0.4);
	float shift = (rand(block_y + block_time) - 0.5) * intensity * 0.07;

	// 一部ブロックだけ強くずらす
	float strong = step(0.92, rand(block_y + block_time * 1.7));
	shift += strong * (rand(block_y * 3.0 + block_time) - 0.5) * 0.15;

	// RGB チャンネル分離（クロマティックアベレーション）
	vec2 uv_r = UV + vec2(shift + 0.007 * intensity, 0.0);
	vec2 uv_g = UV + vec2(shift, 0.0);
	vec2 uv_b = UV + vec2(shift - 0.007 * intensity, 0.0);

	float r = texture(TEXTURE, clamp(uv_r, vec2(0.0), vec2(1.0))).r;
	float g = texture(TEXTURE, clamp(uv_g, vec2(0.0), vec2(1.0))).g;
	float b = texture(TEXTURE, clamp(uv_b, vec2(0.0), vec2(1.0))).b;
	float a = texture(TEXTURE, clamp(uv_g, vec2(0.0), vec2(1.0))).a;

	// スキャンライン
	float scan = sin(UV.y * 600.0) * 0.02;

	COLOR = vec4(r - scan, g - scan, b - scan, a);
}
