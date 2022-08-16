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
import androidx.annotation.NonNull
import io.flutter.Log

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry

/** TestNativePlugin */
class SwRendPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var textureRegistry: TextureRegistry
  private val methods = mapOf<String, (MethodCall, Result) -> Unit>(
    "init" to this::initializeTexture,
    "draw" to this::drawToTexture,
    "invalidate" to this::invalidate,
    "get_pixels" to this::readPixels,
    "get_size" to this::getSize,
    "list_textures" to this::listTextures,
    "dispose" to this::dispose,
  )
  private val textures = mutableMapOf<Long, BufferedSurface>()

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    BufferedSurface.eglContext.setup()

    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.funguscow/sw_rend")
    channel.setMethodCallHandler(this)
    Log.d("Native", "Created channel for android")

    textureRegistry = flutterPluginBinding.textureRegistry
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
        in methods -> {
          methods[call.method]?.invoke(call, result)
        }
        else -> {
          result.notImplemented()
        }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    BufferedSurface.eglContext.dispose()
  }

  private fun initializeTexture(call: MethodCall, result: Result) {
    val width = call.argument<Int>("width") ?: 0
    val height = call.argument<Int>("height") ?: 0
    val texture = BufferedSurface(width, height, textureRegistry)
    textures[texture.textureId] = texture
    result.success(texture.textureId)
  }

  private fun drawToTexture(call: MethodCall, result: Result) {
    val x = call.argument<Int>("x") ?: 0
    val y = call.argument<Int>("y") ?: 0
    val width = call.argument<Int>("width") ?: -1
    val height = call.argument<Int>("height") ?: -1
    val textureId = call.argument<Int>("texture")?.toLong() ?: -1
    val data = call.argument<ByteArray>("pixels")!!
    if (textureId !in textures) {
      result.error("NO_TEX", "No texture with id $textureId", null)
      return
    }
    val texture = textures[textureId]!!
    texture.blit(data, Rect(x, y, width, height))
    result.success(null)
  }

  private fun invalidate(call: MethodCall, result: Result) {
    val textureId = call.argument<Int>("texture")?.toLong() ?: -1
    if (textureId !in textures) {
      result.error("NO_TEX", "No texture with id $textureId", null)
      return
    }
    val texture = textures[textureId]!!
    texture.drawToScreen()
    result.success(null)
  }

  private fun readPixels(call: MethodCall, result: Result) {
    val textureId = call.argument<Int>("texture")?.toLong() ?: -1
    if (textureId !in textures) {
      result.error("NO_TEX", "No texture with id $textureId", null)
      return
    }
    val texture = textures[textureId]!!
    result.success(texture.read())
  }

  private fun getSize(call: MethodCall, result: Result) {
    val textureId = call.argument<Int>("texture")?.toLong() ?: -1
    if (textureId !in textures) {
      result.error("NO_TEX", "No texture with id $textureId", null)
      return
    }
    val texture = textures[textureId]!!
    result.success(intArrayOf(texture.width, texture.height))
  }

  private fun dispose(call: MethodCall, result: Result) {
    val textureId = call.argument<Int>("texture")?.toLong() ?: -1
    if (textureId !in textures) {
      result.error("NO_TEX", "No texture with id $textureId", null)
      return
    }
    val texture = textures[textureId]!!
    texture.dispose()
    result.success(null)
  }

  private fun listTextures(call: MethodCall, result: Result) {
    result.success(textures.keys.toLongArray())
  }
}
