package com.funguscow.sw_rend

import android.graphics.Rect
import android.graphics.SurfaceTexture
import android.opengl.EGLSurface
import io.flutter.Log
import io.flutter.view.TextureRegistry

class BufferedSurface(val width: Int, val height: Int, textureRegistry: TextureRegistry) {
    companion object {
        val eglContext = EglContext()
    }

    private val eglSurface: EGLSurface
    private val surfaceTexture: SurfaceTexture

    val textureId: Long
    private val glTextureId: Int

    init {
        val entry = textureRegistry.createSurfaceTexture()
        surfaceTexture = entry.surfaceTexture()
        surfaceTexture.setDefaultBufferSize(width, height)
        textureId = entry.id()
        Log.d("Native", "Generated texture = $textureId")
        eglSurface = eglContext.buildSurfaceTextureWindow(surfaceTexture)
        glTextureId = eglContext.makeTexture(width, height)
    }

    fun drawToScreen() {
        eglContext.makeCurrent(eglSurface, width, height)
        eglContext.drawTextureToCurrentSurface(glTextureId, eglSurface)
    }

    fun blit(data: ByteArray, boundsIn: Rect = Rect(0, 0, width, height)) {
        eglContext.blit(glTextureId, boundsIn.left, boundsIn.top, boundsIn.right, boundsIn.bottom, data)
    }

    fun dispose() {
        eglContext.deleteTex(glTextureId)
    }

    fun read() : ByteArray {
        eglContext.makeCurrent(eglSurface, width, height)
        return eglContext.readPixels(width, height)
    }

}