import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sw_rend/test_native.dart';
import 'package:sw_rend/test_native_platform_interface.dart';
import 'package:sw_rend/test_native_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockTestNativePlatform 
    with MockPlatformInterfaceMixin
    implements TestNativePlatform {

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
  final TestNativePlatform initialPlatform = TestNativePlatform.instance;

  test('$MethodChannelTestNative is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTestNative>());
  });

  test('getPlatformVersion', () async {
    TestNative testNativePlugin = TestNative();
    MockTestNativePlatform fakePlatform = MockTestNativePlatform();
    TestNativePlatform.instance = fakePlatform;
  
    expect(await testNativePlugin.getPlatformVersion(), '42');
  });
}
