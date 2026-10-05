
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const JungleRushApp());

class JungleRushApp extends StatelessWidget {
  const JungleRushApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Jungle Rush',
        theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        home: const JungleHome(),
      );
}

enum TrapType { spike, log, rock, gap, branch }
enum GameMode { running, parachuting }

class JungleObject {
  JungleObject({required this.lane, required this.depth, required this.type});
  int lane;
  double depth;
  final TrapType type;
  bool hit = false;
}

class CoinObject {
  CoinObject({required this.lane, required this.depth});
  int lane;
  double depth;
  bool taken = false;
}

class JungleHome extends StatefulWidget {
  const JungleHome({super.key});
  @override
  State<JungleHome> createState() => _JungleHomeState();
}

class _JungleHomeState extends State<JungleHome> {
  int coins = 0;
  int diamonds = 0;
  int selectedSkin = 0;
  final Set<int> ownedSkins = {0};

  final skins = <Map<String, dynamic>>[
    {'name': 'Explorer', 'price': 0, 'body': const Color(0xFF16C784)},
    {'name': 'Sky Blue', 'price': 120, 'body': const Color(0xFF42A5F5)},
    {'name': 'Sunset', 'price': 250, 'body': const Color(0xFFFF7043)},
    {'name': 'Golden', 'price': 500, 'body': const Color(0xFFFFC107)},
  ];

  void openGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JungleGame(
          skinColor: skins[selectedSkin]['body'] as Color,
          startingCoins: coins,
          startingDiamonds: diamonds,
          onFinished: (c, d) => setState(() {
            coins = c;
            diamonds = d;
          }),
        ),
      ),
    );
  }

  void openShop() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF102A24),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, sheetSetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('RUNNER SHOP',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('🪙 ' + coins.toString() + '   💎 ' + diamonds.toString()),
                const SizedBox(height: 14),
                ...List.generate(skins.length, (index) {
                  final skin = skins[index];
                  final owned = ownedSkins.contains(index);
                  final price = skin['price'] as int;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: skin['body'] as Color,
                        child: const Icon(Icons.person),
                      ),
                      title: Text(skin['name'] as String),
                      subtitle: Text(owned ? 'Owned' : price.toString() + ' coins'),
                      trailing: FilledButton(
                        onPressed: owned
                            ? () {
                                setState(() => selectedSkin = index);
                                sheetSetState(() {});
                              }
                            : coins >= price
                                ? () {
                                    setState(() {
                                      coins -= price;
                                      ownedSkins.add(index);
                                      selectedSkin = index;
                                    });
                                    sheetSetState(() {});
                                  }
                                : null,
                        child: Text(selectedSkin == index
                            ? 'SELECTED'
                            : owned
                                ? 'USE'
                                : 'BUY'),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget badge(String icon, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(icon + ' ' + value,
            style: const TextStyle(fontWeight: FontWeight.w900)),
      );

  @override
  Widget build(BuildContext context) {
    final skinColor = skins[selectedSkin]['body'] as Color;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: HomePainter(skinColor: skinColor)),
            Positioned(
              top: 18,
              left: 18,
              right: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [badge('🪙', coins.toString()), badge('💎', diamonds.toString())],
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const SizedBox(height: 35),
                    const Text('JUNGLE',
                        style: TextStyle(
                            fontSize: 50,
                            height: .9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 5)),
                    const Text('RUSH',
                        style: TextStyle(
                            fontSize: 58,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 7,
                            color: Color(0xFFFFD54F))),
                    const SizedBox(height: 8),
                    const Text('RUN • DODGE • GLIDE • SURVIVE',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: openGame,
                      icon: const Icon(Icons.play_arrow_rounded, size: 30),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                        child: Text('START RUN',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: openShop,
                      icon: const Icon(Icons.shopping_bag_rounded),
                      label: const Text('CHARACTER SHOP'),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Run through the jungle, dodge traps, collect coins, '
                      'then glide in a parachute. Every safe landing gives 1 diamond.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JungleGame extends StatefulWidget {
  const JungleGame({
    super.key,
    required this.skinColor,
    required this.startingCoins,
    required this.startingDiamonds,
    required this.onFinished,
  });

  final Color skinColor;
  final int startingCoins;
  final int startingDiamonds;
  final void Function(int coins, int diamonds) onFinished;

  @override
  State<JungleGame> createState() => _JungleGameState();
}

class _JungleGameState extends State<JungleGame> {
  final random = math.Random();
  final traps = <JungleObject>[];
  final coinsList = <CoinObject>[];
  Timer? timer;

  GameMode mode = GameMode.running;
  int lane = 1;
  int lives = 3;
  int score = 0;
  late int coins;
  late int diamonds;
  double distance = 0;
  double speed = .42;
  double jump = 0;
  double slide = 0;
  double parachuteTime = 0;
  double nextParachute = 550;
  double spawnClock = 0;
  bool paused = false;
  bool dead = false;

  @override
  void initState() {
    super.initState();
    coins = widget.startingCoins;
    diamonds = widget.startingDiamonds;
    timer = Timer.periodic(const Duration(milliseconds: 40), (_) => tick());
  }

  @override
  void dispose() {
    timer?.cancel();
    widget.onFinished(coins, diamonds);
    super.dispose();
  }

  void tick() {
    if (!mounted || paused || dead) return;
    setState(() {
      if (mode == GameMode.running) {
        distance += speed * 1.55;
        score += 1;
        speed = math.min(1.05, speed + .00016);
        spawnClock += .04;

        if (spawnClock > (0.82 - speed * .18).clamp(.38, .82)) {
          spawnThings();
          spawnClock = 0;
        }

        for (final trap in traps) {
          trap.depth += speed * .032;
        }
        for (final coin in coinsList) {
          coin.depth += speed * .032;
        }

        if (jump > 0) jump = math.max(0, jump - .055);
        if (slide > 0) slide = math.max(0, slide - .055);
        checkRunningCollisions();

        traps.removeWhere((x) => x.depth > 1.08 || x.hit);
        coinsList.removeWhere((x) => x.depth > 1.08 || x.taken);

        if (distance >= nextParachute) startParachute();
      } else {
        parachuteTime -= .04;
        score += 2;
        distance += .55;
        for (final coin in coinsList) {
          coin.depth += .010;
        }
        coinsList.removeWhere((x) => x.depth > 1.08 || x.taken);

        if (random.nextDouble() < .08) {
          coinsList.add(CoinObject(lane: random.nextInt(3), depth: 0));
        }
        if (parachuteTime <= 0) landParachute();
      }
    });
  }

  void spawnThings() {
    final laneIndex = random.nextInt(3);
    final roll = random.nextDouble();
    TrapType type;
    if (roll < .22) {
      type = TrapType.spike;
    } else if (roll < .44) {
      type = TrapType.log;
    } else if (roll < .66) {
      type = TrapType.rock;
    } else if (roll < .82) {
      type = TrapType.gap;
    } else {
      type = TrapType.branch;
    }

    traps.add(JungleObject(lane: laneIndex, depth: 0, type: type));

    final coinCount = random.nextInt(3) + 2;
    for (int i = 0; i < coinCount; i++) {
      coinsList.add(CoinObject(lane: (laneIndex + i) % 3, depth: -.13 * i));
    }

    if (random.nextDouble() < .24) {
      final other = (laneIndex + 1 + random.nextInt(2)) % 3;
      traps.add(JungleObject(lane: other, depth: -.18, type: TrapType.rock));
    }
  }

  void checkRunningCollisions() {
    for (final coin in coinsList) {
      if (!coin.taken &&
          coin.depth > .78 &&
          coin.depth < 1.02 &&
          coin.lane == lane) {
        coin.taken = true;
        coins += 1;
        score += 20;
      }
    }

    for (final trap in traps) {
      if (trap.hit ||
          trap.depth < .80 ||
          trap.depth > 1.02 ||
          trap.lane != lane) {
        continue;
      }

      final safeJump = jump > .28 &&
          (trap.type == TrapType.spike ||
              trap.type == TrapType.log ||
              trap.type == TrapType.rock);
      final safeSlide = slide > .28 && trap.type == TrapType.branch;

      if (safeJump || safeSlide) {
        trap.hit = true;
        score += 35;
      } else {
        trap.hit = true;
        lives -= 1;
        score = math.max(0, score - 50);
        if (lives <= 0) {
          die();
          return;
        }
      }
    }
  }

  void startParachute() {
    mode = GameMode.parachuting;
    parachuteTime = 15;
    traps.clear();
    coinsList.clear();
  }

  void landParachute() {
    mode = GameMode.running;
    diamonds += 1;
    score += 250;
    nextParachute = distance + 850;
    showMessage('💎 Safe landing! +1 Diamond');
  }

  void die() {
    dead = true;
    timer?.cancel();
    Future.microtask(() {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF102A24),
          title: const Text('RUN OVER'),
          content: Text(
            'Score: ' + score.toString() +
                '\nCoins: ' + coins.toString() +
                '\nDiamonds: ' + diamonds.toString(),
            style: const TextStyle(fontSize: 18),
          ),
          actions: [
            if (diamonds > 0)
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  revive();
                },
                icon: const Icon(Icons.favorite),
                label: const Text('REVIVE • 1 💎'),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('HOME'),
            ),
          ],
        ),
      );
    });
  }

  void revive() {
    setState(() {
      diamonds -= 1;
      lives = 2;
      dead = false;
      traps.clear();
      coinsList.clear();
      jump = 0;
      slide = 0;
    });
    timer = Timer.periodic(const Duration(milliseconds: 40), (_) => tick());
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void moveLeft() {
    if (mode != GameMode.running || dead) return;
    setState(() => lane = math.max(0, lane - 1));
  }

  void moveRight() {
    if (mode != GameMode.running || dead) return;
    setState(() => lane = math.min(2, lane + 1));
  }

  void jumpUp() {
    if (mode != GameMode.running || dead || jump > 0) return;
    setState(() => jump = 1);
  }

  void slideDown() {
    if (mode != GameMode.running || dead || slide > 0) return;
    setState(() => slide = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v < -180) moveRight();
            if (v > 180) moveLeft();
          },
          onVerticalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v < -180) jumpUp();
            if (v > 180) slideDown();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: JunglePainter(
                  playerLane: lane,
                  traps: traps,
                  coins: coinsList,
                  jump: jump,
                  slide: slide,
                  mode: mode,
                  skinColor: widget.skinColor,
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    hud('🏆', score.toString()),
                    const SizedBox(width: 6),
                    hud('🪙', coins.toString()),
                    const SizedBox(width: 6),
                    hud('💎', diamonds.toString()),
                    const Spacer(),
                    hud('❤️', lives.toString()),
                  ],
                ),
              ),
              if (mode == GameMode.parachuting)
                Positioned(
                  top: 68,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🪂 PARACHUTE  ' + parachuteTime.ceil().toString() + 's',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              if (mode == GameMode.running)
                Positioned(
                  bottom: 15,
                  left: 14,
                  right: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      control(Icons.arrow_back_rounded, moveLeft),
                      control(Icons.keyboard_arrow_up_rounded, jumpUp),
                      control(Icons.keyboard_arrow_down_rounded, slideDown),
                      control(Icons.arrow_forward_rounded, moveRight),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget hud(String icon, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .52),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(icon + ' ' + value,
            style: const TextStyle(fontWeight: FontWeight.w900)),
      );

  Widget control(IconData icon, VoidCallback action) => Material(
        color: Colors.black.withValues(alpha: .58),
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          onTap: action,
          borderRadius: BorderRadius.circular(32),
          child: SizedBox(
            width: 58,
            height: 58,
            child: Icon(icon, size: 30),
          ),
        ),
      );
  }
}

class JunglePainter extends CustomPainter {
  JunglePainter({
    required this.playerLane,
    required this.traps,
    required this.coins,
    required this.jump,
    required this.slide,
    required this.mode,
    required this.skinColor,
  });

  final int playerLane;
  final List<JungleObject> traps;
  final List<CoinObject> coins;
  final double jump;
  final double slide;
  final GameMode mode;
  final Color skinColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (mode == GameMode.parachuting) {
      sky(canvas, size);
      clouds(canvas, size);
      jungleBelow(canvas, size);
      parachute(canvas, size);
      for (final p in [
        Offset(size.width * .20, size.height * .47),
        Offset(size.width * .38, size.height * .54),
        Offset(size.width * .62, size.height * .45),
        Offset(size.width * .80, size.height * .55),
      ]) {
        coin(canvas, p, .8);
      }
      return;
    }

    jungle(canvas, size);
    road(canvas, size);

    for (final c in coins) {
      coin(canvas,
          Offset(laneX(size, c.lane, c.depth), roadY(size, c.depth)),
          c.depth);
    }

    for (final t in traps) {
      trap(canvas,
          Offset(laneX(size, t.lane, t.depth), roadY(size, t.depth)),
          t.depth, t.type);
    }

    final px = laneX(size, playerLane, 1);
    final py = size.height * .83 -
        math.sin(jump * math.pi) * size.height * .16;
    runner(canvas, Offset(px, py), slide);
  }

  double laneX(Size size, int lane, double depth) {
    final t = depth.clamp(0.0, 1.0).toDouble();
    final left =
        size.width * .39 + (size.width * .02 - size.width * .39) * t;
    final right =
        size.width * .61 + (size.width * .98 - size.width * .61) * t;
    return left + (right - left) * ((lane + .5) / 3);
  }

  double roadY(Size size, double depth) {
    final t = depth.clamp(0.0, 1.0).toDouble();
    return size.height * (.30 + .65 * t);
  }

  void sky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFFB3E5FC), Color(0xFFE8F5E9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );
  }

  void clouds(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: .82);
    for (final c in [
      Offset(size.width * .16, size.height * .17),
      Offset(size.width * .75, size.height * .25),
      Offset(size.width * .48, size.height * .09),
    ]) {
      canvas.drawCircle(c, 27, p);
      canvas.drawCircle(c + const Offset(25, 7), 22, p);
      canvas.drawCircle(c + const Offset(-25, 8), 20, p);
      canvas.drawRect(
        Rect.fromCenter(center: c + const Offset(0, 12), width: 75, height: 25),
        p,
      );
    }
  }

  void jungleBelow(Canvas canvas, Size size) {
    final dark = Paint()..color = const Color(0xFF0C4728);
    final green = Paint()..color = const Color(0xFF176B3A);
    for (int i = 0; i < 14; i++) {
      final x = i * size.width / 13;
      final h = 100.0 + (i % 4) * 28;
      canvas.drawRect(
        Rect.fromLTWH(x, size.height * .62 - h, 18, h), dark);
      canvas.drawCircle(Offset(x + 9, size.height * .62 - h), 38, green);
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .84),
        width: size.width * .7,
        height: 90,
      ),
      Paint()..color = const Color(0xFF4DD0E1),
    );
  }

  void parachute(Canvas canvas, Size size) {
    final c = Offset(size.width * .5, size.height * .34);
    final canopy = Paint()..color = const Color(0xFFFF7043);
    final rect = Rect.fromCenter(center: c, width: 190, height: 105);
    canvas.drawArc(rect, math.pi, math.pi, true, canopy);

    final stripe = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawArc(rect, math.pi, math.pi, false, stripe);

    final line = Paint()..color = Colors.white..strokeWidth = 2;
    canvas.drawLine(Offset(c.dx - 75, c.dy + 4),
        Offset(size.width * .46, size.height * .62), line);
    canvas.drawLine(Offset(c.dx + 75, c.dy + 4),
        Offset(size.width * .54, size.height * .62), line);
    runner(canvas, Offset(size.width * .5, size.height * .67), 0);
  }

  void jungle(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF76C893));
    final far = Paint()..color = const Color(0xFF2D8A57);
    final mid = Paint()..color = const Color(0xFF176B3A);
    final near = Paint()..color = const Color(0xFF0B4D2A);

    for (int i = 0; i < 11; i++) {
      final x = i * size.width / 10;
      canvas.drawCircle(
          Offset(x, size.height * .34), 55 + (i % 3) * 15, far);
      canvas.drawRect(
          Rect.fromLTWH(x - 8, size.height * .27, 16, size.height * .32),
          mid);
    }
    for (int i = 0; i < 7; i++) {
      final x = i * size.width / 6;
      canvas.drawCircle(Offset(x, size.height * .46), 70, near);
    }
    canvas.drawCircle(
        Offset(size.width * .83, size.height * .13), 36,
        Paint()..color = const Color(0xFFFFE082));
  }

  void road(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .39, size.height * .30)
      ..lineTo(size.width * .61, size.height * .30)
      ..lineTo(size.width * .98, size.height)
      ..lineTo(size.width * .02, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF6D4C41));

    final edge = Paint()
      ..color = const Color(0xFF9CCC65)
      ..strokeWidth = 8;
    canvas.drawLine(Offset(size.width * .39, size.height * .30),
        Offset(size.width * .02, size.height), edge);
    canvas.drawLine(Offset(size.width * .61, size.height * .30),
        Offset(size.width * .98, size.height), edge);

    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: .38)
      ..strokeWidth = 3;
    for (int i = 1; i < 3; i++) {
      final topX = size.width * (.39 + i * .073);
      final bottomX = size.width * (.02 + i * .32);
      canvas.drawLine(Offset(topX, size.height * .30),
          Offset(bottomX, size.height), lanePaint);
    }
  }

  void coin(Canvas canvas, Offset center, double depth) {
    final radius = 6 + depth.clamp(0.0, 1.0).toDouble() * 13;
    canvas.drawCircle(center, radius,
        Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(center, radius * .62,
        Paint()..color = const Color(0xFFFFA000));
    canvas.drawCircle(
      center + Offset(-radius * .28, -radius * .28),
      radius * .18,
      Paint()..color = Colors.white.withValues(alpha: .75),
    );
  }

  void trap(Canvas canvas, Offset center, double depth, TrapType type) {
    final s = .45 + depth.clamp(0.0, 1.0).toDouble() * 1.2;
    final p = Paint();

    switch (type) {
      case TrapType.spike:
        p.color = const Color(0xFFECEFF1);
        final path = Path()
          ..moveTo(center.dx - 24 * s, center.dy + 18 * s)
          ..lineTo(center.dx - 10 * s, center.dy - 28 * s)
          ..lineTo(center.dx, center.dy + 18 * s)
          ..lineTo(center.dx + 11 * s, center.dy - 28 * s)
          ..lineTo(center.dx + 24 * s, center.dy + 18 * s)
          ..close();
        canvas.drawPath(path, p);
        break;
      case TrapType.log:
        p.color = const Color(0xFF795548);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 65 * s, height: 25 * s),
            Radius.circular(10 * s)),
          p);
        break;
      case TrapType.rock:
        p.color = const Color(0xFF455A64);
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 55 * s, height: 42 * s), p);
        break;
      case TrapType.gap:
        p.color = const Color(0xFF151515);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 78 * s, height: 22 * s),
            Radius.circular(10 * s)),
          p);
        break;
      case TrapType.branch:
        p
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 13 * s
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(center.dx - 40 * s, center.dy - 15 * s),
            Offset(center.dx + 40 * s, center.dy + 10 * s), p);
        break;
    }
  }

  void runner(Canvas canvas, Offset center, double sliding) {
    final s = sliding > 0 ? .82 : 1.0;
    canvas.drawCircle(Offset(center.dx, center.dy - 45 * s), 14 * s,
        Paint()..color = const Color(0xFFFFCC80));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy - 10 * s),
          width: 28 * s,
          height: 52 * s),
        Radius.circular(10 * s)),
      Paint()..color = skinColor);

    final legs = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 8 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - 7 * s, center.dy + 13 * s),
        Offset(center.dx - 15 * s, center.dy + 42 * s), legs);
    canvas.drawLine(Offset(center.dx + 7 * s, center.dy + 13 * s),
        Offset(center.dx + 15 * s, center.dy + 42 * s), legs);

    final scarf = Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 5 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - 10 * s, center.dy - 29 * s),
        Offset(center.dx - 30 * s, center.dy - 17 * s), scarf);
  }

  @override
  bool shouldRepaint(covariant JunglePainter oldDelegate) => true;
}

class HomePainter extends CustomPainter {
  HomePainter({required this.skinColor});
  final Color skinColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF0B3D2E), Color(0xFF176B3A), Color(0xFF49A078)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect),
    );

    canvas.drawCircle(Offset(size.width * .82, size.height * .15), 42,
        Paint()..color = const Color(0xFFFFE082));

    final tree = Paint()..color = const Color(0xFF082B20);
    for (int i = 0; i < 8; i++) {
      final x = i * size.width / 7;
      canvas.drawRect(
          Rect.fromLTWH(x, size.height * .52, 18, size.height * .48), tree);
      canvas.drawCircle(Offset(x + 9, size.height * .48), 58, tree);
    }

    canvas.drawCircle(Offset(size.width * .5, size.height * .66), 24,
        Paint()..color = skinColor);
    canvas.drawCircle(Offset(size.width * .5, size.height * .60), 13,
        Paint()..color = const Color(0xFFFFCC80));
  }

  @override
  bool shouldRepaint(covariant HomePainter oldDelegate) =>
      oldDelegate.skinColor != skinColor;
}
