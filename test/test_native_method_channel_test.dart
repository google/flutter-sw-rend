import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sw_rend/sw_rend_method_channel.dart';

void main() {
  MethodChannelTestNative platform = MethodChannelTestNative();
  const MethodChannel channel = MethodChannel('com.funguscow/sw_rend');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
