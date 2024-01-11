package tracer

main :: proc () {
    rl.TraceLog(.INFO, 
        fmt.ctprintf(
            "Image Height =%v, Width=%v",
            IMAGE_HEIGHT, IMAGE_WIDTH
        )
    )
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
    material: ^Material
}


Sphere :: struct {
    position :Vector3,
    radius: f32,
    material : ^Material,
}

sphere_make :: proc(position:= Vector3{0,0,0}, radius: f32=0.5, material: ^Material = nil) -> (self :Sphere){
    self.position = position
    self.radius = radius
    self.material = material
    return 
}

Vector3  :: #type rl.Vector3
Color    :: #type rl.Vector3

Ray :: struct {
    using _: rl.Ray,
    tmin, tmax :f32,
}

Object :: union{Sphere}

Scene :: struct {
    id: int,
    objs: [dynamic] Object,
}


vector3_near_zero :: proc (self: Vector3) -> bool {
    s :f32 = 1e-8;
    return math.abs(self[0]) < s && math.abs(self[1]) < s && math.abs(self[2]) < s;
}

vector3_random :: proc (min :f32 = 0, max:f32 = 1.0) -> Vector3 {
    return {rand.float32_range(min, max), rand.float32_range(min, max), rand.float32_range(min, max)};
}

vector3_random_in_unit_sphere :: proc() -> Vector3 {
    for true {
        p := vector3_random(-1,1)
        if la.dot(p, p) < 1 {
            return p
        }
    }
    return {}
}

vector3_random_unit :: proc() -> Vector3 {
    return la.normalize(vector3_random_in_unit_sphere())
}

vector3_random_on_hemisphere :: proc(normal: Vector3) -> Vector3 {
    on_unit_sphere := vector3_random_unit();
    // In the same hemisphere as the normal
    if la.dot(on_unit_sphere, normal) > 0.0 do return on_unit_sphere;
    return -on_unit_sphere;
}

make_scene :: proc(objs:[dynamic]Object = nil) -> (self: Scene){
    @static id := 0
    self.id = id
    id += 1
    self.objs = objs if objs != nil else [dynamic]Object{}

    return
}

ray_make :: proc(position := Vector3{0,0,0}, direction := Vector3{0,0,1}) -> (ray: Ray) {
    ray.position = position 
    ray.direction = direction 
    ray.tmin = 0.0025
    ray.tmax = math.F32_MAX
    return
}

ray_at :: proc(r :Ray, t: f32) -> rl.Vector3 {
    return r.position + r.direction*t;
}

ray_color_scene :: proc(r :Ray, scene: Scene, depth := MAX_BOUNCE_DEPTH) -> Vector3 {
    @static reflectance :f32 = 0.5
    @static lambertion := true

    if depth <= 0 do return {0,0,0}

    hit := ray_hit_scene(r, scene) 
    if hit.is_hit {
        // n := la.normalize(ray_at(r, hit.t) - Vector3{0,0,-1.0})
        attenuation, scattered, ok := hit.material->scatter(r, hit)
        if ok {
            return attenuation * ray_color_scene(scattered, scene, depth-1);
        }
        return Color{0,0,0}
    }

    unit_direction := la.normalize(r.direction);
    a := 0.5*(unit_direction.y + 1.0);
    start := Vector3{1.0, 1.0, 1.0}
    end   := Vector3{0.5, 0.7, 1.0}
    return auto_cast (1.0-a)*start + a*end;
}

ray_color_sphere :: proc(r :Ray) -> Vector3 {
    hit := ray_hit(r, sphere_make({0,0,-1}, 0.5)) 
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
    hit.material = s.material
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


render ::  #force_inline proc(cam: ^Camera, data: []u32) -> U32Img {
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



Render_Func:: #type proc(cam: ^Camera, data: []u32) -> U32Img
loop :: proc(img_gen :Render_Func) {

    title :: proc () -> cstring {
        return rl.TextFormat("FPS: %v\n", rl.GetFPS())
    }


    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, title=title());

    rl.SetConfigFlags({.WINDOW_RESIZABLE})



    rl.SetTargetFPS(60);


    @static IMG_DATA: [4000*4000]u32;

    data := IMG_DATA[:]
    img : rl.Image;
    img.format = rl.PixelFormat.UNCOMPRESSED_R8G8B8A8
    img.mipmaps = 1

    u32img : U32Img;
    first := false
    camera : ^Camera = nil
    u32img = img_gen(camera, data)
    img.data = u32img.data;
    img.width = u32img.width;
    img.height = u32img.height;
    fmt.println(u32img)
    texture := rl.LoadTextureFromImage(img);

    { // Render as png just once
        u32img = img_gen(camera, data)
        img.data = u32img.data;
        rl.ExportImage(img, fmt.ctprintf("img_%v.png",SAMPLES_PER_PIXEL))
        SAMPLES_PER_PIXEL = 1
    }

    for !rl.WindowShouldClose() {
        rl.SetWindowTitle(title())
        rl.BeginDrawing();
        rl.ClearBackground(rl.DARKBLUE);
        u32img = img_gen(camera, data)
        img.data = u32img.data;
        rl.UpdateTexture(texture, img.data);
        rl.DrawFPS(10, 10);
        rl.DrawTexture(texture, SCREEN_WIDTH / 2 - (img.width/2) , SCREEN_HEIGHT / 2 - (img.height/2), rl.WHITE);
        rl.DrawText("This IS a texture loaded from raw image data!", 300, 370, 10, rl.RAYWHITE);
        rl.EndDrawing();
    }

    rl.CloseWindow();
}

import os   "core:os"
import str  "core:strings"
import fmt  "core:fmt"
import mem  "core:mem"
import la   "core:math/linalg"
import math "core:math"
import rand "core:math/rand"

import rl "vendor:raylib"
