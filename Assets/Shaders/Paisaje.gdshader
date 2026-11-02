shader_type canvas_item;
render_mode unshaded;

uniform sampler2D mascaras : filter_linear, repeat_disable;
uniform float fuerza_agua : hint_range(0.0, 1.5) = 0.85;
uniform float fuerza_luces : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec3 zonas = texture(mascaras, UV).rgb;
    vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
    vec2 punto = UV;

    // Distorsión y movimiento de la cascada (Zona Roja)
    float onda = sin(pixel.y * 0.16 - TIME * 6.0 + pixel.x * 0.07);
    punto.y += onda * 1.5 * TEXTURE_PIXEL_SIZE.y * zonas.r * fuerza_agua;

    vec4 color = texture(TEXTURE, punto);

    // Caída de agua y brillo
    float caida = sin(pixel.y * 0.22 - TIME * 9.0);
    color.rgb *= 1.0 + caida * zonas.r * 0.10 * fuerza_agua;

    // Efecto de espuma (Zona Verde)
    float espuma = 0.5 + 0.5 * sin(pixel.x * 0.26 - TIME * 3.8 + sin(pixel.y * 0.41 + TIME * 2.4));
    color.rgb = mix(color.rgb, vec3(0.73, 0.83, 0.98), espuma * zonas.g * 0.21 * fuerza_agua);

    // Parpadeo suave de luces en ventanas (Zona Azul)
    float fase = floor(pixel.x / 35.0) * 1.73;
    float parpadeo = sin(TIME * 1.4 + fase) * 0.06 + sin(TIME * 2.7 + fase) * 0.03;
    color.rgb *= 1.0 + parpadeo * zonas.b * fuerza_luces;

    COLOR = vec4(clamp(color.rgb, vec3(0.0), vec3(1.0)), color.a);
}