import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/item_model.dart';

class DivingGameWidget extends ConsumerStatefulWidget {
  final VoidCallback onFinish;
  const DivingGameWidget({super.key, required this.onFinish});

  @override
  ConsumerState<DivingGameWidget> createState() => _DivingGameWidgetState();
}

class _DivingGameWidgetState extends ConsumerState<DivingGameWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _gameLoopController;
  final Random _random = Random();

  // Game Variables
  double _otterX = 200;
  double _otterY = 100;
  double _otterTargetX = 200;
  double _otterTargetY = 100;
  double _otterVx = 0;
  final double _otterVy = 0;
  bool _facingRight = true;

  double _oxygen = 100.0;
  double _maxOxygen = 100.0;
  double _speedMultiplier = 1.0;
  bool _doubleGather = false;
  bool _deepLens = false;

  int _invulnFrames = 0;
  bool _isGameOver = false;
  bool _isSuccess = false;
  bool _hasStarted = false;

  // Lists of entities
  final List<OceanItem> _items = [];
  final List<Jellyfish> _jellyfish = [];
  final List<SeaUrchin> _urchins = [];
  final List<OxygenBubbleEntity> _oxBubbles = [];
  final List<GameParticle> _particles = [];
  final List<TreasureChest> _chests = [];
  final List<OxygenVent> _vents = [];

  // Collected during this dive
  final Map<String, int> _collectedRaw = {
    'shell': 0,
    'pearl': 0,
    'seaglass': 0,
    'coral': 0,
  };
  int get _totalCollectedCount => _collectedRaw.values.fold(0, (sum, val) => sum + val);
  final int _bagCapacity = 10;

  @override
  void initState() {
    super.initState();
    _gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60 FPS
    )..addListener(_gameTick);

    // Load Talents and setup stats
    final gameState = ref.read(gameStateProvider);
    if (gameState.unlockedTalents.contains('ox_1')) _maxOxygen += 40;
    if (gameState.unlockedTalents.contains('ox_2')) _maxOxygen += 40;
    if (gameState.unlockedTalents.contains('fin_1')) _speedMultiplier = 1.35;
    if (gameState.unlockedTalents.contains('double_gather')) _doubleGather = true;
    if (gameState.unlockedTalents.contains('deep_lens')) _deepLens = true;

    _oxygen = _maxOxygen;
  }

  @override
  void dispose() {
    _gameLoopController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _hasStarted = true;
      _isGameOver = false;
      _isSuccess = false;
      _oxygen = _maxOxygen;
      _collectedRaw.updateAll((key, val) => 0);
      _items.clear();
      _jellyfish.clear();
      _urchins.clear();
      _oxBubbles.clear();
      _particles.clear();
      _chests.clear();
      _vents.clear();
      _otterX = 200;
      _otterY = 80;
      _otterTargetX = 200;
      _otterTargetY = 80;
      _gameLoopController.repeat();
    });
  }

  void _spawnEntities(Size size) {
    if (size.width == 0 || size.height == 0) return;

    // Spawn Vents and Chests once per game
    if (_vents.isEmpty && _hasStarted) {
      final double vx = _random.nextDouble() * (size.width - 120) + 60;
      _vents.add(OxygenVent(x: vx, y: size.height - 25));

      if (_random.nextDouble() < 0.40) {
        double cx = _random.nextDouble() * (size.width - 120) + 60;
        if ((cx - vx).abs() < 80) {
          cx = (vx + 150) % (size.width - 100) + 50;
        }
        _chests.add(TreasureChest(x: cx, y: size.height - 25));
      }
    }

    // Spawn Items
    if (_items.length < 8) {
      final String id = _getRandomItemId();
      final double x = _random.nextDouble() * (size.width - 60) + 30;
      // Spawn items closer to the sea bottom
      final double y = _random.nextDouble() * (size.height * 0.5) + (size.height * 0.45);
      
      _items.add(OceanItem(
        id: id,
        x: x,
        y: y,
        item: GameItem.fromId(id),
      ));
    }

    // Spawn Jellyfish
    if (_jellyfish.length < 3) {
      final double startY = _random.nextDouble() * (size.height * 0.4) + (size.height * 0.2);
      final double speed = (_random.nextDouble() * 1.5 + 1.0) * (_random.nextBool() ? 1 : -1);
      _jellyfish.add(Jellyfish(
        x: speed > 0 ? -30 : size.width + 30,
        y: startY,
        vx: speed,
        pulseOffset: _random.nextDouble() * pi * 2,
      ));
    }

    // Spawn Sea Urchins at the very bottom
    if (_urchins.length < 4) {
      final double x = _random.nextDouble() * (size.width - 60) + 30;
      final double y = size.height - 25; // Floor
      _urchins.add(SeaUrchin(x: x, y: y));
    }

    // Spawn Oxygen Bubbles
    if (_oxBubbles.length < 2 && _random.nextDouble() < 0.015) {
      final double x = _random.nextDouble() * (size.width - 60) + 30;
      _oxBubbles.add(OxygenBubbleEntity(
        x: x,
        y: size.height + 20,
        speed: _random.nextDouble() * 1.5 + 1.0,
        swayAmount: _random.nextDouble() * 8 + 4,
        phase: _random.nextDouble() * pi * 2,
      ));
    }
  }

  String _getRandomItemId() {
    final rand = _random.nextDouble();
    // Probabilities: Shell: 40%, Seaglass: 30%, Pearl: 20%, Coral: 10%
    if (_deepLens) {
      // Improved drops with deep lens
      if (rand < 0.25) return 'shell';
      if (rand < 0.55) return 'seaglass';
      if (rand < 0.80) return 'pearl';
      return 'coral';
    } else {
      if (rand < 0.45) return 'shell';
      if (rand < 0.75) return 'seaglass';
      if (rand < 0.93) return 'pearl';
      return 'coral';
    }
  }

  void _gameTick() {
    if (_isGameOver) return;

    final Size size = MediaQuery.of(context).size;
    _spawnEntities(size);

    setState(() {
      // 1. Move Otter with easing physics
      final double dx = _otterTargetX - _otterX;
      final double dy = _otterTargetY - _otterY;
      
      // Speed adjustments based on fin upgrades
      final double speed = 0.08 * _speedMultiplier;

      _otterVx = dx * speed;
      _otterX += _otterVx;
      _otterY += dy * speed;

      // Update facing direction
      if (_otterVx.abs() > 0.5) {
        _facingRight = _otterVx > 0;
      }

      // Keep inside bounds
      _otterX = _otterX.clamp(20.0, size.width - 20.0);
      _otterY = _otterY.clamp(30.0, size.height - 20.0);

      // Decrement invulnerability frames
      if (_invulnFrames > 0) _invulnFrames--;

      // 2. Decrease Oxygen
      // Oxygen drains slower at the surface (above y=100)
      if (_otterY > 100) {
        _oxygen -= 0.16; // Standard drain
      } else {
        // Refill at surface!
        _oxygen = min(_maxOxygen, _oxygen + 2.5);
        if (_oxygen >= _maxOxygen && _totalCollectedCount > 0) {
          // Cash in!
          _completeDiveWithSuccess();
        }
      }

      if (_oxygen <= 0) {
        _oxygen = 0;
        _completeDiveWithFail();
      }

      // 3. Update Jellyfish
      for (var j in _jellyfish) {
        j.x += j.vx;
        // Bounce or wrap
        if (j.x < -50 || j.x > size.width + 50) {
          j.vx = -j.vx;
        }

        // Collision with Otter
        final double dist = sqrt(pow(j.x - _otterX, 2) + pow(j.y - _otterY, 2));
        if (dist < 32 && _invulnFrames == 0) {
          _oxygen = max(0.0, _oxygen - 25.0);
          _invulnFrames = 60; // 1 second invuln
          _particles.add(GameParticle(
            x: _otterX,
            y: _otterY,
            text: '⚡ -25 O₂',
            color: Colors.redAccent,
            vy: -1.5,
            life: 45,
          ));
          // Stun effect bubbles
          for (int i = 0; i < 5; i++) {
            _particles.add(GameParticle(
              x: _otterX + _random.nextDouble() * 20 - 10,
              y: _otterY + _random.nextDouble() * 20 - 10,
              color: Colors.purpleAccent,
              radius: _random.nextDouble() * 3 + 1,
              vx: _random.nextDouble() * 4 - 2,
              vy: _random.nextDouble() * 4 - 2,
              life: 30,
            ));
          }
        }
      }

      // 4. Update Urchins (static obstacles)
      for (var u in _urchins) {
        final double dist = sqrt(pow(u.x - _otterX, 2) + pow(u.y - _otterY, 2));
        if (dist < 28 && _invulnFrames == 0) {
          _oxygen = max(0.0, _oxygen - 20.0);
          _invulnFrames = 60;
          _particles.add(GameParticle(
            x: _otterX,
            y: _otterY,
            text: '💥 -20 O₂',
            color: Colors.orangeAccent,
            vy: -1.5,
            life: 45,
          ));
        }
      }

      // 5. Update Oxygen Bubbles
      final List<OxygenBubbleEntity> toRemoveBubbles = [];
      for (var b in _oxBubbles) {
        b.y -= b.speed;
        b.phase += 0.05;

        // Collision with Otter
        final double dist = sqrt(pow(b.x + sin(b.phase) * b.swayAmount - _otterX, 2) + pow(b.y - _otterY, 2));
        if (dist < 30) {
          _oxygen = min(_maxOxygen, _oxygen + 20.0);
          toRemoveBubbles.add(b);
          _particles.add(GameParticle(
            x: b.x,
            y: b.y,
            text: '🫧 +20 O₂',
            color: Colors.cyanAccent,
            vy: -1.5,
            life: 45,
          ));
        } else if (b.y < -20) {
          toRemoveBubbles.add(b);
        }
      }
      _oxBubbles.removeWhere((b) => toRemoveBubbles.contains(b));

      // 6. Update Items (Collectibles)
      final List<OceanItem> toRemoveItems = [];
      for (var item in _items) {
        final double dist = sqrt(pow(item.x - _otterX, 2) + pow(item.y - _otterY, 2));
        if (dist < 30) {
          if (_totalCollectedCount < _bagCapacity) {
            _collectedRaw[item.id] = (_collectedRaw[item.id] ?? 0) + 1;
            toRemoveItems.add(item);

            // Floating text particle
            _particles.add(GameParticle(
              x: item.x,
              y: item.y,
              text: '+${item.item.icon}',
              color: item.item.color,
              vy: -2.0,
              life: 40,
            ));
          } else {
            // Bag Full warning particle
            if (_random.nextDouble() < 0.05) {
              _particles.add(GameParticle(
                x: _otterX,
                y: _otterY - 30,
                text: '🎒 가방 가득참!',
                color: Colors.redAccent,
                vy: -1.0,
                life: 30,
              ));
            }
          }
        }
      }
      _items.removeWhere((i) => toRemoveItems.contains(i));

      // 7. Update Particles
      final List<GameParticle> toRemoveParticles = [];
      for (var p in _particles) {
        p.x += p.vx;
        p.y += p.vy;
        p.life--;
        if (p.life <= 0) toRemoveParticles.add(p);
      }
      _particles.removeWhere((p) => toRemoveParticles.contains(p));

      // 8. Update Oxygen Vents
      for (var v in _vents) {
        if (v.bubbleCooldown > 0) {
          v.bubbleCooldown--;
        } else {
          _oxBubbles.add(OxygenBubbleEntity(
            x: v.x,
            y: v.y - 15,
            speed: _random.nextDouble() * 1.0 + 1.2,
            swayAmount: _random.nextDouble() * 4 + 2,
            phase: _random.nextDouble() * pi * 2,
          ));
          v.bubbleCooldown = 90 + _random.nextInt(60);
        }

        // Direct proximity oxygen charge
        final double dist = sqrt(pow(v.x - _otterX, 2) + pow(v.y - _otterY, 2));
        if (dist < 45) {
          _oxygen = min(_maxOxygen, _oxygen + 0.35);
          if (_random.nextDouble() < 0.05) {
            _particles.add(GameParticle(
              x: _otterX + _random.nextDouble() * 20 - 10,
              y: _otterY - 15,
              text: '🫧 O₂',
              color: Colors.cyanAccent,
              vy: -1.0,
              life: 25,
            ));
          }
        }
      }

      // 9. Update Treasure Chests
      for (var c in _chests) {
        if (!c.isOpened) {
          final double dist = sqrt(pow(c.x - _otterX, 2) + pow(c.y - _otterY, 2));
          if (dist < 32) {
            c.isOpened = true;
            final isGold = _random.nextBool();
            if (isGold) {
              final goldGained = 40 + _random.nextInt(41);
              ref.read(gameStateProvider.notifier).addGold(goldGained);
              _particles.add(GameParticle(
                x: c.x,
                y: c.y - 20,
                text: '🎁 🪙 +$goldGained Gold!',
                color: Colors.amberAccent,
                vy: -2.0,
                life: 60,
              ));
            } else {
              final mats = ['pearl', 'coral', 'seaglass'];
              final selectedMat = mats[_random.nextInt(mats.length)];
              final item = GameItem.fromId(selectedMat);

              if (_totalCollectedCount < _bagCapacity) {
                _collectedRaw[selectedMat] = (_collectedRaw[selectedMat] ?? 0) + 1;
                _particles.add(GameParticle(
                  x: c.x,
                  y: c.y - 20,
                  text: '🎁 +${item.icon} ${item.name}!',
                  color: item.color,
                  vy: -2.0,
                  life: 60,
                ));
              } else {
                ref.read(gameStateProvider.notifier).addGold(50);
                _particles.add(GameParticle(
                  x: c.x,
                  y: c.y - 20,
                  text: '🎁 🎒 가득참! 🪙 +50 Gold!',
                  color: Colors.amberAccent,
                  vy: -2.0,
                  life: 60,
                ));
              }
            }

            for (int i = 0; i < 12; i++) {
              final double angle = _random.nextDouble() * pi * 2;
              final double speed = _random.nextDouble() * 4 + 2;
              _particles.add(GameParticle(
                x: c.x,
                y: c.y - 10,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed - 1.0,
                color: Colors.yellowAccent,
                radius: _random.nextDouble() * 3 + 2,
                life: 40 + _random.nextInt(20),
              ));
            }
          }
        }
      }
    });
  }

  void _completeDiveWithSuccess() {
    _gameLoopController.stop();
    setState(() {
      _isGameOver = true;
      _isSuccess = true;
    });

    // Add collected items to global inventory
    final gameNotifier = ref.read(gameStateProvider.notifier);
    _collectedRaw.forEach((itemId, count) {
      if (count > 0) {
        gameNotifier.addRawMaterial(itemId, count);
      }
    });
  }

  void _completeDiveWithFail() {
    _gameLoopController.stop();
    setState(() {
      _isGameOver = true;
      _isSuccess = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          if (!_hasStarted) {
            return Center(
              child: Container(
                width: min(size.width * 0.85, 480),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade900.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.4), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🌊 심해 채집 잠수',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '마우스나 손가락 드래그로 귀여운 수달을 조종하여 바다 속 조개, 진주, 바다유리를 채집하세요!\n'
                        '⚠️ 산소가 바닥나기 전에 수면(맨 위쪽)으로 돌아와야 합니다. 산소가 다 떨어지면 조종 불가 상태가 되어 획득한 아이템을 모두 잃어버립니다!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      // Display stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatChip('❤️ 최대 산소', '${_maxOxygen.round()} O₂', Colors.cyan),
                          _buildStatChip('⚡ 수영 속도', 'x${_speedMultiplier.toStringAsFixed(2)}', Colors.amber),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatChip('🐚 가방 용량', '$_bagCapacity칸', Colors.lightGreen),
                          _buildStatChip('⭐ 더블 채집', _doubleGather ? '활성화' : '미달성', Colors.purpleAccent),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                        child: const Text('잠수 시작하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _otterTargetX = details.localPosition.dx;
                _otterTargetY = details.localPosition.dy;
              });
            },
            onPanDown: (details) {
              setState(() {
                _otterTargetX = details.localPosition.dx;
                _otterTargetY = details.localPosition.dy;
              });
            },
            child: MouseRegion(
              onHover: (event) {
                setState(() {
                  _otterTargetX = event.localPosition.dx;
                  _otterTargetY = event.localPosition.dy;
                });
              },
              child: Stack(
                children: [
                  // The Game Canvas
                  CustomPaint(
                    size: size,
                    painter: DivingGamePainter(
                      otterX: _otterX,
                      otterY: _otterY,
                      facingRight: _facingRight,
                      invuln: _invulnFrames > 0,
                      items: _items,
                      jellyfish: _jellyfish,
                      urchins: _urchins,
                      oxBubbles: _oxBubbles,
                      particles: _particles,
                      chests: _chests,
                      vents: _vents,
                      surfaceY: 100,
                      floorY: size.height - 20,
                    ),
                  ),

                  // Game HUD Overlay
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Oxygen Bar
                        Container(
                          width: 220,
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                          ),
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Container(
                                width: 196 * (_oxygen / _maxOxygen),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _oxygen < 30 ? Colors.redAccent : Colors.cyanAccent,
                                      _oxygen < 30 ? Colors.orangeAccent : Colors.blueAccent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              Positioned(
                                left: 6,
                                child: Text(
                                  '🫧 산소: ${_oxygen.round()} / ${_maxOxygen.round()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bag items info
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _totalCollectedCount >= _bagCapacity ? Colors.redAccent : Colors.greenAccent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🎒 채집 가방: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              Text(
                                '$_totalCollectedCount / $_bagCapacity',
                                style: TextStyle(
                                  color: _totalCollectedCount >= _bagCapacity ? Colors.redAccent : Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Surface Cash-In Indicator
                  if (_totalCollectedCount > 0 && _otterY > 120)
                    Positioned(
                      top: 110,
                      left: size.width / 2 - 100,
                      child: Container(
                        width: 200,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.shade700.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 10)
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              '수면으로 복귀하여 복귀 완료!',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Result Dialog (Game Over overlay)
                  if (_isGameOver)
                    Center(
                      child: Container(
                        width: min(size.width * 0.85, 420),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade900.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isSuccess ? Colors.greenAccent : Colors.redAccent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isSuccess
                                  ? Colors.greenAccent.withOpacity(0.2)
                                  : Colors.redAccent.withOpacity(0.2),
                              blurRadius: 15,
                            )
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                                color: _isSuccess ? Colors.greenAccent : Colors.redAccent,
                                size: 44,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isSuccess ? '🎉 무사히 복귀 성공!' : '💀 기절: 구조됨',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isSuccess
                                    ? '채집한 자원을 안전하게 가게 인벤토리에 보관했습니다.'
                                    : '산소가 고갈되어 바다에서 기절했습니다. 해안 경비대가 구조해 주었지만, 이번 잠수에서 채집한 자원은 유실되었습니다...',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              if (_isSuccess) ...[
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('획득 자원:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: _collectedRaw.entries.map((e) {
                                      final item = GameItem.fromId(e.key);
                                      return Column(
                                        children: [
                                          Text(item.icon, style: const TextStyle(fontSize: 20)),
                                          const SizedBox(height: 2),
                                          Text('${item.name}\nx${e.value}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(color: Colors.white, fontSize: 10)),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  OutlinedButton(
                                    onPressed: widget.onFinish,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white54),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    child: const Text('가게로 가기', style: TextStyle(fontSize: 13)),
                                  ),
                                  ElevatedButton(
                                    onPressed: _startGame,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isSuccess ? Colors.green : Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    child: const Text('한 번 더 잠수', style: TextStyle(fontSize: 13)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

// Entity Classes
class OceanItem {
  final String id;
  final double x;
  final double y;
  final GameItem item;

  OceanItem({required this.id, required this.x, required this.y, required this.item});
}

class Jellyfish {
  double x;
  double y;
  double vx;
  double pulseOffset;

  Jellyfish({required this.x, required this.y, required this.vx, required this.pulseOffset});
}

class SeaUrchin {
  final double x;
  final double y;

  SeaUrchin({required this.x, required this.y});
}

class OxygenBubbleEntity {
  double x;
  double y;
  final double speed;
  final double swayAmount;
  double phase;

  OxygenBubbleEntity({required this.x, required this.y, required this.speed, required this.swayAmount, required this.phase});
}

class GameParticle {
  double x;
  double y;
  double vx;
  double vy;
  String? text;
  Color color;
  double radius;
  int life;

  GameParticle({
    required this.x,
    required this.y,
    this.vx = 0.0,
    this.vy = 0.0,
    this.text,
    required this.color,
    this.radius = 4.0,
    required this.life,
  });
}

class TreasureChest {
  final double x;
  final double y;
  bool isOpened;

  TreasureChest({required this.x, required this.y, this.isOpened = false});
}

class OxygenVent {
  final double x;
  final double y;
  int bubbleCooldown;

  OxygenVent({required this.x, required this.y, this.bubbleCooldown = 0});
}

// 2D Game Painter
class DivingGamePainter extends CustomPainter {
  final double otterX;
  final double otterY;
  final bool facingRight;
  final bool invuln;
  final List<OceanItem> items;
  final List<Jellyfish> jellyfish;
  final List<SeaUrchin> urchins;
  final List<OxygenBubbleEntity> oxBubbles;
  final List<GameParticle> particles;
  final List<TreasureChest> chests;
  final List<OxygenVent> vents;
  final double surfaceY;
  final double floorY;

  DivingGamePainter({
    required this.otterX,
    required this.otterY,
    required this.facingRight,
    required this.invuln,
    required this.items,
    required this.jellyfish,
    required this.urchins,
    required this.oxBubbles,
    required this.particles,
    required this.chests,
    required this.vents,
    required this.surfaceY,
    required this.floorY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Sea Water Gradient Background (Lighter to darker)
    final waterGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF4FC3F7), // Surface
        const Color(0xFF0288D1), // Medium Depth
        const Color(0xFF0D47A1), // Sea Floor
      ],
      stops: const [0.0, 0.4, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = waterGrad.createShader(rect));

    // 2. Draw Sea Floor Sand, Vents, Chests & Plants
    final sandPaint = Paint()..color = const Color(0xFFD7CCC8);
    canvas.drawRect(Rect.fromLTRB(0, floorY, size.width, size.height), sandPaint);

    // Draw Oxygen Vents (glowing volcano shape)
    final ventPaint = Paint()..color = const Color(0xFF37474F);
    final ventGlow = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (var v in vents) {
      canvas.drawCircle(Offset(v.x, v.y - 12), 14, ventGlow);
      final path = Path()
        ..moveTo(v.x - 22, v.y)
        ..lineTo(v.x - 10, v.y - 12)
        ..lineTo(v.x + 10, v.y - 12)
        ..lineTo(v.x + 22, v.y)
        ..close();
      canvas.drawPath(path, ventPaint);

      canvas.drawOval(
        Rect.fromCenter(center: Offset(v.x, v.y - 12), width: 14, height: 4),
        Paint()..color = Colors.cyanAccent,
      );
    }

    // Draw Treasure Chests
    for (var c in chests) {
      if (c.isOpened) {
        final textPainter = TextPainter(
          text: const TextSpan(text: '🔓', style: TextStyle(fontSize: 24)),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(c.x - 12, c.y - 24));
      } else {
        canvas.drawCircle(
          Offset(c.x, c.y - 10),
          18,
          Paint()..color = Colors.amberAccent.withOpacity(0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        final textPainter = TextPainter(
          text: const TextSpan(text: '🎁', style: TextStyle(fontSize: 24)),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(c.x - 12, c.y - 24));
      }
    }

    final grassPaint = Paint()
      ..color = Colors.teal.shade700
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw some simple vector sea grasses at the bottom
    for (int i = 20; i < size.width; i += 60) {
      final double sway = sin(DateTime.now().millisecondsSinceEpoch * 0.003 + i) * 8;
      final path = Path()
        ..moveTo(i.toDouble(), floorY)
        ..quadraticBezierTo(i + sway, floorY - 30, i + sway * 1.5, floorY - 60)
        ..quadraticBezierTo(i + sway, floorY - 20, i.toDouble() + 5, floorY);
      canvas.drawPath(path, Paint()..color = Colors.green.shade800.withOpacity(0.7)..style = PaintingStyle.fill);
    }

    // 3. Draw Water Surface ripples
    final surfacePaint = Paint()..color = Colors.white.withOpacity(0.3);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, surfaceY), surfacePaint);

    // 4. Draw Collectible Items
    for (var it in items) {
      // Small glow behind item
      canvas.drawCircle(
        Offset(it.x, it.y),
        16,
        Paint()..color = it.item.color.withOpacity(0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Draw item emoji/icon
      final textPainter = TextPainter(
        text: TextSpan(text: it.item.icon, style: const TextStyle(fontSize: 22)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(it.x - 11, it.y - 14));
    }

    // 5. Draw Sea Urchins (Obstacles)
    final urchinPaint = Paint()..color = const Color(0xFF212121);
    for (var u in urchins) {
      // Urchin body
      canvas.drawCircle(Offset(u.x, u.y), 10, urchinPaint);
      
      // Spikes
      for (double angle = 0; angle < pi * 2; angle += pi / 6) {
        final double sx = u.x + cos(angle) * 16;
        final double sy = u.y + sin(angle) * 16;
        canvas.drawLine(
          Offset(u.x, u.y),
          Offset(sx, sy),
          Paint()..color = const Color(0xFF212121)..strokeWidth = 2,
        );
      }
    }

    // 6. Draw Jellyfish (Obstacles)
    for (var j in jellyfish) {
      final double time = DateTime.now().millisecondsSinceEpoch * 0.005;
      final double pulse = sin(time + j.pulseOffset) * 4;
      final double capRadius = 14 + pulse;

      // Glow
      canvas.drawCircle(
        Offset(j.x, j.y),
        capRadius + 8,
        Paint()..color = Colors.purpleAccent.withOpacity(0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Jellyfish dome head
      final Paint jPaint = Paint()..color = Colors.purpleAccent.withOpacity(0.8);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(j.x, j.y), radius: capRadius),
        pi,
        pi,
        true,
        jPaint,
      );

      // Tentacles (swaying lines)
      final tentaclePaint = Paint()
        ..color = Colors.purpleAccent.withOpacity(0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      for (int t = -2; t <= 2; t++) {
        final double tx = j.x + t * 5;
        final double ty = j.y;
        final path = Path()..moveTo(tx, ty);

        for (int step = 1; step <= 3; step++) {
          final double segmentY = ty + step * 8;
          final double swayX = tx + sin(time * 1.5 + step + t) * 4;
          path.lineTo(swayX, segmentY);
        }
        canvas.drawPath(path, tentaclePaint);
      }
    }

    // 7. Draw Oxygen Bubbles
    final Paint bubbleOutline = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var b in oxBubbles) {
      final double cx = b.x + sin(b.phase) * b.swayAmount;
      canvas.drawCircle(Offset(cx, b.y), 10, bubbleOutline);
      canvas.drawCircle(Offset(cx - 3, b.y - 3), 3, Paint()..color = Colors.white.withOpacity(0.4));
      
      // Draw O2 letters inside bubble
      final textPainter = TextPainter(
        text: const TextSpan(text: 'O₂', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(cx - 4, b.y - 5));
    }

    // 8. Draw Cute Vector Otter
    final double scale = facingRight ? 1.0 : -1.0;
    canvas.save();
    canvas.translate(otterX, otterY);
    canvas.scale(scale, 1.0);

    // Apply invuln flashing effect
    final Paint otterPaint = Paint()
      ..color = invuln && (DateTime.now().millisecondsSinceEpoch ~/ 100) % 2 == 0
          ? Colors.red.withOpacity(0.6)
          : const Color(0xFF8D6E63); // Otter Brown

    final Paint lightBrown = Paint()..color = const Color(0xFFD7CCC8);
    final Paint nosePaint = Paint()..color = Colors.black87;

    // Body
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-8, 5), width: 42, height: 20),
      otterPaint,
    );

    // Tail (curving back)
    final tailPath = Path()
      ..moveTo(-26, 4)
      ..quadraticBezierTo(-35, 12, -45, 6)
      ..quadraticBezierTo(-35, -2, -26, 2)
      ..close();
    canvas.drawPath(tailPath, otterPaint);

    // Feet
    canvas.drawCircle(const Offset(-18, 12), 5, otterPaint);
    canvas.drawCircle(const Offset(-2, 12), 5, otterPaint);

    // Head
    canvas.drawCircle(const Offset(14, 0), 12, otterPaint);

    // Light brown face/tummy patch
    canvas.drawCircle(const Offset(15, 2), 7, lightBrown);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-4, 6), width: 20, height: 10),
      lightBrown,
    );

    // Ears
    canvas.drawCircle(const Offset(10, -10), 3, otterPaint);
    canvas.drawCircle(const Offset(8, -10), 1.5, lightBrown);

    // Eyes
    canvas.drawCircle(const Offset(17, -2), 1.5, nosePaint);

    // Nose
    canvas.drawCircle(const Offset(22, 1), 1.5, nosePaint);

    // Snout whiskers
    final whiskerPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(22, 2), const Offset(28, 0), whiskerPaint);
    canvas.drawLine(const Offset(22, 2), const Offset(28, 4), whiskerPaint);

    // Arm holding diving bag
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(8, 6), width: 10, height: 6),
      otterPaint,
    );

    // Tiny diving bag
    final bagPaint = Paint()..color = Colors.amber.shade700;
    canvas.drawOval(Rect.fromCenter(center: const Offset(8, 12), width: 8, height: 8), bagPaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(8, 9), width: 5, height: 3), Paint()..color = Colors.brown);

    canvas.restore();

    // 9. Draw Floating Particles & Floating Texts
    for (var p in particles) {
      if (p.text != null) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: p.text!,
            style: TextStyle(
              color: p.color.withOpacity(p.life / 45.0),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(p.x - textPainter.width / 2, p.y - 10));
      } else {
        canvas.drawCircle(
          Offset(p.x, p.y),
          p.radius,
          Paint()..color = p.color.withOpacity(p.life / 30.0),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant DivingGamePainter oldDelegate) => true;
}
