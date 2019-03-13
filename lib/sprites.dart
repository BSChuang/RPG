import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/animation.dart' as animation;
import 'package:flame/position.dart';
import 'dart:math';

class Sprites {
  static Widget makeSprite(String spritesheet, double size) {
    double width = spriteMap[spritesheet][0];
    double height = spriteMap[spritesheet][1];
    Random rand = new Random();
    double offset = 0.1 + rand.nextDouble() * 0.025;
    return Flame.util.animationAsWidget(
            Position(size, height / width * size),
            animation.Animation.sequenced(spritesheet + '.png', 4,
                textureWidth: width, textureHeight: height, stepTime: offset));
  }

  static Map<String, List<double>> spriteMap = {
    'big_demon': [42, 52],
    'skeleton_idle': [26, 26],
    'elf_idle': [26, 38]
  };
}
