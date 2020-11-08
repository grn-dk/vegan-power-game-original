import 'dart:ui';

import 'package:flame/sprite.dart';

import 'package:vegan_power/game_engine.dart';

class Cloud {
  final GameEngine game;
  final double cloudSpeed = 0.5;
  final double x_offset = 0;
  double y_offset;

  Rect cloudRect;
  double get cloudSize => 0.9 + game.rnd.nextDouble();

  Sprite cloudSprite;
  bool isOffScreen = false;

  Cloud(this.game, double x, double y) {
    y_offset = game.tileSize * cloudSpeed * (1 + game.rnd.nextDouble());
    cloudRect = Rect.fromLTWH(x, y, game.tileSize * cloudSize, game.tileSize * cloudSize);

    switch (game.rnd.nextInt(2)) {
      case 0:
        cloudSprite = Sprite('bg/cloud_01.png');
        break;
      case 1:
        cloudSprite = Sprite('bg/cloud_02.png');
        break;
    }

  }

  void render(Canvas c) {
    cloudSprite.renderRect(c, cloudRect.inflate(0.5));
  }

  void update(double t) {
    cloudRect = cloudRect.translate( x_offset, y_offset * t);

    if (cloudRect.top > game.screenSize.height) {
      isOffScreen = true;
    }
  }

}