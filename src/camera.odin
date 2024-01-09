package tracer

import fmt "core:fmt"
import math "core:math"
import gl "vendor:OpenGL"
import "vendor:glfw"

Camera :: struct {
    Pos: [3]f32,
    Rot: [3]f32,
    Speed: f32,
    Sensitivity: f32,
    Window: ^glfw.WindowHandle,
    isUpdate: bool,
    WIDTH, HEIGHT: int,
}

camera_make :: proc(window: ^glfw.WindowHandle, position: [3]f32, rotation: [3]f32, speed: f32, sensitivity: f32) -> (cam: Camera) {
    using cam;
  	Pos[0] = position[0];
    Pos[1] = position[1];
    Pos[2] = position[2];
    Rot[0] = rotation[0];
    Rot[1] = rotation[1];
    Rot[2] = rotation[2];
    Speed = speed;
    Window = window;
    Sensitivity = sensitivity;
    x,y := glfw.GetWindowSize(Window^)
	WIDTH, HEIGHT =  cast(int) x, cast(int)y
    return cam
}

camera_rotate :: proc(using camera: ^Camera) {
    // mouse position
    xpos, ypos := glfw.GetCursorPos(camera.Window^)
    fmt.printf("x=%v y=%v\n", xpos, ypos)

    // normalized mouse position
    normalizedX := (xpos - f64(camera.WIDTH )/ 2.0) / f64(camera.WIDTH )
    normalizedY := (ypos - f64(camera.HEIGHT)/ 2.0) / f64(camera.HEIGHT)

    x :f32 = cast(f32)(normalizedX * 360.0 * f64(camera.Sensitivity))
    y :f32 = cast(f32)(normalizedY * 180.0 * f64(camera.Sensitivity))

    if x != cast(f32)camera.Rot[0] || y != camera.Rot[0] {
        camera.isUpdate = true
    }
    camera.Rot[0] = x
    camera.Rot[1] = y
}

camera_move :: proc(using camera: ^Camera) {
    cos_a := math.cos(camera.Rot[0] * (3.141592 / 180.0))
    sin_a := math.sin(camera.Rot[0] * (3.141592 / 180.0))

    if glfw.GetKey(camera.Window^, glfw.KEY_W) == glfw.PRESS { // forward
        camera.Pos[2] += camera.Speed * cos_a
        camera.Pos[0] += camera.Speed * sin_a
        camera.isUpdate = true
    }
    if glfw.GetKey(camera.Window^, glfw.KEY_S) == glfw.PRESS { // backward
        camera.Pos[2] -= camera.Speed * cos_a
        camera.Pos[0] -= camera.Speed * sin_a
        camera.isUpdate = true
    }
    if glfw.GetKey(camera.Window^, glfw.KEY_D) == glfw.PRESS { // right
        camera.Pos[2] -= camera.Speed * sin_a
        camera.Pos[0] += camera.Speed * cos_a
        camera.isUpdate = true
    }
    if glfw.GetKey(camera.Window^, glfw.KEY_A) == glfw.PRESS { // left
        camera.Pos[2] += camera.Speed * sin_a
        camera.Pos[0] -= camera.Speed * cos_a
        camera.isUpdate = true
    }
    if glfw.GetKey(camera.Window^, glfw.KEY_LEFT_SHIFT) == glfw.PRESS { // down
        camera.Pos[1] -= camera.Speed
        camera.isUpdate = true
    }
    if glfw.GetKey(camera.Window^, glfw.KEY_SPACE) == glfw.PRESS { // up
        camera.Pos[1] += camera.Speed
        camera.isUpdate = true
    }
}

camera_check_update :: proc(using camera: ^Camera, updateVariable: ^int) {
    if isUpdate {
        fmt.println("Do be updated")
        updateVariable^ = 1
        isUpdate = false
    }
}

camera_update :: proc(camera: ^Camera) {
    camera_rotate(camera)
    camera_move(camera)
}

