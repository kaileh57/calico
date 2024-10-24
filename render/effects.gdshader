shader_type canvas_item;
// Line effect uniforms
uniform int lineCount : hint_range(2, 9000) = 70;
uniform float darknessMult : hint_range(0.0, 1.0) = 0.25;
uniform float timeSpeed : hint_range(1.0, 65.0) = 6.5;
uniform float wave_amount : hint_range(0.0, 2.0) = 1.0; // New wave control uniform
// Screen texture uniform
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
// Warp controls
uniform float warp_amount : hint_range(0.0, 2.0) = 1.1;
uniform float corner_push : hint_range(0.0, 0.5) = 0.04;
// Color shift controls
uniform float color_bleeding : hint_range(0.0, 0.1) = 0.05;
uniform float red_offset : hint_range(-0.01, 0.01) = 0.001;
uniform float green_offset : hint_range(-0.01, 0.01) = -0.002;
uniform float blue_offset : hint_range(-0.01, 0.01) = -0.002;
uniform float color_boost : hint_range(0.0, 5.0) = 2.8;
uniform float color_ghost : hint_range(0.0, 0.3) = 0.08;
// Pixel effects
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.65;
uniform float scanline_speed : hint_range(0.0, 10.0) = 3.5;
uniform float pixel_flutter : hint_range(0.0, 0.05) = 0.01;
uniform float pixel_noise : hint_range(0.0, 0.01) = 0.0017;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.3;

vec2 curve(vec2 uv) {
    uv = (uv - 0.5) * 2.0;
    uv *= warp_amount;
    uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
    uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
    uv = (uv / 2.0) + 0.5;
    uv = uv * (1.0 - corner_push * 2.0) + corner_push;
    return uv;
}

void fragment() {
    vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 q = FRAGCOORD.xy / iResolution.xy;
    vec2 uv = q;
    // Apply CRT curve distortion
    uv = curve(uv);
    // Calculate retro lines effect using curved coordinates
    float wave = cos(uv.y * PI * float(lineCount) + (TIME * timeSpeed)) * wave_amount; // Modified with wave_amount
    float slowwave = cos(uv.y * PI * float(lineCount/50) + (TIME * timeSpeed/2.5)) * wave_amount; // Modified with wave_amount
    float square = round(wave);
    vec4 retroLines = vec4(
        square,
        square,
        square,
        ((-square) * darknessMult)
    );
    vec4 darkwaves = vec4(0.0, 0.0, 0.0, ((-slowwave) * darknessMult/2.0));
    vec4 lines_effect = (darkwaves + retroLines) / 5.0;
    // Dynamic pixel noise
    float x = sin(0.3*TIME+uv.y*21.0)*sin(0.7*TIME+uv.y*29.0)*sin(0.3+0.33*TIME+uv.y*31.0)*pixel_noise;
    // Color shifting and bleeding
    vec3 col;
    col.r = texture(screen_texture,vec2(x+uv.x+red_offset,uv.y+red_offset)).x + color_bleeding;
    col.g = texture(screen_texture,vec2(x+uv.x+green_offset,uv.y+green_offset)).y + color_bleeding;
    col.b = texture(screen_texture,vec2(x+uv.x+blue_offset,uv.y+blue_offset)).z + color_bleeding;
    // Color ghosting effect
    col.r += color_ghost*texture(screen_texture,0.75*vec2(x+0.025, -0.027)+vec2(uv.x+red_offset,uv.y+red_offset)).x;
    col.g += color_ghost*0.5*texture(screen_texture,0.75*vec2(x+-0.022, -0.02)+vec2(uv.x+green_offset,uv.y+green_offset)).y;
    col.b += color_ghost*texture(screen_texture,0.75*vec2(x+-0.02, -0.018)+vec2(uv.x+blue_offset,uv.y+blue_offset)).z;
    // Color enhancement
    col = clamp(col*0.6+0.4*col*col*1.0,0.0,1.0);
    // Vignette
    float vig = (0.0 + 1.0*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y));
    col *= vec3(pow(vig,vignette_strength));
    // Color boost and temperature
    col *= vec3(0.95,1.05,0.95);
    col *= color_boost;
    // Scanlines
    float scans = clamp(0.35+0.35*sin(scanline_speed*TIME+uv.y*iResolution.y*1.5), 0.0, 1.0);
    float s = pow(scans,1.7);
    col = col*vec3(0.4+0.7*s);
    // Screen flicker
    col *= 1.0 + pixel_flutter*sin(110.0*TIME);
    // Edge masking
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        col *= 0.0;
    }
    // Scanline interference
    col *= 1.0-scanline_strength*vec3(clamp((mod(FRAGCOORD.x, 2.0)-1.0)*2.0,0.0,1.0));
    // Final composition
    vec4 final_color = vec4(col, 1.0);
    COLOR = mix(final_color, lines_effect + final_color, lines_effect.a);
}