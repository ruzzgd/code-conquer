shader_type canvas_item;

uniform float glitch_strength : hint_range(0.0, 1.0) = 0.0;
uniform float time_scale : hint_range(0.1, 10.0) = 8.0;

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;

    if (glitch_strength > 0.0) {
        // 🔹 Horizontal glitch bands (thicker and stronger)
        float band = step(0.8, rand(vec2(uv.y * 50.0, TIME * time_scale)));
        uv.x += band * (0.15 * glitch_strength); // bigger shift

        // 🔹 Vertical tearing (random cuts)
        float tear = step(0.9, rand(vec2(uv.x * 30.0, TIME * 2.0)));
        uv.y += tear * (0.1 * glitch_strength);

        // 🔹 Blocky pixel offset (chunky distortions)
        vec2 block_uv = floor(uv * 30.0) / 30.0; 
        float block = step(0.92, rand(block_uv + TIME * time_scale));
        uv.x += block * (0.2 * glitch_strength);

        // 🔹 Heavy RGB channel shift
        vec4 texR = texture(TEXTURE, uv + vec2(0.03 * glitch_strength, 0.0));
        vec4 texG = texture(TEXTURE, uv);
        vec4 texB = texture(TEXTURE, uv - vec2(0.03 * glitch_strength, 0.0));

        // Mix in a "flash" effect (whitish distortion)
        float flash = step(0.98, rand(vec2(TIME * 10.0, uv.y * 200.0))) * 0.6 * glitch_strength;

        COLOR = vec4(texR.r, texG.g, texB.b, texG.a) + vec4(flash, flash, flash, 0.0);
    } else {
        // Normal background (no glitch)
        COLOR = texture(TEXTURE, uv);
    }
}
