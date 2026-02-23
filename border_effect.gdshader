//taken from  https://godotshaders.com/shader/particle-star/
shader_type canvas_item;

uniform sampler2D texture;
uniform float time;
uniform vec2 resolution;
uniform vec4 dissolveColor;  // Controllo del colore e della trasparenza dell'effetto di dissolvenza
uniform float circleSize;  // Controllo sulla grandezza del cerchio

void fragment() {
    vec2 uv = vec2(SCREEN_UV.x, 1.0 - SCREEN_UV.y);  // Inverti l'asse Y delle coordinate UV
    vec4 color = textureLod(texture, uv, 0.0);

    // Calcola il centro dello schermo
    vec2 center = resolution / 2.0;

    // Calcola la distanza dall'attuale pixel al centro dello schermo
    float distance = distance(uv, center);

    // Calcola la larghezza dell'effetto di dissolvenza basata sulla grandezza del cerchio
    float fadeWidth = circleSize;

    // Calcola la velocità dell'animazione
    float speed = 1.0;

    // Calcola il valore di transizione basato sul tempo e sulla distanza
    float transition = smoothstep(fadeWidth, 0.0, distance) * sin(time * speed);

    // Crea un nuovo colore mescolando l'attuale colore con il colore e la trasparenza personalizzati
    vec4 finalColor = mix(dissolveColor, color, transition);

    // Assegna il colore finale al pixel
    COLOR = finalColor;
}