import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'test_native_platform_interface.dart';

/// An implementation of [TestNativePlatform] that uses method channels.
class MethodChannelTestNative extends TestNativePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.funguscow/sw_rend');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> addNums(int a, int b) async {
    return await methodChannel.invokeMethod<String>('add', <String, int>{'a': a, 'b': b});
  }

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

  Future<Int32List?> getSize(int texId) async {
    return await methodChannel.invokeMethod<Int32List?>('get_size', <String, int>{'texture': texId});
  }

  Future<Int64List?> listTextures() async {
    return await methodChannel.invokeMethod<Int64List>('list_textures');
  }

  Future<void> dispose(int texId) async {
    return await methodChannel.invokeMethod<void>('dispose', <String, int>{'texture': texId});
  }

}
