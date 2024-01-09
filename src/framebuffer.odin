package tracer

import gl "vendor:OpenGL"

FrameBuffer :: struct {
	buf: uint,
	bind : proc(^FrameBuffer),
	delete: proc(^FrameBuffer),
}


frame_buffer_make :: proc(attachments: int, tex1: uint, tex2: uint) -> (frame: FrameBuffer) {
    using frame
	gl.GenFramebuffers(1, auto_cast &buf);
	gl.BindFramebuffer(gl.FRAMEBUFFER, auto_cast buf);
	gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, u32(tex1), 0);

	if attachments == 2 {
		gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT1, gl.TEXTURE_2D, u32(tex2), 0);
		colorAttachments : [2]u32 = { gl.COLOR_ATTACHMENT0, gl.COLOR_ATTACHMENT1 };
		gl.DrawBuffers(2, cast([^]u32) raw_data(&colorAttachments));

	}
  
  frame.bind  = proc(self: ^FrameBuffer) { gl.BindFramebuffer(gl.FRAMEBUFFER, cast(u32)self.buf) };
  frame.delete = proc(self: ^FrameBuffer) { gl.DeleteFramebuffers(1, cast(^u32)&self.buf); };
  return
}
