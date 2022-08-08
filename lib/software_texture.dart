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

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:sw_rend/sw_rend.dart';

/// Represents a texture on the host device whose pixels can be
/// directly manipulated
class SoftwareTexture {
  static final SwRend _plugin = SwRend();
  static const int bytesPerPixel = 4;

  late final int textureId;
  late final int width, height;
  late final Uint8List buffer;

  /// [size] holds the width and height in pixels of this texture
  SoftwareTexture(Size size)
      : width = size.width.toInt(),
        height = size.height.toInt() {
    buffer = Uint8List(width * height * bytesPerPixel);
  }

  /// Instantiates the actual texture on the device and stores its texture ID
  Future<void> generateTexture() async {
    textureId = (await _plugin.init(width, height))!;
  }

  /// Push a region of the [buffer] to the underlying texture and optionally
  /// redraw it
  ///
  /// If [area] is specified, only the pixels that fall within it are pushed
  /// from [buffer] to the texture data, otherwise, the entire [buffer] is used.
  /// If [redraw] is [true] or unspecified, the texture will be refreshed with
  /// its new contents.
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

  /// Retrieves the actual pixel data in the texture and stores in [buffer]
  Future<void> readPixels() async {
    Uint8List? currentPixels = await _plugin.getPixels(textureId);
    buffer.setAll(0, currentPixels!);
  }

  /// Redraws the texture
  Future<void> redraw() async => _plugin.invalidate(textureId);

  /// Dispose of the underlying resources of this texture
  Future<void> dispose() async => _plugin.dispose(textureId);

  /// Copy a region of another [Uint8List] to this texture's [buffer]
  /// [srcRect] must contain the starting X and Y coordinates to copy from,
  /// and the width and height of the *entire* image held by [src].
  /// [dstRect] if provided, gives a region of this texture's [buffer] to which
  /// to copy the pixels.
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
