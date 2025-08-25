shader_type compute;

layout(local_size_x = 16, local_size_y = 16) in;

uniform sampler2D fire_tex;
uniform sampler2D earth_tex;
uniform sampler2D water_tex;
uniform float delta_time;

void main() {
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
    vec4 fire = texelFetch(fire_tex, pos, 0);
    vec4 earth = texelFetch(earth_tex, pos, 0);
    vec4 water = texelFetch(water_tex, pos, 0);

    // If burning
    if (fire.r > 0.5) {
        // Extinguish if water present
        if (water.b > 0.5) {
            fire = vec4(0.0);
        } else {
            // Decrease lifetime
            fire.g -= delta_time;
            // Spread fire (20% chance per second)
            if (fract(fire.g) > (1.0 - delta_time) && rand(pos) < 0.2) {
                // Ignite a random neighbor (pseudo, see note below)
                // You will need to implement neighbor logic in a second pass or with atomic ops
            }
            // If lifetime over, turn to ash
            if (fire.g <= 0.0) {
                fire = vec4(0.0);
                earth = vec4(0.2, 0.2, 0.2, 1.0); // ash
            }
        }
    }
    // Write back (pseudo, see Godot docs for imageStore)
    imageStore(fire_img, pos, fire);
    // imageStore(earth_img, pos, earth);
}

// Helper: random function
float rand(ivec2 co) {
    return fract(sin(dot(vec2(co), vec2(12.9898,78.233))) * 43758.5453);
}