/*
Copyright 2022 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */

package com.funguscow.sw_rend

import android.graphics.SurfaceTexture
import android.opengl.*
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.util.concurrent.Semaphore

class EglContext {

    companion object {
        // Pass through position and UV values
        val vertexSource = """
            #version 300 es
            precision mediump float;
            
            /*layout(location = 0)*/ in vec2 position;
            /*layout(location = 1)*/ in vec2 uv;
            
            out vec2 uvOut;
            
            void main() {
                gl_Position = vec4(position, -0.5, 1.0);
                uvOut = vec2(uv.x, 1.0 - uv.y);
            }
        """.trimIndent()

        // Eventually get the texture value, for now, just make it cyan so I can see it
        val fragmentSource = """
            #version 300 es
            precision mediump float;
            
            in vec2 uvOut;
            
            out vec4 fragColor;
            
            uniform sampler2D tex;
            
            void main() {
                vec4 texel = texture(tex, uvOut);
                fragColor = texel;
            }
        """.trimIndent()

        var glThread: HandlerThread? = null
        var glHandler: Handler? = null
    }

    private var display = EGL14.EGL_NO_DISPLAY
    private var context = EGL14.EGL_NO_CONTEXT
    private var config: EGLConfig? = null

    private var vertexBuffer: FloatBuffer
    private var uvBuffer: FloatBuffer

    private var defaultProgram: Int = -1
    private var uniformTextureLocation: Int = -1
    private var vertexLocation: Int = -1
    private var uvLocation: Int = -1

    private fun checkGlError(msg: String) {
        val errCodeEgl = EGL14.eglGetError()
        val errCodeGl = GLES30.glGetError()
        if (errCodeEgl != EGL14.EGL_SUCCESS || errCodeGl != GLES30.GL_NO_ERROR) {
            throw RuntimeException(
                "$msg - $errCodeEgl(${GLU.gluErrorString(errCodeEgl)}) : $errCodeGl(${
                    GLU.gluErrorString(
                        errCodeGl
                    )
                })"
            )
        }
    }

    init {
        // Flat square
        val vertices = floatArrayOf(-1f, -1f, 1f, -1f, -1f, 1f, 1f, 1f)
        vertexBuffer = ByteBuffer.allocateDirect(vertices.size * 4).order(ByteOrder.nativeOrder())
            .asFloatBuffer().also {
                it.put(vertices)
                it.position(0)
            }
        val uv = floatArrayOf(0f, 0f, 1f, 0f, 0f, 1f, 1f, 1f)
        uvBuffer =
            ByteBuffer.allocateDirect(uv.size * 4).order(ByteOrder.nativeOrder()).asFloatBuffer()
                .also {
                    it.put(uv)
                    it.position(0)
                }

        if (glThread == null) {
            glThread = HandlerThread("flutterSoftwareRendererPlugin")
            glThread!!.start()
            glHandler = Handler(glThread!!.looper)
        }
    }

    // Run OpenGL code on a separate thread to keep the context available
    private fun doOnGlThread(blocking: Boolean = true, task: () -> Unit) {
        val semaphore: Semaphore? = if (blocking) Semaphore(0) else null
        glHandler!!.post {
            task.invoke()
            semaphore?.release()
        }
        semaphore?.acquire()
    }

    fun setup() {
        doOnGlThread {
            Log.d("Native", "Setting up EglContext")

            display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
            if (display == EGL14.EGL_NO_DISPLAY) {
                checkGlError("Failed to get display")
            }

            val versionBuffer = IntArray(2)
            if (!EGL14.eglInitialize(display, versionBuffer, 0, versionBuffer, 1)) {
                checkGlError("Failed to initialize")
            }

            val configs = arrayOfNulls<EGLConfig>(1)
            val configNumBuffer = IntArray(1)
            var attrBuffer = intArrayOf(
                EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                EGL14.EGL_RED_SIZE, 8,
                EGL14.EGL_GREEN_SIZE, 8,
                EGL14.EGL_BLUE_SIZE, 8,
                EGL14.EGL_ALPHA_SIZE, 8,
                EGL14.EGL_DEPTH_SIZE, 16,
                //EGL14.EGL_STENCIL_SIZE, 8,
                //EGL14.EGL_SAMPLE_BUFFERS, 1,
                //EGL14.EGL_SAMPLES, 4,
                EGL14.EGL_NONE
            )
            if (!EGL14.eglChooseConfig(
                    display,
                    attrBuffer,
                    0,
                    configs,
                    0,
                    configs.size,
                    configNumBuffer,
                    0
                )
            ) {
                checkGlError("Failed to choose a config")
            }
            if (configNumBuffer[0] == 0) {
                checkGlError("Got zero configs")
            }

            config = configs[0]
            attrBuffer = intArrayOf(
                EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL14.EGL_NONE
            )
            context = EGL14.eglCreateContext(display, config, EGL14.EGL_NO_CONTEXT, attrBuffer, 0)
            if (context == EGL14.EGL_NO_CONTEXT) {
                Log.e("Native", "Failed to get any context")
                checkGlError("Failed to get context")
            }
        }
    }

    // Called by my plugin to get a surface to register for Texture widget
    fun buildSurfaceTextureWindow(surfaceTexture: SurfaceTexture): EGLSurface {
        var outerSurface: EGLSurface? = null
        doOnGlThread {
            val attribBuffer = intArrayOf(EGL14.EGL_NONE)
            val surface =
                EGL14.eglCreateWindowSurface(display, config, surfaceTexture, attribBuffer, 0)
            if (surface == EGL14.EGL_NO_SURFACE) {
                checkGlError("Obtained no surface")
            }

            EGL14.eglMakeCurrent(display, surface, surface, context)
            if (defaultProgram == -1) {
                defaultProgram = makeProgram(
                    mapOf(
                        GLES30.GL_VERTEX_SHADER to vertexSource,
                        GLES30.GL_FRAGMENT_SHADER to fragmentSource
                    )
                )
                uniformTextureLocation = GLES30.glGetUniformLocation(defaultProgram, "tex")
                vertexLocation = GLES30.glGetAttribLocation(defaultProgram, "position")
                checkGlError("Getting attribute locations")

                uvLocation = GLES30.glGetAttribLocation(defaultProgram, "uv")
                checkGlError("Getting uniform location")
            }
            outerSurface = surface
        }
        return outerSurface!!
    }

    fun makeCurrent(eglSurface: EGLSurface, width: Int, height: Int) {
        doOnGlThread {
            GLES30.glViewport(0, 0, width, height)
            if (!EGL14.eglMakeCurrent(display, eglSurface, eglSurface, context)) {
                checkGlError("Failed to make surface current")
            }
        }
    }

    fun makeTexture(width: Int, height: Int): Int {
        var outerTexture: Int? = null
        doOnGlThread {
            val intArr = IntArray(1)
            GLES30.glGenTextures(1, intArr, 0)
            checkGlError("Generate texture")

            val texture = intArr[0]
            GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, texture)
            checkGlError("Bind texture")

            GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_MIN_FILTER, GLES30.GL_NEAREST)
            GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_MAG_FILTER, GLES30.GL_NEAREST)
            GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_WRAP_S, GLES30.GL_CLAMP_TO_EDGE)
            GLES30.glTexParameteri(GLES30.GL_TEXTURE_2D, GLES30.GL_TEXTURE_WRAP_T, GLES30.GL_CLAMP_TO_EDGE)
            checkGlError("Set texture parameters")

            val buffer =
                ByteBuffer.allocateDirect(width * height * 4).order(ByteOrder.nativeOrder())
            GLES30.glTexImage2D(
                GLES30.GL_TEXTURE_2D,
                0,
                GLES30.GL_RGBA,
                width,
                height,
                0,
                GLES30.GL_RGBA,
                GLES30.GL_UNSIGNED_BYTE,
                buffer
            )
            checkGlError("Create texture buffer")

            outerTexture = texture
        }
        return outerTexture!!
    }

    private fun compileShader(source: String, shaderType: Int): Int {
        val shaderId = GLES30.glCreateShader(shaderType)
        checkGlError("Create shader")

        if (shaderId == 0) {
            Log.e("Native", "Could not create shader for some reason")
            checkGlError("Could not create shader")
        }

        GLES30.glShaderSource(shaderId, source)
        checkGlError("Setting shader source")

        GLES30.glCompileShader(shaderId)
        checkGlError("Compile shader")

        val statusBuffer = IntArray(1)
        GLES30.glGetShaderiv(shaderId, GLES30.GL_COMPILE_STATUS, statusBuffer, 0)
        val shaderLog = GLES30.glGetShaderInfoLog(shaderId)
        Log.d("Native", "Compiling shader #$shaderId : $shaderLog")

        if (statusBuffer[0] == 0) {
            GLES30.glDeleteShader(shaderId)
            checkGlError("Failed to compile shader $shaderId")
        }
        return shaderId
    }

    private fun makeProgram(sources: Map<Int, String>): Int {
        val program = GLES30.glCreateProgram()
        checkGlError("Create program")
        sources.forEach {
            val shader = compileShader(it.value, it.key)
            GLES30.glAttachShader(program, shader)
        }
        val linkBuffer = IntArray(1)
        GLES30.glLinkProgram(program)
        checkGlError("Link program")

        GLES30.glGetProgramiv(program, GLES30.GL_LINK_STATUS, linkBuffer, 0)
        val programLog = GLES30.glGetProgramInfoLog(program)
        Log.d("Native", "Linking program #$program : $programLog")

        if (linkBuffer[0] == 0) {
            GLES30.glDeleteProgram(program)
            checkGlError("Failed to link program $program")
        }
        return program
    }

    // Called to actually draw to the surface. When fully implemented it should draw whatever is
    // on the associated texture, but for now, to debug, I just want to verify I can draw vertices,
    // but it seems I cannot?
    fun drawTextureToCurrentSurface(texture: Int, surface: EGLSurface) {
        doOnGlThread {
            GLES30.glClearColor(0f, 0f, 0f, 0f)
            GLES30.glClear(GLES30.GL_COLOR_BUFFER_BIT)
            checkGlError("Clear screen")

            GLES30.glUseProgram(defaultProgram)
            checkGlError("Set shader program")

            GLES30.glActiveTexture(GLES30.GL_TEXTURE0)
            GLES30.glEnable(GLES30.GL_TEXTURE_2D)
            checkGlError("Activate texture 0")
            GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, texture)
            checkGlError("Binding texture $texture")
            GLES30.glUniform1i(uniformTextureLocation, 0)
            checkGlError("Set texture uniform")

            GLES30.glEnableVertexAttribArray(vertexLocation)
            vertexBuffer.position(0)
            GLES30.glVertexAttribPointer(vertexLocation, 2, GLES30.GL_FLOAT, false, 0, vertexBuffer)
            checkGlError("Enable Attribute 0")

            GLES30.glEnableVertexAttribArray(uvLocation)
            uvBuffer.position(0)
            GLES30.glVertexAttribPointer(uvLocation, 2, GLES30.GL_FLOAT, false, 0, uvBuffer)
            checkGlError("Enable Attribute 1")

            //indexBuffer.position(0)
            //GLES30.glDrawElements(GLES30.GL_TRIANGLES, 4, GLES30.GL_UNSIGNED_INT, indexBuffer)
            // I would expect to get a triangle of different color than the background
            GLES30.glDrawArrays(GLES30.GL_TRIANGLE_STRIP, 0, 4)
            checkGlError("Draw arrays")
            GLES30.glFinish()
            checkGlError("Finished GL")

            EGL14.eglSwapBuffers(display, surface)
            checkGlError("Swapped buffers")
        }
    }

    fun blit(textureId: Int, x: Int, y: Int, width: Int, height: Int, data: ByteArray) {
        doOnGlThread {
            val buffer = ByteBuffer.allocateDirect(data.size).order(ByteOrder.nativeOrder()).also {
                it.position(0)
                it.put(data)
                it.position(0)
            }
            GLES30.glBindTexture(GLES30.GL_TEXTURE_2D, textureId)
            GLES30.glTexSubImage2D(
                GLES30.GL_TEXTURE_2D,
                0,
                x,
                y,
                width,
                height,
                GLES30.GL_RGBA,
                GLES30.GL_UNSIGNED_BYTE,
                buffer
            )
            checkGlError("Texture buffer subregion")
        }
    }

    fun readPixels(width: Int, height: Int): ByteArray {
        var outerArray: ByteArray? = null
        doOnGlThread {
            val buffer = ByteBuffer.allocateDirect(width * height * 4)
            val array = ByteArray(width * height * 4)
            GLES30.glReadPixels(
                0,
                0,
                width,
                height,
                GLES30.GL_RGBA,
                GLES30.GL_UNSIGNED_BYTE,
                buffer
            )
            buffer.position(0)
            buffer.get(array)
            outerArray = array
        }
        return outerArray!!
    }

    fun deleteTex(textureId: Int) {
        doOnGlThread { GLES30.glDeleteTextures(1, intArrayOf(textureId), 0) }
    }

    fun dispose() {
        doOnGlThread { GLES30.glDeleteProgram(defaultProgram) }
    }

}