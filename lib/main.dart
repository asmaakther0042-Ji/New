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
    theme: ThemeData.dark(useMaterial3: true),
    home: const HomeScreen(),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int coins = 0, diamonds = 0, selected = 0;
  final Set<int> owned = {0};
  final colors = [
    const Color(0xFF20C878), const Color(0xFF42A5F5),
    const Color(0xFFFF7043), const Color(0xFFFFC107)
  ];

  void start() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(
      skin: colors[selected], coins: coins, diamonds: diamonds,
      onDone: (c, d) => setState(() { coins = c; diamonds = d; }),
    )));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Stack(children: [
      CustomPaint(size: Size.infinite, painter: const HomePainter()),
      Positioned(top: 14, left: 14, right: 14, child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_badge('🪙 ' + coins.toString()), _badge('💎 ' + diamonds.toString())],
      )),
      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('JUNGLE', style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900, letterSpacing: 5)),
        const Text('RUSH', style: TextStyle(fontSize: 62, fontWeight: FontWeight.w900, color: Color(0xFFFFD54F), letterSpacing: 7)),
        const SizedBox(height: 30),
        FilledButton.icon(
          onPressed: start,
          icon: const Icon(Icons.play_arrow_rounded, size: 32),
          label: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 35, vertical: 15),
            child: Text('START RUN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _shop(context),
          icon: const Icon(Icons.shopping_bag_rounded),
          label: const Text('CHARACTER SHOP'),
        ),
      ])),
    ])),
  );

  Widget _badge(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(22)),
    child: Text(s, style: const TextStyle(fontWeight: FontWeight.w900)),
  );

  void _shop(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF103326),
      builder: (_) => StatefulBuilder(builder: (context, refresh) {
        final names = ['Explorer', 'Sky Blue', 'Sunset', 'Golden'];
        final prices = [0, 120, 250, 500];
        return SafeArea(child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('CHARACTER SHOP', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('🪙 ' + coins.toString() + '   💎 ' + diamonds.toString()),
            ...List.generate(4, (i) => Card(child: ListTile(
              leading: CircleAvatar(backgroundColor: colors[i]),
              title: Text(names[i]),
              subtitle: Text(prices[i] == 0 ? 'Free' : prices[i].toString() + ' coins'),
              trailing: FilledButton(
                onPressed: owned.contains(i)
                  ? () { setState(() => selected = i); refresh(() {}); }
                  : coins >= prices[i]
                    ? () { setState(() { coins -= prices[i]; owned.add(i); selected = i; }); refresh(() {}); }
                    : null,
                child: Text(
                  selected == i ? 'SELECTED' : (owned.contains(i) ? 'USE' : 'BUY'),
                ),
              ),
            ))),
          ]),
        ));
      }),
    );
  }
}

enum GameMode { run, parachute }
enum TrapType { spike, rock, branch, log, gap }

class Trap {
  Trap(this.type, this.depth);
  final TrapType type;
  double depth;
  bool checked = false;
}
class Coin {
  Coin(this.depth);
  double depth;
  bool taken = false;
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key, required this.skin, required this.coins,
    required this.diamonds, required this.onDone,
  });
  final Color skin;
  final int coins, diamonds;
  final void Function(int, int) onDone;
  @override State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Timer? timer;
  final random = math.Random();
  final traps = <Trap>[];
  final skyCoins = <Coin>[];
  late int coins = widget.coins, diamonds = widget.diamonds;
  GameMode mode = GameMode.run;
  int score = 0, lightHits = 0;
  double distance = 0, speed = .40, jump = 0, slide = 0;
  double birdDistance = .78, spawnClock = 0;
  double parachuteTime = 15, nextParachute = 650;
  bool over = false;

  @override void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 40), (_) => tick());
  }
  @override void dispose() {
    timer?.cancel();
    widget.onDone(coins, diamonds);
    super.dispose();
  }

  void tick() {
    if (!mounted || over) return;
    setState(() {
      if (mode == GameMode.run) {
        distance += speed * 1.5; score++;
        speed = math.min(1.0, speed + .00015);
        birdDistance = math.min(1.0, birdDistance + .0025);
        spawnClock += .04;
        if (spawnClock > math.max(.42, .86 - speed * .25)) {
          spawn();
          spawnClock = 0;
        }
        for (final t in traps) t.depth += speed * .033;
        for (final c in skyCoins) c.depth += speed * .033;
        jump = math.max(0, jump - .055);
        slide = math.max(0, slide - .055);
        checkCoins();
        checkTraps();
        traps.removeWhere((t) => t.depth > 1.08 || t.checked);
        skyCoins.removeWhere((c) => c.depth > 1.08 || c.taken);
        if (distance >= nextParachute) startParachute();
      } else {
        parachuteTime -= .04; score += 2;
        for (final c in skyCoins) c.depth += .01;
        checkParachuteCoins();
        skyCoins.removeWhere((c) => c.depth > 1.08 || c.taken);
        if (random.nextDouble() < .10) skyCoins.add(Coin(random.nextDouble() * .55));
        if (parachuteTime <= 0) land();
      }
    });
  }

  void spawn() {
    final types = TrapType.values;
    traps.add(Trap(types[random.nextInt(types.length)], 0));
    for (int i = 0; i < 3; i++) skyCoins.add(Coin(-.14 * i));
  }

  void checkCoins() {
    for (final c in skyCoins) {
      if (!c.taken && c.depth > .78 && c.depth < 1.03) {
        c.taken = true; coins++; score += 20;
      }
    }
  }

  void checkParachuteCoins() {
    for (final c in skyCoins) {
      if (!c.taken && c.depth > .72 && c.depth < .92) {
        c.taken = true;
        coins++;
        score += 25;
      }
    }
  }

  bool avoided(TrapType t) => t == TrapType.branch ? slide > .28 : jump > .28;
  bool heavy(TrapType t) => t == TrapType.spike || t == TrapType.gap;

  void checkTraps() {
    for (final t in traps) {
      if (t.checked || t.depth < .82 || t.depth > 1.02) continue;
      t.checked = true;
      if (avoided(t.type)) {
        score += 35;
        birdDistance = math.min(1.0, birdDistance + .035);
      } else if (heavy(t.type)) {
        endGame('Heavy collision!');
        return;
      } else {
        lightHits++;
        birdDistance = math.max(.08, birdDistance - .22);
        score = math.max(0, score - 40);
        if (lightHits >= 2) {
          endGame('The monster bird caught you!');
          return;
        }
        toast('Light hit! The monster bird is closer.');
      }
    }
  }

  void startParachute() {
    mode = GameMode.parachute;
    parachuteTime = 15;
    traps.clear(); skyCoins.clear();
    for (int i = 0; i < 5; i++) skyCoins.add(Coin(-.10 * i));
    toast('🪂 Parachute! Collect sky coins.');
  }

  void land() {
    mode = GameMode.run;
    diamonds++;
    score += 250;
    nextParachute = distance + 850;
    birdDistance = math.min(1.0, birdDistance + .15);
    toast('💎 Safe landing! +1 Diamond');
  }

  void endGame(String reason) {
    over = true; timer?.cancel();
    Future.microtask(() {
      if (!mounted) return;
      showDialog(
        context: context, barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('GAME OVER'),
          content: Text(reason + '\n\nScore: ' + score.toString() +
              '\nCoins: ' + coins.toString() +
              '\nDiamonds: ' + diamonds.toString()),
          actions: [
            if (diamonds > 0) FilledButton(
              onPressed: () { Navigator.pop(context); revive(); },
              child: const Text('REVIVE • 1 💎'),
            ),
            TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('HOME'),
            ),
          ],
        ),
      );
    });
  }

  void revive() {
    setState(() {
      diamonds--; over = false; lightHits = 0; birdDistance = .75;
      traps.clear(); skyCoins.clear(); jump = 0; slide = 0; mode = GameMode.run;
    });
    timer = Timer.periodic(const Duration(milliseconds: 40), (_) => tick());
  }

  void toast(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(
      SnackBar(content: Text(s), duration: const Duration(milliseconds: 1200)));
  }

  void jumpUp() {
    if (mode == GameMode.run && jump <= 0 && !over) setState(() => jump = 1);
  }
  void slideDown() {
    if (mode == GameMode.run && slide <= 0 && !over) setState(() => slide = 1);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -180) jumpUp();
        if (v > 180) slideDown();
      },
      child: Stack(fit: StackFit.expand, children: [
        CustomPaint(painter: GamePainter(
          mode: mode, traps: traps, coins: skyCoins, jump: jump,
          slide: slide, skin: widget.skin, birdDistance: birdDistance,
        )),
        Positioned(top: 10, left: 10, right: 10, child: Row(children: [
          _hud('🏆 ' + score.toString()),
          const SizedBox(width: 5), _hud('🪙 ' + coins.toString()),
          const SizedBox(width: 5), _hud('💎 ' + diamonds.toString()),
          const Spacer(), _hud('⚡ ' + lightHits.toString() + '/2'),
        ])),
        if (mode == GameMode.parachute) Positioned(
          top: 60, left: 0, right: 0,
          child: Center(child: _hud('🪂 ' + parachuteTime.ceil().toString() + 's  •  🪙 collect')),
        ),
      ]),
    )),
  );

  Widget _hud(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(18)),
    child: Text(s, style: const TextStyle(fontWeight: FontWeight.w900)),
  );
}

class GamePainter extends CustomPainter {
  GamePainter({
    required this.mode, required this.traps, required this.coins,
    required this.jump, required this.slide, required this.skin,
    required this.birdDistance,
  });
  final GameMode mode;
  final List<Trap> traps;
  final List<Coin> coins;
  final double jump, slide, birdDistance;
  final Color skin;

  @override
  void paint(Canvas canvas, Size size) {
    if (mode == GameMode.parachute) {
      sky(canvas, size);
      for (final c in coins) {
        coin(canvas, Offset(size.width * (.22 + c.depth * .8), size.height * .55), .8);
      }
      parachute(canvas, size);
      return;
    }
    jungle(canvas, size);
    road(canvas, size);
    bird(canvas, size);
    for (final c in coins) coin(canvas, Offset(size.width / 2, roadY(size, c.depth)), c.depth);
    for (final t in traps) trap(canvas, Offset(size.width / 2, roadY(size, t.depth)), t.depth, t.type);
    final y = size.height * .82 - math.sin(jump * math.pi) * size.height * .17;
    runner(canvas, Offset(size.width / 2, y), slide);
  }

  double roadY(Size s, double d) => s.height * (.30 + .67 * d.clamp(0.0, 1.0));

  void jungle(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF58A85F));
    final p = Paint()..color = const Color(0xFF0B4D2A);
    for (int i = 0; i < 10; i++) {
      final x = i * s.width / 9;
      c.drawRect(Rect.fromLTWH(x, s.height * .36, 18, s.height * .64), p);
      c.drawCircle(Offset(x + 9, s.height * .36), 68, p);
    }
    c.drawCircle(Offset(s.width * .82, s.height * .13), 35,
        Paint()..color = const Color(0xFFFFE082));
  }

  void road(Canvas c, Size s) {
    final path = Path()
      ..moveTo(s.width * .43, s.height * .30)
      ..lineTo(s.width * .57, s.height * .30)
      ..lineTo(s.width * .96, s.height)
      ..lineTo(s.width * .04, s.height)..close();
    c.drawPath(path, Paint()..color = const Color(0xFF795548));
    final e = Paint()..color = const Color(0xFF9CCC65)..strokeWidth = 9;
    c.drawLine(Offset(s.width*.43,s.height*.30), Offset(s.width*.04,s.height), e);
    c.drawLine(Offset(s.width*.57,s.height*.30), Offset(s.width*.96,s.height), e);
  }

  void bird(Canvas c, Size s) {
    final close = 1 - birdDistance;
    final x = s.width / 2, y = s.height * (.68 + close * .08);
    final z = .65 + close * .55;
    final p = Paint()..color = const Color(0xFF311B3F);
    c.drawOval(Rect.fromCenter(center: Offset(x-28*z,y), width: 55*z, height: 32*z), p);
    c.drawOval(Rect.fromCenter(center: Offset(x+28*z,y), width: 55*z, height: 32*z), p);
    c.drawCircle(Offset(x,y), 25*z, p);
    c.drawPath(Path()..moveTo(x+18*z,y-3*z)..lineTo(x+45*z,y+7*z)..lineTo(x+18*z,y+14*z)..close(),
      Paint()..color = const Color(0xFFFFB300));
  }

  void coin(Canvas c, Offset p, double d) {
    final r = 7 + d.clamp(0.0,1.0)*12;
    c.drawCircle(p, r, Paint()..color = const Color(0xFFFFD54F));
    c.drawCircle(p, r*.58, Paint()..color = const Color(0xFFFFA000));
  }

  void trap(Canvas c, Offset p, double d, TrapType t) {
    final z = .45 + d.clamp(0.0,1.0)*1.15;
    if (t == TrapType.spike) {
      c.drawPath(Path()..moveTo(p.dx-28*z,p.dy+20*z)..lineTo(p.dx,p.dy-30*z)..lineTo(p.dx+28*z,p.dy+20*z)..close(),
        Paint()..color = Colors.white);
    } else if (t == TrapType.branch) {
      c.drawLine(Offset(p.dx-50*z,p.dy-12*z), Offset(p.dx+50*z,p.dy+12*z),
        Paint()..color = const Color(0xFF5D4037)..strokeWidth = 14*z..strokeCap = StrokeCap.round);
    } else {
      c.drawOval(Rect.fromCenter(center:p,width:70*z,height:45*z),
        Paint()..color = t == TrapType.rock ? const Color(0xFF455A64) : const Color(0xFF795548));
    }
  }

  void runner(Canvas c, Offset p, double sl) {
    final z = sl > 0 ? .78 : 1.0;
    c.drawCircle(Offset(p.dx,p.dy-45*z),14*z,Paint()..color=const Color(0xFFFFCC80));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(p.dx,p.dy-10*z),width:29*z,height:52*z),Radius.circular(10*z)),Paint()..color=skin);
    final legs=Paint()..color=const Color(0xFF263238)..strokeWidth=8*z..strokeCap=StrokeCap.round;
    c.drawLine(Offset(p.dx-7*z,p.dy+14*z),Offset(p.dx-15*z,p.dy+42*z),legs);
    c.drawLine(Offset(p.dx+7*z,p.dy+14*z),Offset(p.dx+15*z,p.dy+42*z),legs);
  }

  void sky(Canvas c, Size s) {
    c.drawRect(Offset.zero&s,Paint()..shader=const LinearGradient(
      colors:[Color(0xFF4FC3F7),Color(0xFFB3E5FC),Color(0xFFE8F5E9)],
      begin:Alignment.topCenter,end:Alignment.bottomCenter).createShader(Offset.zero&s));
  }

  void parachute(Canvas c, Size s) {
    final p=Offset(s.width/2,s.height*.34);
    c.drawArc(Rect.fromCenter(center:p,width:210,height:115),math.pi,math.pi,true,Paint()..color=const Color(0xFFFF7043));
    final line=Paint()..color=Colors.white..strokeWidth=2;
    c.drawLine(Offset(p.dx-80,p.dy+2),Offset(s.width*.46,s.height*.63),line);
    c.drawLine(Offset(p.dx+80,p.dy+2),Offset(s.width*.54,s.height*.63),line);
    runner(c,Offset(s.width/2,s.height*.68),0);
  }

  @override bool shouldRepaint(covariant GamePainter oldDelegate)=>true;
}

class HomePainter extends CustomPainter {
  const HomePainter();
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero&s,Paint()..shader=const LinearGradient(
      colors:[Color(0xFF063B2B),Color(0xFF176B3A),Color(0xFF49A078)],
      begin:Alignment.topCenter,end:Alignment.bottomCenter).createShader(Offset.zero&s));
    final p=Paint()..color=const Color(0xFF082B20);
    for(int i=0;i<8;i++){final x=i*s.width/7;c.drawRect(Rect.fromLTWH(x,s.height*.52,18,s.height*.48),p);c.drawCircle(Offset(x+9,s.height*.48),58,p);}
  }
  @override bool shouldRepaint(covariant HomePainter oldDelegate)=>false;
}
