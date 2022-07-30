
import 'dart:typed_data';

import 'test_native_platform_interface.dart';

class TestNative {
  Future<String?> getPlatformVersion() {
    return TestNativePlatform.instance.getPlatformVersion();
  }
  Future<String?> addNums(int a, int b) {
    return TestNativePlatform.instance.addNums(a, b);
    // return Future.value('70');
  }
  Future<int?> init(int w, int h) {
    return TestNativePlatform.instance.init(w, h);
  }
  Future<void> draw(int texId, int x, int y, int w, int h, Uint8List pixels) async {
    return TestNativePlatform.instance.draw(texId, x, y, w, h, pixels);
  }
  Future<Uint8List?> getPixels(int texId) {
    return TestNativePlatform.instance.getPixels(texId);
  }
  Future<void> invalidate(int texId) {
    return TestNativePlatform.instance.invalidate(texId);
  }
  Future<Int32List?> getSize(int texId) {
    return TestNativePlatform.instance.getSize(texId);
  }
  Future<Int64List?> listTextures() {
    return TestNativePlatform.instance.listTextures();
  }
  Future<void> dispose(int texId) {
    return TestNativePlatform.instance.dispose(texId);
  }
}
