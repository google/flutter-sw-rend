import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:sw_rend/test_native.dart';

class SoftwareTexture {
  static final TestNative _plugin = TestNative();
  static const int bytesPerPixel = 4;

  late final int textureId;
  late final int width, height;
  late final Uint8List buffer;

  SoftwareTexture(Size size)
      : width = size.width.toInt(),
        height = size.height.toInt() {
    buffer = Uint8List(width * height * bytesPerPixel);
  }

  Future<void> generateTexture() async {
    textureId = (await _plugin.init(width, height))!;
  }

  Future<dynamic> draw({Rect? area, bool redraw = true}) async {
    int x = area?.left.toInt() ?? 0;
    int y = area?.top.toInt() ?? 0;
    int w = area?.width.toInt() ?? width;
    int h = area?.height.toInt() ?? height;
    Future<void> draw = _plugin.draw(textureId, x, y, w, h, buffer);
    if (redraw) {
      Future<void> invalidate = _plugin.invalidate(textureId);
      return Future.wait([draw, invalidate]);
    }
    return draw;
  }

  Future<void> readPixels() async {
    Uint8List? currentPixels = await _plugin.getPixels(textureId);
    buffer.setAll(0, currentPixels!);
  }

  Future<void> redraw() async => _plugin.invalidate(textureId);

  Future<void> dispose() async => _plugin.dispose(textureId);

  void blit(Uint8List src, Rect srcRect, Rect? dstRect) {
    int srcX = srcRect.left.toInt();
    int srcY = srcRect.top.toInt();
    int srcW = srcRect.width.toInt();
    int srcH = srcRect.height.toInt();
    int dstX = dstRect?.left.toInt() ?? 0;
    int dstY = dstRect?.top.toInt() ?? 0;
    int dstW = dstRect?.width.toInt() ?? width;
    int dstH = dstRect?.height.toInt() ?? height;
    int rowSize = min(min(dstW, srcW - srcX), width - dstX);
    int numRows = min(min(dstH, srcH - srcY), height - dstY);
    for (int dy = 0; dy < numRows; dy++) {

      for (int dx = 0; dx < rowSize; dx++) {
        for (int k = 0; k < 4; k++) {
          buffer[4 * ((dstY + dy) * width + dstX + dx) + k] =
              src[4 * ((srcY + dy) * srcW + srcX + srcH) + k];
        }
      }
    }
  }
}
