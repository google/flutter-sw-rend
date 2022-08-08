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
