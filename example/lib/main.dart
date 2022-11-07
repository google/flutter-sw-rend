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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:sw_rend/software_texture.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int width = 300, height = 300;
  num scale = 1;
  DateTime start = DateTime.now();
  DateTime last = DateTime.now();
  int frames = 0;
  double fps = 1;
  SoftwareTexture? texture, texture2;
  late Uint8List gol;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    gol = Uint8List(width * height);
    Random r = Random();
    for (int i = 0; i < width * height; i++ ){
      gol[i] = r.nextBool() ? 255 : 0;
    }

    SoftwareTexture tex =
        SoftwareTexture(Size(width.toDouble(), height.toDouble()));
    await tex.generateTexture().then((void v) {
      if (kDebugMode) {
        print("TEXTURE = ${tex.textureId}");
      }
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

  Future<void> game() async {
    Uint8List newGol = Uint8List(width * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int index = y * width + x;
        int neighbors = 0;

        for (int dy = y-1; dy <= y+1; dy++) {
          for (int dx = x - 1; dx <= x + 1; dx++) {
            if (dy == y && dx == x) {
              continue;
            }
            if (gol[dx % width + (dy % height) * width] != 0) {
              neighbors += 1;
            }
          }
        }

        if (neighbors < 2) {
          newGol[index] = 0;
        }
        else if (neighbors > 3 && gol[index] != 0) {
          newGol[index] = 0;
        }
        else if (neighbors == 3) {
          newGol[index] = 255;
        }
        else {
          newGol[index] = gol[index];
        }
      }
    }
    gol.setAll(0, newGol);
  }

  Future<void> noisy() async {
    await game();
    Uint8List pixels = texture!.buffer;
    await texture!.readPixels();
    Random r = Random();
    for (int i = 0; i < width * height * 4; i += 4) {
      int index = i ~/ 4;
      int color = gol[index];
      pixels[i] = color;
      pixels[i + 1] = color;
      pixels[i + 2] = color;
      pixels[i + 3] = 255;
    }
    await texture!.draw();
    pixels = texture2!.buffer;
    for (int i = 0; i < width * height * 4; i += 4) {
      int x = (i ~/ 4) % width;
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
