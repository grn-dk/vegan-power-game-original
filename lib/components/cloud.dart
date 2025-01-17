import 'dart:ui';

import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';

import 'package:vegan_power/game_engine.dart';

class Cloud {
  final GameEngine game;
  final double cloudSpeed = 0.5;
  final double xOffset = 0;
  double yOffset;

  Rect cloudRect;
  double get cloudSize => 0.9 + game.rnd.nextDouble();

  Sprite cloudSprite;
  bool isOffScreen = false;

  Cloud(this.game, double x, double y) {
    yOffset = game.tileSize * cloudSpeed * (1 + game.rnd.nextDouble());
    cloudRect = Rect.fromLTWH(x, y, game.tileSize * cloudSize, game.tileSize * cloudSize);

    switch (game.rnd.nextInt(2)) {
      case 0:
        cloudSprite = Sprite(Flame.images.fromCache('bg/cloud_01.png'));
        break;
      case 1:
        cloudSprite = Sprite(Flame.images.fromCache('bg/cloud_02.png'));
        break;
    }

  }

  void render(Canvas c) {
    cloudSprite.renderRect(c, cloudRect.inflate(0.5));
  }

  void update(double t) {
    cloudRect = cloudRect.translate( xOffset, yOffset * t);

    if (cloudRect.top > game.screenSize.height) {
      isOffScreen = true;
    }
  }

}