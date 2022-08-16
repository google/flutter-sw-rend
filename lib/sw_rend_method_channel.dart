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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sw_rend_platform_interface.dart';

/// An implementation of [SwRendPlatform] that uses method channels.
class MethodChannelTestNative extends SwRendPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.funguscow/sw_rend');


  @override
  Future<int?> init(int w, int h) async {
    return await methodChannel.invokeMethod<int>('init', <String, int>{'width': w, 'height': h});
  }

  @override
  Future<void> draw(int texId, int x, int y, int w, int h, Uint8List pixels) async {
    return await methodChannel.invokeMethod<void>('draw', <String, dynamic>{
      'x': x, 'y': y, 'width': w, 'height': h, 'pixels': pixels, 'texture': texId
    });
  }

  @override
  Future<Uint8List?> getPixels(int texId) async {
    return await methodChannel.invokeMethod<Uint8List>('get_pixels', <String, int>{'texture': texId});
  }

  @override
  Future<void> invalidate(int texId) async {
    return await methodChannel.invokeMethod<void>('invalidate', <String, int>{'texture': texId});
  }

  @override
  Future<Int32List?> getSize(int texId) async {
    return await methodChannel.invokeMethod<Int32List?>('get_size', <String, int>{'texture': texId});
  }

  @override
  Future<Int64List?> listTextures() async {
    return await methodChannel.invokeMethod<Int64List>('list_textures');
  }

  @override
  Future<void> dispose(int texId) async {
    return await methodChannel.invokeMethod<void>('dispose', <String, int>{'texture': texId});
  }

}
