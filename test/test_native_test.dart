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

import 'package:flutter_test/flutter_test.dart';
import 'package:sw_rend/sw_rend.dart';
import 'package:sw_rend/sw_rend_method_channel.dart';
import 'package:sw_rend/sw_rend_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockTestNativePlatform 
    with MockPlatformInterfaceMixin
    implements SwRendPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> addNums(int a, int b) => Future.value('${a + b}');

  @override
  Future<int?> init(int w, int h) => Future.value(-1);

  @override
  Future<void> draw(int texId, int x, int y, int w, int h, Uint8List pixels) => Future.value(null);

  @override
  Future<Uint8List?> getPixels(int texId) => Future.value(Uint8List(0));

  @override
  Future<void> invalidate(int texId) => Future.value(null);

  @override
  Future<void> dispose(int texId) => Future.value(null);

  @override
  Future<Int32List?> getSize(int texId) => Future.value(Int32List(0));

  @override
  Future<Int64List?> listTextures() => Future.value(null);

}

void main() {
  final SwRendPlatform initialPlatform = SwRendPlatform.instance;

  test('$MethodChannelTestNative is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTestNative>());
  });

  test('getPlatformVersion', () async {
    SwRend testNativePlugin = SwRend();
    MockTestNativePlatform fakePlatform = MockTestNativePlatform();
    SwRendPlatform.instance = fakePlatform;
  
    expect(await testNativePlugin.getPlatformVersion(), '42');
  });
}
