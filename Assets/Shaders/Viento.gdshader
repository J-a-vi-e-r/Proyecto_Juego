shader_type canvas_item;
render_mode unshaded;

uniform float fuerza : hint_range(0.0, 6.0) = 2.0;
uniform float velocidad : hint_range(0.1, 3.0) = 1.2;

void fragment() {
    vec2 punto = UV;
    // Reduce el movimiento en la parte inferior para fijar los troncos
    float parte_alta = 1.0 - smoothstep(0.0, 0.5, UV.y);
    float balanceo = sin(TIME * velocidad + UV.y * 1.6);
    punto.x += balanceo * fuerza * TEXTURE_PIXEL_SIZE.x * parte_alta;

    if (punto.x < 0.0 || punto.x > 1.0) {
        COLOR = vec4(0.0);
    } else {
        COLOR = texture(TEXTURE, punto);
    }
}