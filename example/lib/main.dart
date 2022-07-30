import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sw_rend/software_texture.dart';
import 'package:sw_rend/test_native.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String twoPlusThree = 'Waiting';
  final _testNativePlugin = TestNative();
  int width = 350, height = 200;
  num scale = 1;
  DateTime start = DateTime.now();
  DateTime last = DateTime.now();
  int frames = 0;
  double fps = 1;
  SoftwareTexture? texture;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void scheduleTick() {
    SchedulerBinding.instance.scheduleFrameCallback((timeStamp) {tick();});
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _testNativePlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    String sum = await _testNativePlugin.addNums(2, 3) ?? 'Failed to add';
    SoftwareTexture tex = SoftwareTexture(Size(width.toDouble(), height.toDouble()));
    await tex.generateTexture().then((void v) {
      print("TEXTURE = ${tex.textureId}");
      texture = tex;
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      twoPlusThree = sum;
    });

    tick();
    ///scheduleTick();
  }

  Future<void> tick() async {
    num targetFps = 1;
    Duration wait = Duration(microseconds: 1e6 ~/ targetFps);
    DateTime pre = DateTime.now();
    await noisy();
    DateTime now = DateTime.now();
    frames++;
    fps = 1e6 * frames / now.difference(start).inMicroseconds;
    if (frames >= 50) {
      setState((){});
      frames = 0;
      start = now;
    }
    Duration passed = now.difference(last);
    last = now;
    wait = wait - now.difference(pre);
    //print("$wait $passed");
    Timer(wait, tick);
    //scheduleTick();
  }

  Future<void> noisy() async {
    Uint8List pixels = texture!.buffer;//Uint8List(width * height * 4);
    Random r = Random();
    for (int i = 0; i < width * height * 4; i += 4) {
      pixels[i] = r.nextInt(256) ~/ (1 + r.nextInt(4));
      pixels[i + 1] = r.nextInt(256) ~/ (1 + r.nextInt(4));
      pixels[i + 2] = r.nextInt(256) ~/ (1 + r.nextInt(4));
      pixels[i + 3] = 255;
    }
    //await _testNativePlugin.draw(textureId, 0, 0, width, height, pixels);
    //await _testNativePlugin.invalidate(textureId);
    texture!.draw();
    //setState((){});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: Text('$fps'),
      ),
      body: Center(
        child: SizedBox(
          width: width.toDouble() * scale,
          child: ListView(
            children: [
              const Text('Text goes here'),
              Container(
                        width: width.toDouble() * scale,
                        height: height.toDouble() * scale,
                        color: Colors.green,
                        child: (texture == null) ? null : Texture(textureId: texture!.textureId, filterQuality: FilterQuality.none,)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Text('Button'),
        onPressed: () {
          noisy();
        },
      ),
    ));
  }
}
