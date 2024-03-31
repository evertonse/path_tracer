package tracer
_render ::  #force_inline proc(cam: ^Camera, data: []u32) -> U32Img {
        // Get a randomly-sampled camera ray for the pixel at location i,j, originating from
        // the camera defocus disk.

    pixel_sample_square :: proc(pixel_delta_u, pixel_delta_v: Vector3) -> Color {
        // Returns a random point in the square surrounding a pixel at the origin.
        px := -0.5 + rand.float32_range(0, 1.0)
        py := -0.5 + rand.float32_range(0, 1.0)
        return (px * pixel_delta_u) + (py * pixel_delta_v);
    }

    color_u32 :: proc(color: Color, samples_per_pixel: int) -> u32 {
        rf, gf, bf := expand_values(color)
        // Divide the color by the number of samples.
        scale := 1.0 / f32(samples_per_pixel);
        rf *= scale;
        gf *= scale;
        bf *= scale;

        rf = math.pow(rf, 1.0/f32(GAMMA));
        gf = math.pow(gf, 1.0/f32(GAMMA));
        bf = math.pow(bf, 1.0/f32(GAMMA));

        @static min, max :f32 = 0.0, 0.999
        // assert(r <= 1.0 && g <= 1.0 && b <= 1.0)
        r := u32(256 * math.clamp(rf, min, max));
        g := u32(256 * math.clamp(gf, min, max));
        b := u32(256 * math.clamp(bf, min, max));

        a := u32(0xff)
        color_as_u32 :u32 =  (a << 24) | (b << 16) | (g << 8) | (r);
        return color_as_u32;
    }


    scene := SCENE
    focal_length := 1.0

    camera_center := Vector3{0,0,0}

    viewport_u := Vector3{VIEWPORT_WIDTH,0,0}
    viewport_v := Vector3{0, -VIEWPORT_HEIGHT,0}

    Δu : Vector3 = viewport_u/f32(IMAGE_WIDTH)
    Δv : Vector3 = viewport_v/f32(IMAGE_HEIGHT)

    viewport_upper_left := camera_center - Vector3{0,0, f32(focal_length)} - viewport_u/2.0 - viewport_v/2.0

    pixel_0_0 := viewport_upper_left +0.5*(Δu + Δv)

    when !RELEASE {
        fmt.println("focal_length = ",  focal_length)
        rl.TraceLog(.INFO, fmt.caprintf("viewport_width = %v | viewport_height = %v\n",VIEWPORT_WIDTH, VIEWPORT_HEIGHT))
        rl.TraceLog(.INFO, fmt.caprintf("Δu, Δv = %v, %v", Δu, Δv))
        rl.TraceLog(.INFO, fmt.caprintf("viewport_u, viewport_v = %v, %v", viewport_u, viewport_v))
        rl.TraceLog(.INFO, fmt.caprintf("viewport_upper_left=%v", viewport_upper_left))
    }                                     
    width, height : i32 = IMAGE_WIDTH, IMAGE_HEIGHT
    for j in 0..<height {
        for i in 0..<width {
            x,y: f32 = f32(i),f32(j)
            pixel_color := Color{0,0,0}
            pixel_center := pixel_0_0 + (x * Δu) + (y * Δv);
            for _ in 0..<SAMPLES_PER_PIXEL {
                pixel_sample := pixel_center + pixel_sample_square(Δu, Δv);

                ray_origin  := camera_center
                ray_direction := pixel_sample - ray_origin;

                ray := ray_make(
                    position  =  ray_origin,
                    direction = ray_direction,
                )

                rc := ray_color(ray, scene)
                pixel_color += rc

            }

            data[j*width + i] = color_u32(pixel_color, SAMPLES_PER_PIXEL)
        }
    }


    img := U32Img{data = raw_data(data), width = auto_cast width, height = auto_cast height}
    return img

}

import os   "core:os"
import str  "core:strings"
import fmt  "core:fmt"
import mem  "core:mem"
import la   "core:math/linalg"
import math "core:math"
import rand "core:math/rand"

import rl "vendor:raylib"

