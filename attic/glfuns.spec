void activeTexture(GLenum texture);1
void attachShader(WebGLProgram program, WebGLShader shader);1
void bindAttribLocation(WebGLProgram program, GLuint index, DOMString name);1
void bindBuffer(GLenum target, WebGLBuffer? buffer);1
void bindFramebuffer(GLenum target, WebGLFramebuffer? framebuffer);1
void bindRenderbuffer(GLenum target, WebGLRenderbuffer? renderbuffer);1
void bindTexture(GLenum target, WebGLTexture? texture);1
void blendColor(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);1
void blendEquation(GLenum mode);1
void blendEquationSeparate(GLenum modeRGB, GLenum modeAlpha);1
void blendFunc(GLenum sfactor, GLenum dfactor);1
void blendFuncSeparate(GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);1
GLenum checkFramebufferStatus(GLenum target);1
void clear(GLbitfield mask);1
void clearColor(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);1
void clearDepth(GLclampf depth);1
void clearStencil(GLint s);1
void colorMask(GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha);1
void compileShader(WebGLShader shader);1
void copyTexImage2D(GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);1
void copyTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);1
WebGLBuffer? createBuffer();1
WebGLFramebuffer? createFramebuffer();1
WebGLProgram? createProgram();1
WebGLRenderbuffer? createRenderbuffer();1
WebGLShader? createShader(GLenum type);1
WebGLTexture? createTexture();1
void cullFace(GLenum mode);1
void deleteBuffer(WebGLBuffer? buffer);1
void deleteFramebuffer(WebGLFramebuffer? framebuffer);1
void deleteProgram(WebGLProgram? program);1
void deleteRenderbuffer(WebGLRenderbuffer? renderbuffer);1
void deleteShader(WebGLShader? shader);1
void deleteTexture(WebGLTexture? texture);1
void depthFunc(GLenum func);1
void depthMask(GLboolean flag);1
void depthRange(GLclampf zNear, GLclampf zFar);1
void detachShader(WebGLProgram program, WebGLShader shader);1
void disable(GLenum cap);1
void disableVertexAttribArray(GLuint index);1
void drawArrays(GLenum mode, GLint first, GLsizei count);1
void drawElements(GLenum mode, GLsizei count, GLenum type, GLintptr offset);1
void enable(GLenum cap);1
void enableVertexAttribArray(GLuint index);1
void finish();1
void flush();1
void framebufferRenderbuffer(GLenum target, GLenum attachment, GLenum renderbuffertarget, WebGLRenderbuffer? renderbuffer);1
void framebufferTexture2D(GLenum target, GLenum attachment, GLenum textarget, WebGLTexture? texture, GLint level);1
void frontFace(GLenum mode);1
void generateMipmap(GLenum target);1
WebGLActiveInfo? getActiveAttrib(WebGLProgram program, GLuint index);1
WebGLActiveInfo? getActiveUniform(WebGLProgram program, GLuint index);1
sequence<WebGLShader>? getAttachedShaders(WebGLProgram program);1
GLint getAttribLocation(WebGLProgram program, DOMString name);1
any getBufferParameter(GLenum target, GLenum pname);1
any getParameter(GLenum pname);1
GLenum getError();1
any getFramebufferAttachmentParameter(GLenum target, GLenum attachment, GLenum pname);1
any getProgramParameter(WebGLProgram program, GLenum pname);1
DOMString? getProgramInfoLog(WebGLProgram program);1
any getRenderbufferParameter(GLenum target, GLenum pname);1
any getShaderParameter(WebGLShader shader, GLenum pname);1
WebGLShaderPrecisionFormat? getShaderPrecisionFormat(GLenum shadertype, GLenum precisiontype);1
DOMString? getShaderInfoLog(WebGLShader shader);1
DOMString? getShaderSource(WebGLShader shader);1
any getTexParameter(GLenum target, GLenum pname);1
any getUniform(WebGLProgram program, WebGLUniformLocation location);1
WebGLUniformLocation? getUniformLocation(WebGLProgram program, DOMString name);1
any getVertexAttrib(GLuint index, GLenum pname);1
GLintptr getVertexAttribOffset(GLuint index, GLenum pname);1
void hint(GLenum target, GLenum mode);1
GLboolean isBuffer(WebGLBuffer? buffer);1
GLboolean isEnabled(GLenum cap);1
GLboolean isFramebuffer(WebGLFramebuffer? framebuffer);1
GLboolean isProgram(WebGLProgram? program);1
GLboolean isRenderbuffer(WebGLRenderbuffer? renderbuffer);1
GLboolean isShader(WebGLShader? shader);1
GLboolean isTexture(WebGLTexture? texture);1
void lineWidth(GLfloat width);1
void linkProgram(WebGLProgram program);1
void pixelStorei(GLenum pname, GLint param);1
void polygonOffset(GLfloat factor, GLfloat units);1
void renderbufferStorage(GLenum target, GLenum internalformat, GLsizei width, GLsizei height);1
void sampleCoverage(GLclampf value, GLboolean invert);1
void scissor(GLint x, GLint y, GLsizei width, GLsizei height);1
void shaderSource(WebGLShader shader, DOMString source);1
void stencilFunc(GLenum func, GLint ref, GLuint mask);1
void stencilFuncSeparate(GLenum face, GLenum func, GLint ref, GLuint mask);1
void stencilMask(GLuint mask);1
void stencilMaskSeparate(GLenum face, GLuint mask);1
void stencilOp(GLenum fail, GLenum zfail, GLenum zpass);1
void stencilOpSeparate(GLenum face, GLenum fail, GLenum zfail, GLenum zpass);1
void texParameterf(GLenum target, GLenum pname, GLfloat param);1
void texParameteri(GLenum target, GLenum pname, GLint param);1
void uniform1f(WebGLUniformLocation? location, GLfloat x);1
void uniform2f(WebGLUniformLocation? location, GLfloat x, GLfloat y);1
void uniform3f(WebGLUniformLocation? location, GLfloat x, GLfloat y, GLfloat z);1
void uniform4f(WebGLUniformLocation? location, GLfloat x, GLfloat y, GLfloat z, GLfloat w);1
void uniform1i(WebGLUniformLocation? location, GLint x);1
void uniform2i(WebGLUniformLocation? location, GLint x, GLint y);1
void uniform3i(WebGLUniformLocation? location, GLint x, GLint y, GLint z);1
void uniform4i(WebGLUniformLocation? location, GLint x, GLint y, GLint z, GLint w);1
void useProgram(WebGLProgram? program);1
void validateProgram(WebGLProgram program);1
void vertexAttrib1f(GLuint index, GLfloat x);1
void vertexAttrib2f(GLuint index, GLfloat x, GLfloat y);1
void vertexAttrib3f(GLuint index, GLfloat x, GLfloat y, GLfloat z);1
void vertexAttrib4f(GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);1
void vertexAttrib1fv(GLuint index, Float32List values);1
void vertexAttrib2fv(GLuint index, Float32List values);1
void vertexAttrib3fv(GLuint index, Float32List values);1
void vertexAttrib4fv(GLuint index, Float32List values);1
void vertexAttribPointer(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, GLintptr offset);1
void viewport(GLint x, GLint y, GLsizei width, GLsizei height);1


void activeTexture(GLenum texture);2
void attachShader(WebGLProgram program, WebGLShader shader);2
void bindAttribLocation(WebGLProgram program, GLuint index, DOMString name);2
void bindBuffer(GLenum target, WebGLBuffer? buffer);2
void bindFramebuffer(GLenum target, WebGLFramebuffer? framebuffer);2
void bindRenderbuffer(GLenum target, WebGLRenderbuffer? renderbuffer);2
void bindTexture(GLenum target, WebGLTexture? texture);2
void blendColor(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);2
void blendEquation(GLenum mode);2
void blendEquationSeparate(GLenum modeRGB, GLenum modeAlpha);2
void blendFunc(GLenum sfactor, GLenum dfactor);2
void blendFuncSeparate(GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);2
GLenum checkFramebufferStatus(GLenum target);2
void clear(GLbitfield mask);2
void clearColor(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);2
void clearDepth(GLclampf depth);2
void clearStencil(GLint s);2
void colorMask(GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha);2
void compileShader(WebGLShader shader);2
void copyTexImage2D(GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);2
void copyTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);2
WebGLBuffer? createBuffer();2
WebGLFramebuffer? createFramebuffer();2
WebGLProgram? createProgram();2
WebGLRenderbuffer? createRenderbuffer();2
WebGLShader? createShader(GLenum type);2
WebGLTexture? createTexture();2
void cullFace(GLenum mode);2
void deleteBuffer(WebGLBuffer? buffer);2
void deleteFramebuffer(WebGLFramebuffer? framebuffer);2
void deleteProgram(WebGLProgram? program);2
void deleteRenderbuffer(WebGLRenderbuffer? renderbuffer);2
void deleteShader(WebGLShader? shader);2
void deleteTexture(WebGLTexture? texture);2
void depthFunc(GLenum func);2
void depthMask(GLboolean flag);2
void depthRange(GLclampf zNear, GLclampf zFar);2
void detachShader(WebGLProgram program, WebGLShader shader);2
void disable(GLenum cap);2
void disableVertexAttribArray(GLuint index);2
void drawArrays(GLenum mode, GLint first, GLsizei count);2
void drawElements(GLenum mode, GLsizei count, GLenum type, GLintptr offset);2
void enable(GLenum cap);2
void enableVertexAttribArray(GLuint index);2
void finish();2
void flush();2
void framebufferRenderbuffer(GLenum target, GLenum attachment, GLenum renderbuffertarget, WebGLRenderbuffer? renderbuffer);2
void framebufferTexture2D(GLenum target, GLenum attachment, GLenum textarget, WebGLTexture? texture, GLint level);2
void frontFace(GLenum mode);2
void generateMipmap(GLenum target);2
WebGLActiveInfo? getActiveAttrib(WebGLProgram program, GLuint index);2
WebGLActiveInfo? getActiveUniform(WebGLProgram program, GLuint index);2
sequence<WebGLShader>? getAttachedShaders(WebGLProgram program);2
GLint getAttribLocation(WebGLProgram program, DOMString name);2
any getBufferParameter(GLenum target, GLenum pname);2
any getParameter(GLenum pname);2
GLenum getError();2
any getFramebufferAttachmentParameter(GLenum target, GLenum attachment, GLenum pname);2
any getProgramParameter(WebGLProgram program, GLenum pname);2
DOMString? getProgramInfoLog(WebGLProgram program);2
any getRenderbufferParameter(GLenum target, GLenum pname);2
any getShaderParameter(WebGLShader shader, GLenum pname);2
WebGLShaderPrecisionFormat? getShaderPrecisionFormat(GLenum shadertype, GLenum precisiontype);2
DOMString? getShaderInfoLog(WebGLShader shader);2
DOMString? getShaderSource(WebGLShader shader);2
any getTexParameter(GLenum target, GLenum pname);2
any getUniform(WebGLProgram program, WebGLUniformLocation location);2
WebGLUniformLocation? getUniformLocation(WebGLProgram program, DOMString name);2
any getVertexAttrib(GLuint index, GLenum pname);2
GLintptr getVertexAttribOffset(GLuint index, GLenum pname);2
void hint(GLenum target, GLenum mode);2
GLboolean isBuffer(WebGLBuffer? buffer);2
GLboolean isEnabled(GLenum cap);2
GLboolean isFramebuffer(WebGLFramebuffer? framebuffer);2
GLboolean isProgram(WebGLProgram? program);2
GLboolean isRenderbuffer(WebGLRenderbuffer? renderbuffer);2
GLboolean isShader(WebGLShader? shader);2
GLboolean isTexture(WebGLTexture? texture);2
void lineWidth(GLfloat width);2
void linkProgram(WebGLProgram program);2
void pixelStorei(GLenum pname, GLint param);2
void polygonOffset(GLfloat factor, GLfloat units);2
void renderbufferStorage(GLenum target, GLenum internalformat, GLsizei width, GLsizei height);2
void sampleCoverage(GLclampf value, GLboolean invert);2
void scissor(GLint x, GLint y, GLsizei width, GLsizei height);2
void shaderSource(WebGLShader shader, DOMString source);2
void stencilFunc(GLenum func, GLint ref, GLuint mask);2
void stencilFuncSeparate(GLenum face, GLenum func, GLint ref, GLuint mask);2
void stencilMask(GLuint mask);2
void stencilMaskSeparate(GLenum face, GLuint mask);2
void stencilOp(GLenum fail, GLenum zfail, GLenum zpass);2
void stencilOpSeparate(GLenum face, GLenum fail, GLenum zfail, GLenum zpass);2
void texParameterf(GLenum target, GLenum pname, GLfloat param);2
void texParameteri(GLenum target, GLenum pname, GLint param);2
void uniform1f(WebGLUniformLocation? location, GLfloat x);2
void uniform2f(WebGLUniformLocation? location, GLfloat x, GLfloat y);2
void uniform3f(WebGLUniformLocation? location, GLfloat x, GLfloat y, GLfloat z);2
void uniform4f(WebGLUniformLocation? location, GLfloat x, GLfloat y, GLfloat z, GLfloat w);2
void uniform1i(WebGLUniformLocation? location, GLint x);2
void uniform2i(WebGLUniformLocation? location, GLint x, GLint y);2
void uniform3i(WebGLUniformLocation? location, GLint x, GLint y, GLint z);2
void uniform4i(WebGLUniformLocation? location, GLint x, GLint y, GLint z, GLint w);2
void useProgram(WebGLProgram? program);2
void validateProgram(WebGLProgram program);2
void vertexAttrib1f(GLuint index, GLfloat x);2
void vertexAttrib2f(GLuint index, GLfloat x, GLfloat y);2
void vertexAttrib3f(GLuint index, GLfloat x, GLfloat y, GLfloat z);2
void vertexAttrib4f(GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);2
void vertexAttrib1fv(GLuint index, Float32List values);2
void vertexAttrib2fv(GLuint index, Float32List values);2
void vertexAttrib3fv(GLuint index, Float32List values);2
void vertexAttrib4fv(GLuint index, Float32List values);2
void vertexAttribPointer(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, GLintptr offset);2
void viewport(GLint x, GLint y, GLsizei width, GLsizei height);2
void copyBufferSubData(GLenum readTarget, GLenum writeTarget, GLintptr readOffset, GLintptr writeOffset, GLsizeiptr size);2
void getBufferSubData(GLenum target, GLintptr srcByteOffset, ArrayBufferView dstBuffer, optional GLuint dstOffset = 0, optional GLuint length = 0);2
void blitFramebuffer(GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);2
void framebufferTextureLayer(GLenum target, GLenum attachment, WebGLTexture? texture, GLint level, GLint layer);2
void invalidateFramebuffer(GLenum target, sequence<GLenum> attachments);2
void invalidateSubFramebuffer(GLenum target, sequence<GLenum> attachments, GLint x, GLint y, GLsizei width, GLsizei height);2
void readBuffer(GLenum src);2
any getInternalformatParameter(GLenum target, GLenum internalformat, GLenum pname);2
void renderbufferStorageMultisample(GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height);2
void texStorage2D(GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height);2
void texStorage3D(GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth);2
void texImage3D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, GLintptr pboOffset);2
void texImage3D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, TexImageSource source);2
void texImage3D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, ArrayBufferView? srcData);2
void texImage3D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, ArrayBufferView srcData, GLuint srcOffset);2
void texSubImage3D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, GLintptr pboOffset);2
void texSubImage3D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, TexImageSource source);2
void texSubImage3D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, ArrayBufferView? srcData, optional GLuint srcOffset = 0);2
void copyTexSubImage3D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height);2
void compressedTexImage3D(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, GLintptr offset);2
void compressedTexImage3D(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, ArrayBufferView srcData, optional GLuint srcOffset = 0, optional GLuint srcLengthOverride = 0);2
void compressedTexSubImage3D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, GLintptr offset);2
void compressedTexSubImage3D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, ArrayBufferView srcData, optional GLuint srcOffset = 0, optional GLuint srcLengthOverride = 0);2
GLint getFragDataLocation(WebGLProgram program, DOMString name);2
void uniform1ui(WebGLUniformLocation? location, GLuint v0);2
void uniform2ui(WebGLUniformLocation? location, GLuint v0, GLuint v1);2
void uniform3ui(WebGLUniformLocation? location, GLuint v0, GLuint v1, GLuint v2);2
void uniform4ui(WebGLUniformLocation? location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);2
void uniform1uiv(WebGLUniformLocation? location, Uint32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniform2uiv(WebGLUniformLocation? location, Uint32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniform3uiv(WebGLUniformLocation? location, Uint32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniform4uiv(WebGLUniformLocation? location, Uint32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniformMatrix3x2fv(WebGLUniformLocation? location, GLboolean transpose, Float32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniformMatrix4x2fv(WebGLUniformLocation? location, GLboolean transpose, Float32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniformMatrix2x3fv(WebGLUniformLocation? location, GLboolean transpose, Float32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniformMatrix4x3fv(WebGLUniformLocation? location, GLboolean transpose, Float32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniformMatrix2x4fv(WebGLUniformLocation? location, GLboolean transpose, Float32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniformMatrix3x4fv(WebGLUniformLocation? location, GLboolean transpose, Float32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void vertexAttribI4i(GLuint index, GLint x, GLint y, GLint z, GLint w);2
void vertexAttribI4iv(GLuint index, Int32List values);2
void vertexAttribI4ui(GLuint index, GLuint x, GLuint y, GLuint z, GLuint w);2
void vertexAttribI4uiv(GLuint index, Uint32List values);2
void vertexAttribIPointer(GLuint index, GLint size, GLenum type, GLsizei stride, GLintptr offset);2
void vertexAttribDivisor(GLuint index, GLuint divisor);2
void drawArraysInstanced(GLenum mode, GLint first, GLsizei count, GLsizei instanceCount);2
void drawElementsInstanced(GLenum mode, GLsizei count, GLenum type, GLintptr offset, GLsizei instanceCount);2
void drawRangeElements(GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, GLintptr offset);2
void drawBuffers(sequence<GLenum> buffers);2
void clearBufferfv(GLenum buffer, GLint drawbuffer, Float32List values, optional GLuint srcOffset = 0);2
void clearBufferiv(GLenum buffer, GLint drawbuffer, Int32List values, optional GLuint srcOffset = 0);2
void clearBufferuiv(GLenum buffer, GLint drawbuffer, Uint32List values, optional GLuint srcOffset = 0);2
void clearBufferfi(GLenum buffer, GLint drawbuffer, GLfloat depth, GLint stencil);2
WebGLQuery? createQuery();2
void deleteQuery(WebGLQuery? query);2
GLboolean isQuery(WebGLQuery? query);2
void beginQuery(GLenum target, WebGLQuery query);2
void endQuery(GLenum target);2
WebGLQuery? getQuery(GLenum target, GLenum pname);2
any getQueryParameter(WebGLQuery query, GLenum pname);2
WebGLSampler? createSampler();2
void deleteSampler(WebGLSampler? sampler);2
GLboolean isSampler(WebGLSampler? sampler);2
void bindSampler(GLuint unit, WebGLSampler? sampler);2
void samplerParameteri(WebGLSampler sampler, GLenum pname, GLint param);2
void samplerParameterf(WebGLSampler sampler, GLenum pname, GLfloat param);2
any getSamplerParameter(WebGLSampler sampler, GLenum pname);2
WebGLSync? fenceSync(GLenum condition, GLbitfield flags);2
void deleteSync(WebGLSync? sync);2
GLenum clientWaitSync(WebGLSync sync, GLbitfield flags, GLuint64 timeout);2
void waitSync(WebGLSync sync, GLbitfield flags, GLint64 timeout);2
any getSyncParameter(WebGLSync sync, GLenum pname);2
WebGLTransformFeedback? createTransformFeedback();2
void deleteTransformFeedback(WebGLTransformFeedback? tf);2
GLboolean isTransformFeedback(WebGLTransformFeedback? tf);2
void bindTransformFeedback (GLenum target, WebGLTransformFeedback? tf);2
void beginTransformFeedback(GLenum primitiveMode);2
void endTransformFeedback();2
void transformFeedbackVaryings(WebGLProgram program, sequence<DOMString> varyings, GLenum bufferMode);2
WebGLActiveInfo? getTransformFeedbackVarying(WebGLProgram program, GLuint index);2
void pauseTransformFeedback();2
void resumeTransformFeedback();2
void bindBufferBase(GLenum target, GLuint index, WebGLBuffer? buffer);2
void bindBufferRange(GLenum target, GLuint index, WebGLBuffer? buffer, GLintptr offset, GLsizeiptr size);2
any getIndexedParameter(GLenum target, GLuint index);2
sequence<GLuint>? getUniformIndices(WebGLProgram program, sequence<DOMString> uniformNames);2
any getActiveUniforms(WebGLProgram program, sequence<GLuint> uniformIndices, GLenum pname);2
GLuint getUniformBlockIndex(WebGLProgram program, DOMString uniformBlockName);2
any getActiveUniformBlockParameter(WebGLProgram program, GLuint uniformBlockIndex, GLenum pname);2
DOMString? getActiveUniformBlockName(WebGLProgram program, GLuint uniformBlockIndex);2
void uniformBlockBinding(WebGLProgram program, GLuint uniformBlockIndex, GLuint uniformBlockBinding);2
WebGLVertexArrayObject? createVertexArray();2
void deleteVertexArray(WebGLVertexArrayObject? vertexArray);2
GLboolean isVertexArray(WebGLVertexArrayObject? vertexArray);2
void bindVertexArray(WebGLVertexArrayObject? array);2

void bufferData(GLenum target, GLsizeiptr size, GLenum usage);2
void bufferData(GLenum target, BufferSource? srcData, GLenum usage);2
void bufferSubData(GLenum target, GLintptr dstByteOffset, BufferSource srcData);2
void bufferData(GLenum target, ArrayBufferView srcData, GLenum usage, GLuint srcOffset, optional GLuint length = 0);2
void bufferSubData(GLenum target, GLintptr dstByteOffset, ArrayBufferView srcData, GLuint srcOffset, optional GLuint length = 0);2
void texImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, ArrayBufferView? pixels);2
void texImage2D(GLenum target, GLint level, GLint internalformat, GLenum format, GLenum type, TexImageSource source);2
void texSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, ArrayBufferView? pixels);2
void texSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLenum format, GLenum type, TexImageSource source);2
void texImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, GLintptr pboOffset);2
void texImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, TexImageSource source);2
void texImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, ArrayBufferView srcData, GLuint srcOffset);2
void texSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, GLintptr pboOffset);2
void texSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, TexImageSource source);2
void texSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, ArrayBufferView srcData, GLuint srcOffset);2
void compressedTexImage2D(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, GLintptr offset);2
void compressedTexImage2D(GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, ArrayBufferView srcData, optional GLuint srcOffset = 0, optional GLuint srcLengthOverride = 0);2
void compressedTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, GLintptr offset);2
void compressedTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, ArrayBufferView srcData, optional GLuint srcOffset = 0, optional GLuint srcLengthOverride = 0);2
void uniform1fv(WebGLUniformLocation? location, Float32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniform2fv(WebGLUniformLocation? location, Float32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniform3fv(WebGLUniformLocation? location, Float32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniform4fv(WebGLUniformLocation? location, Float32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniform1iv(WebGLUniformLocation? location, Int32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniform2iv(WebGLUniformLocation? location, Int32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniform3iv(WebGLUniformLocation? location, Int32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniform4iv(WebGLUniformLocation? location, Int32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniformMatrix2fv(WebGLUniformLocation? location, GLboolean transpose, Float32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniformMatrix3fv(WebGLUniformLocation? location, GLboolean transpose, Float32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void uniformMatrix4fv(WebGLUniformLocation? location, GLboolean transpose, Float32List data, optional GLuint srcOffset = 0, optional GLuint srcLength = 0);2
void readPixels(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, ArrayBufferView? dstData);2
void readPixels(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLintptr offset);2
void readPixels(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, ArrayBufferView dstData, GLuint dstOffset);2
