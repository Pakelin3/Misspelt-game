shader_type canvas_item;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    vec2 tile_id = floor(UV);
    float r = random(tile_id);
    float brightness = 1.0;
    if (r < 0.33) {
        brightness = 0.50;
    } else if (r < 0.66) {
        brightness = 0.75;
    }
    COLOR = tex_color;
    COLOR.rgb *= brightness;
}
