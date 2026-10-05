import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const CityRushApp());
}

class CityRushApp extends StatelessWidget {
  const CityRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'City Rush',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const CityRushGame(),
    );
  }
}

enum ObjectType { coin, obstacle, train }

class RoadObject {
  RoadObject({
    required this.lane,
    required this.depth,
    required this.type,
  });

  int lane;
  double depth;
  final ObjectType type;
  bool collected = false;
}

class CityRushGame extends StatefulWidget {
  const CityRushGame({super.key});

  @override
  State<CityRushGame> createState() => _CityRushGameState();
}

class _CityRushGameState extends State<CityRushGame> {
  final math.Random random = math.Random();
  final List<RoadObject> objects = [];

  Timer? timer;
  int lane = 1;
  int score = 0;
  int coins = 0;
  int lives = 3;
  int jumpTicks = 0;
  double speed = 0.55;
  bool started = false;
  bool gameOver = false;
  DateTime lastSpawn = DateTime.now();
  Offset? dragStart;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startGame() {
    timer?.cancel();
    setState(() {
      objects.clear();
      lane = 1;
      score = 0;
      coins = 0;
      lives = 3;
      jumpTicks = 0;
      speed = 0.55;
      started = true;
      gameOver = false;
      lastSpawn = DateTime.now();
    });

    timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted || !started || gameOver) return;
      tick();
    });
  }

  void tick() {
    final now = DateTime.now();
    final elapsed = now.difference(lastSpawn).inMilliseconds;

    if (elapsed > (850 - speed * 180).clamp(350, 850)) {
      spawnObject();
      lastSpawn = now;
    }

    setState(() {
      for (final object in objects) {
        object.depth += speed * 0.035;
      }

      if (jumpTicks > 0) {
        jumpTicks--;
      }

      score += 1;
      speed = math.min(1.45, speed + 0.00018);
      checkCollisions();
      objects.removeWhere((o) => o.depth > 1.12 || o.collected);
    });
  }

  void spawnObject() {
    final laneIndex = random.nextInt(3);
    final roll = random.nextDouble();

    ObjectType type;
    if (roll < 0.28) {
      type = ObjectType.coin;
    } else if (roll < 0.76) {
      type = ObjectType.obstacle;
    } else {
      type = ObjectType.train;
    }

    setState(() {
      objects.add(RoadObject(
        lane: laneIndex,
        depth: 0.0,
        type: type,
      ));

      if (type == ObjectType.coin && random.nextBool()) {
        final secondLane = (laneIndex + 1 + random.nextInt(2)) % 3;
        objects.add(RoadObject(
          lane: secondLane,
          depth: -0.10,
          type: ObjectType.coin,
        ));
      }
    });
  }

  void checkCollisions() {
    for (final object in objects) {
      if (object.collected) continue;

      final close = object.depth > 0.78 && object.depth < 1.02;
      if (!close || object.lane != lane) continue;

      if (object.type == ObjectType.coin) {
        object.collected = true;
        coins++;
        score += 10;
      } else if (jumpTicks > 0) {
        if (object.type == ObjectType.train) {
          score += 25;
        }
        object.collected = true;
      } else {
        object.collected = true;
        lives--;
        score = math.max(0, score - (object.type == ObjectType.train ? 30 : 20));

        if (lives <= 0) {
          endGame();
          return;
        }
      }
    }
  }

  void endGame() {
    gameOver = true;
    timer?.cancel();

    Future.microtask(() {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Game Over'),
          content: Text(
            'Score: $score\nCoins: $coins',
            style: const TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                startGame();
              },
              child: const Text('PLAY AGAIN'),
            ),
          ],
        ),
      );
    });
  }

  void moveLeft() {
    if (!started || gameOver) return;
    setState(() {
      lane = math.max(0, lane - 1);
    });
  }

  void moveRight() {
    if (!started || gameOver) return;
    setState(() {
      lane = math.min(2, lane + 1);
    });
  }

  void jump() {
    if (!started || gameOver || jumpTicks > 0) return;
    setState(() {
      jumpTicks = 18;
    });
  }

  void handleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -250) {
      moveRight();
    } else if (velocity > 250) {
      moveLeft();
    } else {
      jump();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: handleSwipe,
          onVerticalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -200) jump();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: CityPainter(
                  playerLane: lane,
                  objects: objects,
                  jumpTicks: jumpTicks,
                  started: started,
                ),
              ),
              if (!started)
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: Colors.black.withValues(alpha: 0.72),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'CITY RUSH',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'RUN • JUMP • COLLECT • RIDE',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          onPressed: startGame,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('START GAME'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (started)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _hud(Icons.star, '$score'),
                      _hud(Icons.monetization_on, '$coins'),
                      _hud(Icons.favorite, '$lives'),
                    ],
                  ),
                ),
              if (started)
                Positioned(
                  bottom: 18,
                  left: 18,
                  right: 18,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _controlButton(Icons.arrow_back, moveLeft),
                      _controlButton(Icons.keyboard_arrow_up, jump),
                      _controlButton(Icons.arrow_forward, moveRight),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hud(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(40),
        child: SizedBox(
          width: 62,
          height: 62,
          child: Icon(icon, size: 32),
        ),
      ),
    );
  }
}

class CityPainter extends CustomPainter {
  CityPainter({
    required this.playerLane,
    required this.objects,
    required this.jumpTicks,
    required this.started,
  });

  final int playerLane;
  final List<RoadObject> objects;
  final int jumpTicks;
  final bool started;

  @override
  void paint(Canvas canvas, Size size) {
    final skyPaint = Paint()..color = const Color(0xFF78C8F0);
    canvas.drawRect(Offset.zero & size, skyPaint);

    final cityPaint = Paint()..color = const Color(0xFF5A6672);
    for (int i = 0; i < 11; i++) {
      final x = i * size.width / 10;
      final h = 55.0 + ((i * 37) % 90);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * 0.28 - h, size.width / 13, h),
        cityPaint,
      );
    }

    final roadTop = size.height * 0.30;
    final road = Path()
      ..moveTo(size.width * 0.36, roadTop)
      ..lineTo(size.width * 0.64, roadTop)
      ..lineTo(size.width * 0.98, size.height)
      ..lineTo(size.width * 0.02, size.height)
      ..close();

    canvas.drawPath(
      road,
      Paint()..color = const Color(0xFF30343B),
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 3;

    for (int i = 1; i < 3; i++) {
      final topX = size.width * (0.36 + i * 0.093);
      final bottomX = size.width * (0.02 + i * 0.32);
      canvas.drawLine(
        Offset(topX, roadTop),
        Offset(bottomX, size.height),
        linePaint,
      );
    }

    for (final object in objects) {
      final x = laneX(size, object.lane, object.depth);
      final y = roadY(size, object.depth);

      if (object.type == ObjectType.coin) {
        drawCoin(canvas, Offset(x, y), object.depth);
      } else if (object.type == ObjectType.obstacle) {
        drawObstacle(canvas, Offset(x, y), object.depth);
      } else {
        drawTrain(canvas, Offset(x, y), object.depth);
      }
    }

    if (started) {
      final playerX = laneX(size, playerLane, 1.0);
      final jumpAmount = jumpTicks > 0
          ? math.sin((jumpTicks / 18) * math.pi) * size.height * 0.13
          : 0.0;

      drawPlayer(
        canvas,
        Offset(playerX, size.height * 0.82 - jumpAmount),
      );
    }
  }

  double laneX(Size size, int lane, double depth) {
    final t = depth.clamp(0.0, 1.0);
    final topLeft = size.width * 0.36;
    final topRight = size.width * 0.64;
    final bottomLeft = size.width * 0.02;
    final bottomRight = size.width * 0.98;
    final left = topLeft + (bottomLeft - topLeft) * t;
    final right = topRight + (bottomRight - topRight) * t;
    return left + (right - left) * ((lane + 0.5) / 3);
  }

  double roadY(Size size, double depth) {
    final t = depth.clamp(0.0, 1.0);
    return size.height * (0.30 + 0.65 * t);
  }

  void drawCoin(Canvas canvas, Offset center, double depth) {
    final radius = 7 + depth.clamp(0, 1) * 13;
    final paint = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(center, radius, paint);

    final inner = Paint()..color = const Color(0xFFFFB300);
    canvas.drawCircle(center, radius * 0.62, inner);
  }

  void drawObstacle(Canvas canvas, Offset center, double depth) {
    final w = 24 + depth * 50;
    final h = 28 + depth * 45;
    final paint = Paint()..color = const Color(0xFFE85D5D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: w, height: h),
        const Radius.circular(7),
      ),
      paint,
    );
  }

  void drawTrain(Canvas canvas, Offset center, double depth) {
    final w = 38 + depth * 85;
    final h = 28 + depth * 60;
    final paint = Paint()..color = const Color(0xFF7E57C2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: w, height: h),
        const Radius.circular(8),
      ),
      paint,
    );

    final windowPaint = Paint()..color = const Color(0xFFB3E5FC);
    final windowW = w * 0.22;
    for (int i = -1; i <= 1; i++) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(center.dx + i * windowW * 1.25, center.dy - h * 0.1),
          width: windowW,
          height: h * 0.35,
        ),
        windowPaint,
      );
    }
  }

  void drawPlayer(Canvas canvas, Offset center) {
    final bodyPaint = Paint()..color = const Color(0xFF00C853);
    final headPaint = Paint()..color = const Color(0xFFFFCC80);

    canvas.drawCircle(Offset(center.dx, center.dy - 34), 13, headPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy - 4),
          width: 25,
          height: 48,
        ),
        const Radius.circular(10),
      ),
      bodyPaint,
    );

    final legPaint = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - 7, center.dy + 18),
      Offset(center.dx - 13, center.dy + 40),
      legPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 7, center.dy + 18),
      Offset(center.dx + 13, center.dy + 40),
      legPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CityPainter oldDelegate) => true;
}
