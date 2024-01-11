package tracer

Camera :: struct {
    samples_per_pixel: i32,                 // Count of random samples for each pixel
    max_bounce_depth : i32,                 // Maximum number of ray bounces into scene
    image_width      : i32,                 // Rendered image width in pixel count
    image_height     : i32,                 // Rendered image height

    viewport_width   : i32,                 
    viewport_height  : i32,                 

    fov              : f32,                 // Vertical view angle (field of view)
    lookfrom         : Vector3,             // Point camera is looking from
    lookat           : Vector3,             // Point camera is looking at
    up               : Vector3,             // Camera-relative "up" direction

    defocus_angle    : f32,                 // Variation angle of rays through each pixel
    focus_dist       : f32,                 // Distance from camera lookfrom point to plane of perfect focus
    focal_length     : f32,                 // idk
    center           : Vector3,             // Camera center
    pixel_0_0        : Vector3,             // Location of pixel 0, 0
    Δu               : Vector3,             // Offset to pixel to the right
    Δv               : Vector3,             // Offset to pixel below
    u, v, w          : Vector3,             // Camera frame basis vectors
    defocus_disk_u   : Vector3,             // Defocus disk horizontal radius
    defocus_disk_v   : Vector3,             // Defocus disk vertical radius
}


/* usage: Create a default camera, then change the fields that you want xD*/
camera_default :: #force_inline proc(
    aspect_ratio     :f32 = 1,
    image_width      :i32 = 800,
    samples_per_pixel:i32 = 10,
    max_bounce_depth :i32 = 10,
    fov              :f32 = 90.0,         
    lookfrom         := Vector3{0, 0,-1}, 
    lookat           := Vector3{0, 0, 0},
    up               := Vector3{0, 1, 0},  
    defocus_angle    :f32 = 0, 
    focus_dist       :f32 = 10, 
    center           := Vector3{0, 0, 0},  
) -> (self: Camera) {
    self.image_width       = image_width      
    self.image_height      = cast(i32) (f32(image_width)/aspect_ratio)
    self.samples_per_pixel = samples_per_pixel
    self.max_bounce_depth  = max_bounce_depth 
    self.fov               = fov             
    self.lookfrom          = lookfrom         
    self.lookat            = lookat           
    self.up                = up              
    self.defocus_angle     = defocus_angle
    self.focus_dist        = focus_dist

    h := math.tan(math.to_radians(fov)/2)
    self.viewport_height = cast(i32) (2 * h * self.focal_length)
    self.viewport_width  = cast(i32) (f32(self.viewport_height*self.image_width)/f32(self.image_height))
        
    viewport_u := Vector3{f32(self.viewport_width),0,0}
    viewport_v := Vector3{0, -f32(self.viewport_height),0}

    self.Δu = viewport_u/f32(self.image_width)
    self.Δv = viewport_v/f32(self.image_height)

    viewport_upper_left := self.center - Vector3{0,0, f32(self.focal_length)} - viewport_u/2.0 - viewport_v/2.0
    self.pixel_0_0 = viewport_upper_left +0.5*(self.Δu  + self.Δv)

    return 
}

import os   "core:os"
import str  "core:strings"
import fmt  "core:fmt"
import mem  "core:mem"
import la   "core:math/linalg"
import math "core:math"
import rand "core:math/rand"

import rl "vendor:raylib"
