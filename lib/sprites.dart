import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/animation.dart' as animation;
import 'package:flame/position.dart';
import 'package:flame/components/component.dart';
import 'package:flame/sprite.dart';
import 'dart:math';

class Sprites {
  static Widget makeSprite(String spritesheet, double size, {int h:16, int w:16}) {
    if (unitSprites.containsKey(spritesheet)) { // If is animated sprite
      double width = unitSprites[spritesheet][0];
      double height = unitSprites[spritesheet][1];
      int frames = unitSprites[spritesheet][2];
      Random rand = new Random();
      double offset = 0.1 + rand.nextDouble() * 0.025;

      return Flame.util.animationAsWidget(
          Position(size, height / width * size),
          animation.Animation.sequenced('units/' + spritesheet + '.png', frames,
              textureWidth: width, textureHeight: height, stepTime: offset));
    } else if (specialSprites.containsKey(spritesheet)) { // If not animated and passed sprites
      int width = h;
      int height = w;

      return Container(
          child: Image(
              image: AssetImage('assets/images/items/' + spritesheet + '.png'),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
              ),
          width: size * width,
          height: size * height);
    } else {
      int width = h;
      int height = w;

      if (specialSprites.containsKey(spritesheet)) {
        width = specialSprites[spritesheet][0];
        height = specialSprites[spritesheet][1];
      }

      return Container(
          child: Image(
              image: AssetImage('assets/images/items/' + spritesheet + '.png'),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
              ),
          width: size * width,
          height: size * height);
    }
  }

  static Map<String, List<dynamic>> unitSprites = {
    'big_demon': [42.0, 52.0, 4],
    'skeleton_idle': [26.0, 26.0, 4],
    'elf_idle': [26.0, 38.0, 4]
  };

  static Map<String, List<dynamic>> specialSprites = {
    'asdf': [16.0, 16.0],
  };
}
