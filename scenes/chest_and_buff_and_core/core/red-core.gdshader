shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // light blue
uniform float glow_strength : hint_range(0.0, 1.0) = 0.5;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    
    COLOR = tex;
    
    float pulse = (sin(TIME * pulse_speed) + 1.0) * 0.5;
    COLOR.rgb += glow_color.rgb * glow_strength * pulse;
}
