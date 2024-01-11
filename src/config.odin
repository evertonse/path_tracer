package tracer

ASPECT_RATIO  :f32 = 16.0 / 9.0

TURBO_TEST :: true

when TURBO_TEST {
    SAMPLES_PER_PIXEL := 400;
    MAX_BOUNCE_DEPTH :: 200
    SCREEN_WIDTH  :i32 = 1600;
} else {
    SAMPLES_PER_PIXEL := 16;
    MAX_BOUNCE_DEPTH :: 20
    SCREEN_WIDTH  :i32 = 1200;
}

SCREEN_HEIGHT :i32 = cast(i32) (f32(SCREEN_WIDTH)/ASPECT_RATIO)


IMAGE_WIDTH  : i32 =  SCREEN_WIDTH;
IMAGE_HEIGHT : i32 =  SCREEN_HEIGHT;

// VIEWPORT_WIDTH  :f32: f32(VIEWPORT_HEIGHT* f32(1)/f32(ASPECT_RATIO));
VIEWPORT_WIDTH  :f32 = VIEWPORT_HEIGHT * (f32(IMAGE_WIDTH)/f32(IMAGE_HEIGHT));
VIEWPORT_HEIGHT :f32 = 2.0


GAMMA :: 2

MATERIAL_CENTER := make_lambertian_material({0.7, 0.3, 0.3});
MATERIAL_GROUND := make_lambertian_material({0.8, 0.8, 0.0});
MATERIAL_LEFT   := make_metal_material({0.8, 0.8, 0.8}, 0.3);
MATERIAL_RIGHT  := make_metal_material({0.8, 0.6, 0.2}, 0.9);
MATERIAL_DIELECTRIC  := make_dielectric_material(1.5);

SCENE := make_scene({
            sphere_make({0,-100.5,-1}, 100.0, &MATERIAL_GROUND),
            sphere_make({0 ,0,-1.3},  0.5, &MATERIAL_CENTER),
            sphere_make({1 ,0,-1.3},  0.5, &MATERIAL_LEFT),
            sphere_make({-1,0,-1.3},  0.5, &MATERIAL_DIELECTRIC),

            sphere_make({-0.125, -0.18, -0.37},  0.11, &MATERIAL_DIELECTRIC),
            sphere_make({-0.125, -0.18, -0.37}, -0.10, &MATERIAL_DIELECTRIC),
            // sphere_make({-1,0,-1.3},  0.5, &MATERIAL_RIGHT),
        })
