package tracer
import gl "vendor:OpenGL"
import glfw "vendor:glfw"


RectVAO :: struct {
	VAO, VBO : u32
};

rect_vao_make:: proc() -> (self: RectVAO) {
    using self
	// Vertices coordinates
	vertices := [?]f32{
		// Positions    // uv
		-1.0,  1.0,   0.0, 1.0, // let top
		-1.0, -1.0,   0.0, 0.0, // let bottom
			1.0, -1.0,   1.0, 0.0, // right bottom
    -1.0,  1.0,  0.0, 1.0, // let top
    1.0, -1.0,  1.0, 0.0, // right bottom
    1.0,  1.0,  1.0, 1.0  // right top
	}

	gl.GenVertexArrays(1, &VAO);
	gl.GenBuffers(1, &VBO);
	gl.BindVertexArray(VAO);
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO);
	gl.BufferData(gl.ARRAY_BUFFER, len(vertices), &vertices[0], gl.STATIC_DRAW);
	gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 4 * size_of(float), cast(uintptr)0);
	gl.EnableVertexAttribArray(0);
	gl.BindBuffer(gl.ARRAY_BUFFER, 0);
	gl.BindVertexArray(0);
    return
}

react_vao_delete :: proc(using self: ^RectVAO) {
	gl.DeleteVertexArrays(1, &VAO);
	gl.DeleteBuffers(1, &VBO);
}
