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