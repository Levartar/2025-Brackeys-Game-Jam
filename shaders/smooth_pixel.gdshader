shader_type canvas_item;
render_mode unshaded;

// Texture must have 'Filter'-flag enabled!

// Automatic smoothing
// independent of geometry and perspective
vec4 texturePointSmooth(sampler2D smp, vec2 uv, vec2 pixel_size)
{
	vec2 ddx = dFdx(uv);
	vec2 ddy = dFdy(uv);
	vec2 lxy = sqrt(ddx * ddx + ddy * ddy);

	vec2 uv_pixels = uv / pixel_size;

	vec2 uv_pixels_floor = round(uv_pixels) - vec2(0.5f);
	vec2 uv_dxy_pixels = uv_pixels - uv_pixels_floor;

	uv_dxy_pixels = clamp((uv_dxy_pixels - vec2(0.5f)) * pixel_size / lxy + vec2(0.5f), 0.0f, 1.0f);

	uv = uv_pixels_floor * pixel_size;

	return textureGrad(smp, uv + uv_dxy_pixels * pixel_size, ddx, ddy);
}

void fragment()
{
	vec4 col = texturePointSmooth(TEXTURE, UV, TEXTURE_PIXEL_SIZE);

	// 4x4 Bayer matrix (values from 0 to 1)
	float bayer[16] = float[](
		0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
		12.0/16.0, 4.0/16.0, 14.0/16.0,  6.0/16.0,
		3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
		15.0/16.0, 7.0/16.0, 13.0/16.0,  5.0/16.0
	);
	int xi = int(FRAGCOORD.x) % 4;
	int yi = int(FRAGCOORD.y) % 4;
	float threshold = bayer[xi + yi * 2];

	// Quantize to 5 color levels and apply strong dithering
	float levels = 5.0;
	vec3 dithered = floor((col.rgb * levels + threshold)) / (levels - 1.0);
	COLOR = vec4(dithered, col.a);
}