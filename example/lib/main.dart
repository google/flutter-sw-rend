import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sw_rend/software_texture.dart';
import 'package:sw_rend/sw_rend.dart';

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
  final _testNativePlugin = SwRend();
  int width = 300, height = 300;
  num scale = 1;
  DateTime start = DateTime.now();
  DateTime last = DateTime.now();
  int frames = 0;
  double fps = 1;
  SoftwareTexture? texture, texture2;

  @override
  void initState() {
    super.initState();
    initPlatformState();
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
    SoftwareTexture tex =
        SoftwareTexture(Size(width.toDouble(), height.toDouble()));
    await tex.generateTexture().then((void v) {
      print("TEXTURE = ${tex.textureId}");
      texture = tex;
    });
    tex = SoftwareTexture(Size(width.toDouble(), height.toDouble()));
    await tex.generateTexture().then((void v) {
      texture2 = tex;
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
  }

  Future<void> tick() async {
    num targetFps = 200;
    Duration wait = Duration(microseconds: 1e6 ~/ targetFps);
    DateTime pre = DateTime.now();
    await noisy();
    DateTime now = DateTime.now();
    frames++;
    fps = 1e6 * frames / now.difference(start).inMicroseconds;
    if (frames >= 50) {
      setState(() {});
      frames = 0;
      start = now;
    }
    last = now;
    wait = wait - now.difference(pre);
    Timer(wait, tick);
  }

  Future<void> noisy() async {
    Uint8List pixels = texture!.buffer;
    await texture!.readPixels();
    Random r = Random();
    for (int i = 0; i < width * height * 4; i += 4) {
      int y = i ~/ width;
      int x = i % width;
      pixels[i] = r.nextInt(256) ~/ (1 + r.nextInt(4));
      pixels[i + 1] = x & 255;
      pixels[i + 2] = y & 255;
      pixels[i + 3] = 255;
    }
    await texture!.draw();
    pixels = texture2!.buffer;
    for (int i = 0; i < width * height * 4; i += 4) {
      int x = i % width;
      pixels[i] = r.nextInt(256) ~/ (2 + r.nextInt(4));
      pixels[i + 1] = r.nextInt(256) ~/ (2 + r.nextInt(4));
      pixels[i + 2] = x & 255;
      pixels[i + 3] = 255;
    }
    await texture2!.draw();
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
                  child: (texture == null)
                      ? null
                      : ConstrainedBox(
                      constraints: BoxConstraints(
                          minWidth: width.toDouble() * scale,
                          minHeight: height.toDouble() * scale),
                      child: Texture(
                        textureId: texture!.textureId,
                        filterQuality: FilterQuality.none,
                      ))),
              Container(
                  width: width.toDouble() * scale,
                  height: height.toDouble() * scale,
                  color: Colors.red,
                  child: (texture2 == null)
                      ? null
                      : ConstrainedBox(
                      constraints: BoxConstraints(
                          minWidth: width.toDouble() * scale,
                          minHeight: height.toDouble() * scale),
                      child: Texture(
                        textureId: texture2!.textureId,
                        filterQuality: FilterQuality.none,
                      ))),
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
