package tracer
import gl "vendor:OpenGL"
import "core:io"


Shader :: struct {
    id : u32
}

import os "core:os"
import "core:fmt"

read_file:: proc(filepath: string) -> string {
    data ,ok := os.read_entire_file(filepath)
    
    if !ok {
        fmt.eprintf("reading entire file failed filepath=%v\n", filepath);
        os.exit(69);
    }
	return transmute(string) data;
}

shader_compile :: proc(shader: u32, shader_type: string) {
	gl.CompileShader(shader);
	status: i32;
	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &status);
	if bool(status) != gl.TRUE {
        os.write(os.stdout, transmute([]u8)string("Shader Compile:  shader error\n"))
	}
}

import str "core:strings"
shader_make :: proc(frag: string, vert: string) -> (self: Shader) {
    using self
    self.id = gl.CreateProgram();
    vert_str := read_file(vert);
    vert_data : [1]cstring = {str.clone_to_cstring(vert_str)};

    frag_str := read_file(frag);
    frag_data : [1]cstring = {str.clone_to_cstring(frag_str)};
    
    // Create Vertex Shader Object
    vertexShader := gl.CreateShader(gl.VERTEX_SHADER);
    gl.ShaderSource(vertexShader, 1, raw_data(vert_data[:]), nil);
    shader_compile(vertexShader, "Vertex");
    
    // Create Fragment Shader Object
    fragmentShader := gl.CreateShader(gl.FRAGMENT_SHADER);
    gl.ShaderSource(fragmentShader, 1, raw_data(frag_data[:]), nil);
    shader_compile(fragmentShader, "Fragment");
    
    sucess: i32 = ---;
    for shader in ([2]u32{fragmentShader, vertexShader}) {
        gl.GetShaderiv(shader, gl.COMPILE_STATUS, &sucess);
        if bool(sucess) != gl.TRUE {
            info: [512]u8;
            gl.GetShaderInfoLog(shader, 512, nil, raw_data(info[:]));
            fmt.eprintf("[Shader::compile_shader ERROR]: %v", info)
            assert(false, "look at console");
        }
	}

    // Create Shader Program Object
    fmt.printf("Shader self.id = %v id\n", id)
    gl.AttachShader(id, vertexShader);
    gl.AttachShader(id, fragmentShader);
    gl.LinkProgram (id);

    
    // Delete the now useless Vertex and Fragment Shader objects
    gl.DeleteShader(vertexShader);
    gl.DeleteShader(fragmentShader);

    return
}

uniform1f :: proc(using s: Shader, name: cstring, val: f32) {
	gl.Uniform1f(gl.GetUniformLocation(id, name), val);
}

uniform2f :: proc(using s: Shader, name: cstring, val1, val2: f32) {
	gl.Uniform2f(gl.GetUniformLocation(id, name), val1, val2);
} 

uniform3f :: proc(using s: Shader, name: cstring, val1, val2, val3: f32) {
	gl.Uniform3f(gl.GetUniformLocation(id, name), val1, val2, val3);
} 

uniform1i :: proc(using s: Shader, name: cstring, val: i32) {
	gl.Uniform1i(gl.GetUniformLocation(id, name), val);
}

uniformfs :: proc(using s: Shader, name: cstring, vals: []f32) {
	gl.Uniform1fv(gl.GetUniformLocation(id, name), cast(i32)len(vals), raw_data(vals));
} 

shader_activate:: proc(using s: Shader) {
	gl.UseProgram(id);
}

shader_delete :: proc(using s: Shader) {
	gl.DeleteProgram(id);
}

