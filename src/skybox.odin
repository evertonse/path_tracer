package tracer
import os "core:os"
import str "core:strings"
import fmt "core:fmt"
import stb "vendor:stb/image"
import gl "vendor:OpenGL"

SKYBOX_FILE_PATH := "images/skybox/small_cave_2k.hdr";

Skybox :: struct {
    filepath: string,
    texture: u32,
    img_width, img_height, col_num: i32,
    
    rotation: [3]f32,
    col:    [3]f32,
};


skybox_make :: proc(WIDTH, HEIGHT :int) -> (self: Skybox) {
    using self
    
    rotation =  [3]f32{0.0, 0.0, 0.0 };
    col =     [3]f32{ 0.5, 0.5, 0.5 }

	newBytes: [^]f32 = stb.loadf("assets/images/skybox/small_cave_2k.hdr", &img_width, &img_height, &col_num, 0);
    defer stb.image_free(newBytes);
    fmt.printf("Skybox w=%v h=%v ch=%v\n", img_width, img_height, col_num)


	gl.GenTextures(1, &texture);
	gl.ActiveTexture(gl.TEXTURE0);
	gl.BindTexture(gl.TEXTURE_2D, texture);
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB32F, img_width, img_height, 0, gl.RGB, gl.FLOAT, newBytes);
	gl.BindTexture(gl.TEXTURE_2D, 0);
    assert(img_width != 0 && img_height != 0)
    return 
}


skybox_change_texture :: proc(using sky: ^Skybox, path: string, err: ^bool, is_hdr := true) {
    // Unload the previous texture if it exists
    if (texture != 0) {
    	gl.DeleteTextures(1, &texture);
    	texture = 0;
    }
    filepath = path
    
    // Load the new texture
    if (is_hdr) {
      newBytes: [^]f32 = stb.loadf(fmt.ctprintf("%s", filepath), &img_width, &img_height, &col_num, 0);
    	if (newBytes == nil) {
    		err^ = true;
    	}
    	else {
    		gl.GenTextures(1, &texture);
    		gl.ActiveTexture(gl.TEXTURE0);
    		gl.BindTexture(gl.TEXTURE_2D, texture);
    		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB32F, img_width, img_height, 0, gl.RGB, gl.FLOAT, newBytes);
    		stb.image_free(newBytes);
    		gl.BindTexture(gl.TEXTURE_2D, 0);
    	}
    } else {
      fmt.println("Oh my god is not hdr")
      os.exit(69)
    }
}

skybox_delete:: proc(using sky: ^Skybox) {
	gl.DeleteTextures(1, &texture);
}

skybox_active_and_bind :: proc(using sky: ^Skybox, texture_unit: u32) {
	gl.ActiveTexture(texture_unit);
	gl.BindTexture(gl.TEXTURE_2D, texture);
}
