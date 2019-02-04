/*import 'package:flutter/material.dart';
import 'package:spritewidget/spritewidget.dart';
import 'dart:ui' as ui show Image;

class MySprite extends StatefulWidget {
  @override
  MySpriteState createState() => new MySpriteState();
}
ImageMap _images;
class MySpriteState extends State<MySprite> {
  NodeWithSize rootNode;

  Future<Null> _loadAssets() async {
    await _images.load()
  }

  @override
  void initState() {
    super.initState();
    rootNode = new NodeWithSize(const Size(1024.0, 1024.0));
  }

  @override
  Widget build(BuildContext context) {
    ImageMap _images = new ImageMap(rootBundle)
    Sprite imp = new Sprite.fromImage(_images['sprites/imp_idle_anim_f0.png']);

    return new SpriteWidget(rootNode);
  }
}

class ImpSprite extends Node {
  List<Sprite> _sprites = <Sprite>[];

  ImpSprite({ui.Image image, bool dark, bool rotated, double loopTime}) {
    _sprites.add(_createSprite(image));
    addChild()
  }

  Sprite _createSprite(ui.Image image) {
    Sprite sprite = new Sprite.fromImage(image);

    return sprite;
  }
}
*/
