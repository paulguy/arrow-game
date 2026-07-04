shader_type canvas_item;

const float weight = 1.0 / 36.0;
const mat4 blur = mat4(
	vec4(weight, weight * 2.0, weight * 2.0, weight),
	vec4(weight * 2.0, weight * 4.0, weight * 4.0, weight * 2.0),
	vec4(weight * 2.0, weight * 4.0, weight * 4.0, weight * 2.0),
	vec4(weight, weight * 2.0, weight * 2.0, weight)
);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR.rgb = vec3(0.0);
	COLOR.a = texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2(-1.5, -1.5))).a * blur[0][0] +
			  texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2(-0.5, -1.5))).a * blur[0][1] +
			  texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2( 0.5, -1.5))).a * blur[0][2] +
			  texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2( 1.5, -1.5))).a * blur[0][3] +
			  texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2(-1.5, -0.5))).a * blur[1][0] +
			  texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2(-0.5, -0.5))).a * blur[1][1] +
			  texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2( 0.5, -0.5))).a * blur[1][2] +
			  texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2( 1.5, -0.5))).a * blur[1][3] +
			  texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2(-1.5,  0.5))).a * blur[2][0] +
			  texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2(-0.5,  0.5))).a * blur[2][1] +
			  texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2( 0.5,  0.5))).a * blur[2][2] +
			  texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2( 1.5,  0.5))).a * blur[2][3] +
			  texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2(-1.5,  1.5))).a * blur[3][0] +
			  texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2(-0.5,  1.5))).a * blur[3][1] +
			  texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2( 0.5,  1.5))).a * blur[3][2] +
			  texture(TEXTURE, UV + (TEXTURE_PIXEL_SIZE * vec2( 1.5,  1.5))).a * blur[3][3];
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
