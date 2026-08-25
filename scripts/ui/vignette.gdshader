// Vignette shader — darkens the screen edges for a moody, foggy frame.
//
// HOW A SHADER WORKS (the lesson):
//   A shader is a tiny program that runs ONCE PER PIXEL on the GPU.
//   For every pixel on screen, it decides what color that pixel should be.
//   `fragment()` is the function that runs per-pixel.
//   `UV` is the pixel's position as a 0..1 coordinate (0,0 = top-left,
//    1,1 = bottom-right, 0.5,0.5 = dead center).
//   `COLOR` is the output — what we set the pixel to.

shader_type canvas_item;

// These "uniforms" are knobs you can tweak in the Inspector (no code needed).
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.55; // how dark the edges get
uniform float vignette_radius   : hint_range(0.0, 1.0) = 0.75; // how far in the dark reaches
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.45; // how blurry/foggy the fade is
uniform vec4  vignette_color    : source_color = vec4(0.0, 0.0, 0.02, 1.0); // edge color (near-black)

void fragment() {
	// Distance of this pixel from the center of the screen (0.5, 0.5).
	// length() gives how far away we are; center = 0, corners ≈ 0.7.
	float dist = length(UV - vec2(0.5));

	// smoothstep makes a soft fade between the clear-center radius and the dark edge.
	// Inside vignette_radius = clear; past it = dark; softness widens the blur band.
	float edge = smoothstep(vignette_radius, vignette_radius + vignette_softness, dist);

	// Multiply by strength so you control the overall darkness.
	float alpha = edge * vignette_strength;

	// Output: the vignette color, with alpha strongest at the edges.
	COLOR = vec4(vignette_color.rgb, alpha);
}
