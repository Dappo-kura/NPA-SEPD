shader_type canvas_item;
uniform float speed : hint_range(1.0, 30.0) = 15.0;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    float t = floor(TIME * speed);
    float n = rand(UV + vec2(t, t * 0.7));
    COLOR = vec4(n, n, n, n * 0.55);
}
