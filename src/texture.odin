package tracer
import gl "vendor:OpenGL"

Texture :: struct {
  tex: uint,
  WIDTH, HEIGHT: int
};



texture_make :: proc(width,height : int) -> (self: Texture){
    using self
    WIDTH = width;
    HEIGHT = height;
    
    gl.GenTextures(1, cast([^]u32) &tex);
    gl.BindTexture(gl.TEXTURE_2D,  cast(u32)tex);
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, auto_cast WIDTH, auto_cast HEIGHT, 0, gl.RGBA, gl.FLOAT, nil);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAX_LEVEL, 7);
    gl.GenerateMipmap(gl.TEXTURE_2D);
    return
}

texture_active_and_bind :: proc(using t: Texture,  texture_unit: u32) {
	gl.ActiveTexture(texture_unit);
	gl.BindTexture(gl.TEXTURE_2D, auto_cast tex);
}

texture_delete :: proc(using t: ^Texture) {
	gl.DeleteTextures(1,  cast([^]u32) &tex);
}
