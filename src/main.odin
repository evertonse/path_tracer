package tracer



ASPECT_RATIO  :f32 = 16.0 / 9.0

SCREEN_WIDTH  :i32 = 900;
SCREEN_HEIGHT :i32 = cast(i32) (f32(SCREEN_WIDTH)/ASPECT_RATIO)


IMAGE_WIDTH  : i32 =  SCREEN_WIDTH;
IMAGE_HEIGHT : i32 =  SCREEN_HEIGHT;

// VIEWPORT_WIDTH  :f32: f32(VIEWPORT_HEIGHT* f32(1)/f32(ASPECT_RATIO));
VIEWPORT_WIDTH  :f32 = VIEWPORT_HEIGHT * (f32(IMAGE_WIDTH)/f32(IMAGE_HEIGHT));
VIEWPORT_HEIGHT :f32= 2.0

samples_per_pixel := 260;

main :: proc () {
    fmt.println(IMAGE_HEIGHT)
    assert(SCREEN_HEIGHT*SCREEN_WIDTH > 0)
    assert(IMAGE_HEIGHT*IMAGE_WIDTH > 0)

    loop(render);
}

U32Img :: struct {
    width, height :i32,
    data: [^]u32,
}

Hit :: struct {
    is_hit, is_front_face: bool,
    position, normal :Vector3,
    t: f32,
}


Sphere :: struct {
    position :Vector3,
    radius: f32,
}

Vector3  :typeid: #type rl.Vector3
Color    :typeid: #type rl.Vector3

Ray :: struct {
    using _: rl.Ray,
    tmin, tmax :f32,
}

Object :: union{Sphere}

Scene :: struct {
    objs: [dynamic] Object,
}

make_scene :: proc() -> (self: Scene){
    return
}

ray_make :: proc(position := Vector3{0,0,0}, direction:= Vector3{0,0,1}) -> (ray: Ray) {
    ray.position = position 
    ray.direction = direction 
    ray.tmin = 0.001
    ray.tmax = math.F32_MAX
    return
}

ray_at :: proc(r :Ray, t: f32) -> rl.Vector3 {
    return r.position + r.direction*t;
}

ray_color_scene :: proc(r :Ray, scene: Scene) -> Vector3 {
    hit := ray_hit_scene(r, scene) 
    if hit.is_hit {
        // n := la.normalize(ray_at(r, hit.t) - Vector3{0,0,-1.0})
        hit.normal = la.normalize(hit.normal)
        return 0.5* (hit.normal + Color{1.0,1.0, 1.0});
    }

    unit_direction := la.normalize(r.direction);

    a := 0.5*(unit_direction.y + 1.0);

    start := Vector3{1.0, 1.0, 1.0}
    end   := Vector3{0.5, 0.7, 1.0}
    return auto_cast (1.0-a)*start + a*end;
}

ray_color_sphere :: proc(r :Ray) -> Vector3 {
    hit := ray_hit(r, Sphere{{0,0,-1}, 0.5}) 
    if hit.is_hit {
        n := la.normalize(ray_at(r, hit.t) - Vector3{0,0,-1.0})
        return 0.5* (n + Color{1.0,1.0, 1.0});
    }

    unit_direction := la.normalize(r.direction);

    a := 0.5*(unit_direction.y + 1.0);

    start := Vector3{1.0, 1.0, 1.0}
    end   := Vector3{0.5, 0.7, 1.0}
    return auto_cast (1.0-a)*start + a*end;
}

ray_color :: proc{ray_color_scene, ray_color_sphere}


ray_hit_sphere :: proc(r: Ray, s: Sphere) -> (hit: Hit) {
    oc := s.position - r.position

    a :f32 = la.length2(r.direction)
    h :f32 = la.dot(r.direction, oc)
    c :f32 = la.length2(oc) - s.radius*s.radius
    discriminant : f32 = h*h - a*c
    discriminant_sqrt : f32 = math.sqrt(discriminant)
    root := (h - discriminant_sqrt)/a
    if discriminant < 0 {
        hit.t = -1.0
        hit.is_hit = false
        return
    }

    if root <= r.tmin || root > r.tmax {
        root = (h + discriminant_sqrt)/a
        if root <= r.tmin || root > r.tmax {
            hit.is_hit = false
            return
        }
    }
    hit.is_hit = true
    hit.t = root
    hit.position = ray_at(r, hit.t)
    hit.normal = (hit.position - s.position) / s.radius;
    hit.is_front_face = la.dot(r.direction, hit.normal) < 0;
    hit.normal = hit.normal if hit.is_front_face else -hit.normal;
    return
}

ray_hit_scene:: proc(
    ray: Ray, 
    scene: Scene
) -> Hit {
    ray := ray
    using scene

    tmp_hit : Hit;
    return_hit : Hit;
    hit_anything := false;
    closest_so_far := ray.tmax;

    for obj in objs {
        ray.tmax = closest_so_far
        switch t in obj {
            case Sphere:
                tmp_hit = ray_hit(ray, obj.(Sphere))
            case:
                 panic("impossible")
        }
            
        if tmp_hit.is_hit {
            hit_anything = true;
            closest_so_far = tmp_hit.t;
            return_hit = tmp_hit;
        }
    }

    return_hit.is_hit = hit_anything

    return return_hit;
}

ray_hit :: proc{ray_hit_sphere, ray_hit_scene}


render ::  #force_inline proc(data: []u32) -> U32Img {
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

        @static min, max :f32 = 0.0, 0.999
        // assert(r <= 1.0 && g <= 1.0 && b <= 1.0)
        r := u32(256 * math.clamp(rf, min, max));
        g := u32(256 * math.clamp(gf, min, max));
        b := u32(256 * math.clamp(bf, min, max));
        a := u32(0xff)
        color_as_u32 :u32 =  (a << 24) | (b << 16) | (g << 8) | (r);
        return color_as_u32;
    }


    scene := make_scene()
    append(&scene.objs, 
        Sphere{position = {0,0,-1}, radius=0.5},
        Sphere{position = {0,-100.5,-1}, radius=100.0},
    )
    focal_length := 1.0

    camera_center := Vector3{0,0,0}

    viewport_u := Vector3{VIEWPORT_WIDTH,0,0}
    viewport_v := Vector3{0, -VIEWPORT_HEIGHT,0}

    Δu : Vector3 = viewport_u/f32(IMAGE_WIDTH)
    Δv : Vector3 = viewport_v/f32(IMAGE_HEIGHT)

    viewport_upper_left := camera_center - Vector3{0,0, f32(focal_length)} - viewport_u/2.0 - viewport_v/2.0

    pixel_0_0 := viewport_upper_left +0.5*(Δu + Δv)

    width, height : i32 = IMAGE_WIDTH, IMAGE_HEIGHT
    for j in 0..<height {
        for i in 0..<width {
            x,y: f32 = f32(i),f32(j)
            pixel_color := Color{0,0,0}
            pixel_center := pixel_0_0 + (x * Δu) + (y * Δv);
            for _ in 0..<samples_per_pixel {
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

            data[j*width + i] = color_u32(pixel_color, samples_per_pixel)
        }
    }


    img := U32Img{data = raw_data(data), width = auto_cast width, height = auto_cast height}
    return img

}




loop :: proc(img_gen :proc([]u32) -> U32Img) {

    using rl
    title :: proc () -> cstring {
        return TextFormat("FPS: %v\n", GetFPS())
    }


    InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, title=title());

    SetConfigFlags({.WINDOW_RESIZABLE})



    SetTargetFPS(60);


    @static IMG_DATA : [4000*4000]u32;
    data := IMG_DATA[:]
    img : Image;
    img.format = PixelFormat.UNCOMPRESSED_R8G8B8A8
    img.mipmaps = 1

    u32img : U32Img;
    first := false
    u32img = img_gen(data)
    img.data = u32img.data;
    img.width = u32img.width;
    img.height = u32img.height;
    fmt.println(u32img)
    texture := LoadTextureFromImage(img);

    { // Render as png just once
        u32img = img_gen(data)
        img.data = u32img.data;
        ExportImage(img, fmt.ctprintf("img_%v.png",samples_per_pixel))
        samples_per_pixel = 1
    }

    for !WindowShouldClose() {
        SetWindowTitle(title())
        BeginDrawing();
        ClearBackground(DARKBLUE);
        u32img = img_gen(data)
        img.data = u32img.data;
        UpdateTexture(texture, img.data);
        DrawFPS(10, 10);
        DrawTexture(texture, SCREEN_WIDTH / 2 - (img.width/2) , SCREEN_HEIGHT / 2 - (img.height/2), WHITE);
        DrawText("This IS a texture loaded from raw image data!", 300, 370, 10, RAYWHITE);
        EndDrawing();
    }

    CloseWindow();
}

import os   "core:os"
import str  "core:strings"
import fmt  "core:fmt"
import mem  "core:mem"
import la   "core:math/linalg"
import math "core:math"
import rand "core:math/rand"

import rl "vendor:raylib"
