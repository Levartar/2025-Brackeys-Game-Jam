shader_type canvas_item;
uniform sampler2D layer_tex;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
    // Show the GPU texture as-is.
    COLOR = texture(layer_tex, UV);
}
