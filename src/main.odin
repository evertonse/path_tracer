package tracer



ASPECT_RATIO  :f32 = 16.0 / 9.0

SCREEN_WIDTH  :i32 = 900;
SCREEN_HEIGHT :i32 = cast(i32) (f32(SCREEN_WIDTH)/ASPECT_RATIO)


IMAGE_WIDTH  : i32 =  SCREEN_WIDTH;
IMAGE_HEIGHT : i32 =  SCREEN_HEIGHT;

// VIEWPORT_WIDTH  :f32: f32(VIEWPORT_HEIGHT* f32(1)/f32(ASPECT_RATIO));
VIEWPORT_WIDTH  :f32 = VIEWPORT_HEIGHT * (f32(IMAGE_WIDTH)/f32(IMAGE_HEIGHT));
VIEWPORT_HEIGHT :f32= 2.0

main :: proc () {
    fmt.println(IMAGE_HEIGHT)
    assert(SCREEN_HEIGHT*SCREEN_WIDTH > 0)
    assert(IMAGE_HEIGHT*IMAGE_WIDTH > 0)

    loop(img_gen_u32);
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

Ray      :: struct {
    using _: rl.Ray,
    tmin, tmax :f32,
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

ray_color :: proc(r :Ray) -> Vector3 {
    hit := ray_hit_sphere(r, Sphere{position = {0,0,-1}, radius=0.5}) 
    if hit.is_hit {
        n := la.normalize(ray_at(r, hit.t) - Vector3{0,0,-1.0})
        return 0.5*Color{n.x + 1.0, n.y + 1.0, n.z + 1.0};
    }

    unit_direction := la.normalize(r.direction);

    a := 0.5*(unit_direction.y + 1.0);

    start := Vector3{1.0, 1.0, 1.0}
    end   := Vector3{0.5, 0.7, 1.0}
    return auto_cast (1.0-a)*start + a*end;
}


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

ray_hit_any :: proc(
    ray: Ray, 
    objs: ..union{Sphere,}
) -> Hit {
    ray := ray

    temp_hit : Hit;
    return_hit : Hit;
    hit_anything := false;
    closest_so_far := ray.tmax;

    for obj in objs {
        ray.tmax = closest_so_far
        hit: Hit;
        switch t in obj {
            case Sphere:
                hit = ray_hit(ray, obj.(Sphere))
            case:
        }
            
        if hit.is_hit {
            hit_anything = true;
            closest_so_far = hit.t;
            return_hit = temp_hit;
        }
    }

    return_hit.is_hit = hit_anything

    return return_hit;
}

ray_hit :: proc{ray_hit_sphere}


img_gen_u32 ::  #force_inline proc(data: []u32) -> U32Img {
#no_bounds_check {
    focal_length := 1.0

    camera_center := Vector3{0,0,0}

    viewport_u := Vector3{VIEWPORT_WIDTH,0,0}
    viewport_v := Vector3{0, -VIEWPORT_HEIGHT,0}

    Δu := viewport_u/f32(IMAGE_WIDTH)
    Δv := viewport_v/f32(IMAGE_HEIGHT)

    viewport_upper_left := camera_center - Vector3{0,0, f32(focal_length)} - viewport_u/2.0 - viewport_v/2.0

    pixel_0_0 := viewport_upper_left +0.5*(Δu + Δv)

    width, height : i32 = IMAGE_WIDTH, IMAGE_HEIGHT
    for j in 0..<height {
        for i in 0..<width {
            x,y: f32 = f32(i),f32(j)
            pixel_center := pixel_0_0 + (x*Δu) + (y*Δv)
            ray_direction := pixel_center -camera_center
            ray := ray_make(
                position  =  camera_center,
                direction =  ray_direction,
            )
           rf, gf, bf := expand_values(ray_color(ray))

            assert(rf <= 1.0 && gf <= 1.0 && bf <= 1.0)

            r := u32(255.999 * rf);
            g := u32(255.999 * gf);
            b := u32(255.999 * bf);
            a := u32(0xff)

            color_u32 :u32 =  (a << 24) | (b << 16) | (g << 8) | (r);
                data[j*width + i] = color_u32
        }
    }


    img := U32Img{data = raw_data(data), width = auto_cast width, height = auto_cast height}
    return img
}

}




loop :: proc(img_gen :proc([]u32) -> U32Img) {
#no_bounds_check{

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
}


import os   "core:os"
import str  "core:strings"
import fmt  "core:fmt"
import mem  "core:mem"
import la   "core:math/linalg"
import math "core:math"

import rl "vendor:raylib"
