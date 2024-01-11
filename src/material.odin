package tracer

Material :: struct {
    scatter: #type proc(self: ^Material, ray: Ray, hit: Hit) -> (attenuation: Color, scattered: Ray, ok: bool),
}

#assert(size_of(Material) == 8)

Shit_Diffuse_Material  :: struct {
    using _ : Material,
    albedo: Color,
}

Lambertian_Material :: struct {
    using _ : Material,
    albedo: Color,
}

Metal_Material :: struct {
    using _ : Material,
    albedo: Color,
    fuzz: f32,
}

Dielectric_Material :: struct {
    using _ : Material,
    ir: f32, // index of refraction
};

make_lambertian_material :: proc(albedo :Color = {0.5, 0.5, 0.5}) -> (self: Lambertian_Material) {

    scatter :: proc(self: ^Material, ray: Ray, hit: Hit) -> (attenuation: Color, scattered: Ray, ok: bool) {
        scatter_direction := hit.normal + vector3_random_unit();
        scattered = ray_make(hit.position, scatter_direction);
        // Catch degenerate scatter direction
        if vector3_near_zero(scatter_direction) {
            scatter_direction = hit.normal
        }
        attenuation = (cast(^Lambertian_Material)self)^.albedo;
        ok = true
        return
    }


    self.scatter = scatter
    self.albedo = albedo

    return

}



make_metal_material :: proc(albedo :Color = {0.5, 0.5, 0.5}, fuzz:f32=0) -> (self: Metal_Material) {
    Self :: Metal_Material

    scatter :: proc(self: ^Material, ray: Ray, hit: Hit) -> (attenuation: Color, scattered: Ray, ok: bool) {
        fuzz := (cast(^Self)self).fuzz
        reflected := la.reflect(la.normalize(ray.direction), hit.normal)
        scattered = ray_make(hit.position, reflected + fuzz*vector3_random_unit());
        // Catch degenerate scatter direction
        attenuation = (cast(^Self)self).albedo;
        ok = la.dot(scattered.direction, hit.normal) > 0;
        return
    }


    self.scatter = scatter
    self.albedo = albedo
    self.fuzz = fuzz if fuzz < 1 else 1

    return

}



make_dielectric_material :: proc ( index_of_refraction:f32= 0) -> (self : Dielectric_Material) {
    Self :: Dielectric_Material

    scatter :: proc(self: ^Material, ray: Ray, hit: Hit) -> (attenuation: Color, scattered: Ray, ok: bool) {
        self := (cast(^Self)self)
        ir := self.ir
        refraction_ratio := (1.0/ir) if hit.is_front_face else ir;

        unit_direction := la.normalize(ray.direction);
        cosθ := math.min(la.dot(-unit_direction, hit.normal), 1.0)
        sinθ := math.sqrt(1.0 - cosθ*cosθ)
        cannot_refract := refraction_ratio * sinθ  > 1.0;
        direction : Vector3
        if cannot_refract || reflectance(cosθ, refraction_ratio) > rand.float32_range(0, 1.0) {
            direction  = la.reflect(unit_direction, hit.normal);
        } else {
            direction  = la.refract(unit_direction, hit.normal, refraction_ratio);
        }

        {
            scattered = ray_make(hit.position, direction);
            attenuation = {1.0, 1.0, 1.0};
            ok = true
        }
        return
    }
    self.scatter = scatter
    self.ir = index_of_refraction
    return

}

reflectance :: proc(cosine, ref_idx: $T)  -> T{
    // Use Schlick's approximation for reflectance.
    r0 := (1-ref_idx) / (1+ref_idx);
    r0 = r0*r0;
    return r0 + (1-r0)*math.pow((1 - cosine),5);
}

import str  "core:strings"
import la   "core:math/linalg"
import math "core:math"
import rand "core:math/rand"

import rl "vendor:raylib"
