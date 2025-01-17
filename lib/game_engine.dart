import 'dart:ui';
import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';

import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/gestures.dart';

import 'package:vegan_power/view.dart';

import 'package:vegan_power/components/animal.dart';
import 'package:vegan_power/components/background.dart';
import 'package:vegan_power/components/cloud.dart';
import 'package:vegan_power/components/credits_button.dart';
import 'package:vegan_power/components/display_credits.dart';
import 'package:vegan_power/components/display_help.dart';
import 'package:vegan_power/components/display_high_score.dart';
import 'package:vegan_power/components/display_life.dart';
import 'package:vegan_power/components/display_score.dart';
import 'package:vegan_power/components/fruit.dart';
import 'package:vegan_power/components/help_button.dart';
import 'package:vegan_power/components/music_button.dart';
import 'package:vegan_power/components/player.dart';
import 'package:vegan_power/components/sound_button.dart';
import 'package:vegan_power/components/start_button.dart';

import 'package:vegan_power/controllers/sounds.dart';
import 'package:vegan_power/controllers/spawn_animals.dart';
import 'package:vegan_power/controllers/spawn_clouds.dart';
import 'package:vegan_power/controllers/spawn_fruits.dart';


import 'package:vegan_power/views/home_view.dart';
import 'package:vegan_power/views/lost_view.dart';

//TODO
/*
V 1.02
Publish on Apple store

V1.1
Add google login
Add global database score
 */

class nisse extends FlameGame with HasCollisionDetection {

}

class GameEngine extends FlameGame with TapDetector, PanDetector {
  final maxLife = 7;
  final startSpeedAnimal = 2.0;
  final startSpeedFruit = 2.0;
  final SharedPreferences storage;

  Size screenSize;
  double tileSize;

  Background background;
  int score;
  int life;
  double fruitSpeed;
  double animalSpeed;

  List<Cloud> clouds;
  List<Fruit> fruits;
  List<Animal> animals;

  Random rnd;
  double gameTime;

  Sounds sounds;
  SpawnClouds cloudSpawner;
  SpawnFruits fruitSpawner;
  SpawnAnimals animalSpawner;

  Player player;

  DisplayScore displayScore;
  DisplayCredits displayCredits;
  DisplayHelp displayHelp;
  DisplayLife displayLife;
  DisplayHighScore displayHighScore;

  View activeView = View.home;

  HomeView homeView;
  LostView lostView;
  /*HelpView helpView;
  CreditsView creditsView;*/

  StartButton startButton;
  HelpButton helpButton;
  CreditsButton creditsButton;
  MusicButton musicButton;
  SoundButton soundButton;

  GameEngine(this.storage) {
    initialize();
  }

  void initialize() async {
    //resize(await Flame.util.initialDimensions());
    homeView = HomeView(this);
    lostView = LostView(this);
    /*helpView = HelpView(this);
    creditsView = CreditsView(this);*/

    startButton = StartButton(this);
    helpButton = HelpButton(this);
    creditsButton = CreditsButton(this);
    musicButton = MusicButton(this);
    soundButton = SoundButton(this);

    //gameTime = 0;
    clouds = List<Cloud>();
    fruits = List<Fruit>();
    animals = List<Animal>();

    rnd = Random();

    score = 0;
    life = maxLife;

    fruitSpeed = startSpeedFruit;
    animalSpeed = startSpeedAnimal;

    sounds = Sounds();
    cloudSpawner = SpawnClouds(this);
    fruitSpawner = SpawnFruits(this);
    animalSpawner = SpawnAnimals(this);
    background = Background(this);
    displayScore = DisplayScore(this);
    displayCredits = DisplayCredits(this);
    displayHelp = DisplayHelp(this);
    displayHighScore = DisplayHighScore(this);
    displayLife = DisplayLife(this);
    //Spawn player in the middle of the screen
    player = Player(this, screenSize.width/2 - tileSize, screenSize.height/2);
    FlameAudio.bgm.play('music/bensound-jazzyfrenchy.mp3', volume: .3);
  }

  void render(Canvas canvas) {
    //Always visible section
    background.render(canvas);
    clouds.forEach((Cloud cloud) => cloud.render(canvas));
    //Always visible section end

    if (activeView == View.home) homeView.render(canvas);

    if (activeView == View.home || activeView == View.lost) {
      startButton.render(canvas);
      helpButton.render(canvas);
      creditsButton.render(canvas);
      musicButton.render(canvas);
      soundButton.render(canvas);
    }

    if (activeView == View.lost) {
      lostView.render(canvas);
    }

    if (activeView == View.help) displayHelp.render(canvas);
    //Only display credits when credits view is active
    if (activeView == View.credits) displayCredits.render(canvas);

    if(activeView == View.playing) {
      player.render(canvas);
      fruits.forEach((Fruit fruit) => fruit.render(canvas));
      animals.forEach((Animal animal) => animal.render(canvas));
      displayLife.render(canvas);
    }
    if(activeView == View.playing || activeView == View.lost) {
      displayScore.render(canvas);
    }
    displayHighScore.render(canvas);
  }

  void update(double t) {
    //Clouds
    cloudSpawner.update(t);
    clouds.forEach((Cloud cloud) => cloud.update(t));
    clouds.removeWhere((Cloud cloud) => cloud.isOffScreen);

    if(activeView == View.playing) {
      //Fruits
      fruitSpawner.update(t);
      fruits.forEach((Fruit fruit) => fruit.update(t));
      fruits.removeWhere((Fruit fruit) => fruit.eaten);
      fruits.removeWhere((Fruit fruit) => fruit.isOffScreen);

      //Animals
      animalSpawner.update(t);
      animals.forEach((Animal animal) => animal.update(t));
      animals.removeWhere((Animal animal) => animal.eaten);
      animals.removeWhere((Animal animal) => animal.isOffScreen);

      //Player
      player.speed = player.startSpeedPlayer + (score * 2);
      player.update(t);

      //Fruit collision detection.
      fruits.forEach((Fruit fruit) {
        if (player.playerRect.contains(fruit.fruitRect.center)) {
          if(soundButton.isEnabled) {
            FlameAudio.play(sounds.fruitEatenSounds[rnd.nextInt(sounds.countFruitEatenSounds)]);
          }
          fruit.fruitEaten();
          score += 1;

          fruitSpeed += 0.02;
          if (score > (storage.getInt('highScore') ?? 0)) {
            storage.setInt('highScore', score);
            displayHighScore.updateHighScore();
          }
        }
      });

      //Animal collision detection.
      animals.forEach((Animal animal) {
        if (player.playerRect.contains(animal.animalRect.center)) {
          if(soundButton.isEnabled) {
            FlameAudio.play(sounds.animalsEatenSounds[rnd.nextInt(sounds.countAnimalsEatenSounds)]);
          }

          animal.animalEaten();
          life -= 1;
          //animalSpeed -= 0.05;
        }
      });

      displayScore.update(t);
      displayLife.update(t);
    }

    if (activeView == View.playing && life <= 0) {
      activeView = View.lost;
    }

    /*DEBUGGING
    gameTime += t;
    if(gameTime > 1) {
      //print ("clouds length: ${clouds.length} and t: $t ");
      gameTime = 0;
    }*/
  }

  /*void resize(Size size) {
    screenSize = size;
    tileSize = screenSize.width / 9;
    super.resize(size);
  }*/
/*
  @override
  void onPanUpdate(DragUpdateDetails d) {
    if(activeView == View.playing) {
      player.targetLocation = Offset(d.globalPosition.dx, d.globalPosition.dy);
      //print("Player tap down on ${d.globalPosition.dx} - ${d.globalPosition.dy} and delta = ${d.delta}");
    }
  }
*/

  /*
  @override
  void onTapDown(TapDownDetails d) {
    bool isHandled = false;

    //Dialog boxes
    if (!isHandled) {
      if (activeView == View.help || activeView == View.credits) {
        activeView = View.home;
        isHandled = true;
      }
    }

    //Startbutton
    if (!isHandled && startButton.rect.contains(d.globalPosition)) {
      if (activeView == View.home || activeView == View.lost) {
        startButton.onTapDown();
        isHandled = true;
      }
    }
    //Helpbutton
    if (!isHandled && helpButton.rect.contains(d.globalPosition)) {
      if (activeView == View.home || activeView == View.lost) {
        helpButton.onTapDown();
        isHandled = true;
      }
    }

    //Creditsbutton
    if (!isHandled && creditsButton.rect.contains(d.globalPosition)) {
      if (activeView == View.home || activeView == View.lost) {
        creditsButton.onTapDown();
        isHandled = true;
      }
    }

    //Player

    if(!isHandled) {
      if(activeView == View.playing) {
        player.targetLocation = Offset(d.globalPosition.dx, d.globalPosition.dy);
        isHandled = true;
      }
    }

    //Musicbutton
    if (!isHandled && musicButton.rect.contains(d.globalPosition)) {
      if (activeView == View.home || activeView == View.lost) {
        musicButton.onTapDown();
        isHandled = true;
      }
    }

    //Soundbutton
    if (!isHandled && soundButton.rect.contains(d.globalPosition)) {
      if (activeView == View.home || activeView == View.lost) {
        soundButton.onTapDown();
        isHandled = true;
      }
    }

    //print("Player tap down on ${d.globalPosition.dx} - ${d.globalPosition.dy}");
  }
  */
  /*
  @override
  void onTapUp(TapUpDetails d) {
    //bool isHandled = false;
  }
*/

  void spawnCloud() {
    //Spawn cloud at a random place horizontally within the screen.
    double x = rnd.nextDouble() * (screenSize.width - (tileSize * 2.025));
    //All clouds start at the top of the screen
    double y = -tileSize-tileSize;
    clouds.add(Cloud(this, x, y));
  }

  void spawnFruit() {
    //Spawn cloud at a random place horizontally within the screen.
    double x = rnd.nextDouble() * (screenSize.width - (tileSize * 2.025));
    //All clouds start at the top of the screen
    double y = -tileSize-tileSize;
    fruits.add(Fruit(this, x, y));
  }
  void spawnAnimal() {
    //Spawn cloud at a random place horizontally within the screen.
    double x = rnd.nextDouble() * (screenSize.width - (tileSize * 2.025));
    //All clouds start at the top of the screen
    double y = -tileSize-tileSize;
    animals.add(Animal(this, x, y));
  }

  void killAll() {
    animals.forEach((Animal animal) => animal.eaten = true);
    fruits.forEach((Fruit fruit) => fruit.eaten = true);
  }
}