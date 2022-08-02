
import 'dart:typed_data';

import 'sw_rend_platform_interface.dart';

class SwRend {
  Future<String?> getPlatformVersion() {
    return SwRendPlatform.instance.getPlatformVersion();
  }
  Future<String?> addNums(int a, int b) {
    return SwRendPlatform.instance.addNums(a, b);
    // return Future.value('70');
  }
  Future<int?> init(int w, int h) {
    return SwRendPlatform.instance.init(w, h);
  }
  Future<void> draw(int texId, int x, int y, int w, int h, Uint8List pixels) async {
    return SwRendPlatform.instance.draw(texId, x, y, w, h, pixels);
  }
  Future<Uint8List?> getPixels(int texId) {
    return SwRendPlatform.instance.getPixels(texId);
  }
  Future<void> invalidate(int texId) {
    return SwRendPlatform.instance.invalidate(texId);
  }
  Future<Int32List?> getSize(int texId) {
    return SwRendPlatform.instance.getSize(texId);
  }
  Future<Int64List?> listTextures() {
    return SwRendPlatform.instance.listTextures();
  }
  Future<void> dispose(int texId) {
    return SwRendPlatform.instance.dispose(texId);
  }
}
