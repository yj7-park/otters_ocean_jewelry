import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import '../models/item_model.dart';
import '../widgets/underwater_background.dart';

class CraftingView extends ConsumerStatefulWidget {
  const CraftingView({super.key});

  @override
  ConsumerState<CraftingView> createState() => _CraftingViewState();
}

class _CraftingViewState extends ConsumerState<CraftingView> with SingleTickerProviderStateMixin {
  CraftingRecipe? _selectedRecipe;

  // Mini-game State
  bool _isPlayingMiniGame = false;
  late AnimationController _sliderController;
  double _sliderValue = 0.0;
  bool _directionForward = true;

  // Talent factors
  double _perfectWindowHalfWidth = 0.05; // Base +- 0.05 (width 0.10)
  double _rareWindowHalfWidth = 0.15; // Base +- 0.15 (width 0.30)

  @override
  void initState() {
    super.initState();
    _selectedRecipe = recipes.first;

    _sliderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900), // Speed of the slider
    )..addListener(() {
        setState(() {
          if (_directionForward) {
            _sliderValue = _sliderController.value;
            if (_sliderController.value >= 1.0) {
              _directionForward = false;
              _sliderController.reverse();
            }
          } else {
            _sliderValue = _sliderController.value;
            if (_sliderController.value <= 0.0) {
              _directionForward = true;
              _sliderController.forward();
            }
          }
        });
      });
  }

  @override
  void dispose() {
    _sliderController.dispose();
    super.dispose();
  }

  void _loadTalents() {
    final state = ref.read(gameStateProvider);
    double windowScale = 1.0;
    if (state.unlockedTalents.contains('craft_focus_1')) {
      windowScale += 0.20;
    }
    if (state.unlockedTalents.contains('craft_focus_2')) {
      windowScale += 0.20;
    }

    _perfectWindowHalfWidth = 0.05 * windowScale;
    _rareWindowHalfWidth = 0.15 * windowScale;
  }

  void _startCraftingGame() {
    if (_selectedRecipe == null) return;
    _loadTalents();

    setState(() {
      _isPlayingMiniGame = true;
      _sliderValue = 0.0;
      _directionForward = true;
      _sliderController.forward(from: 0.0);
    });
  }

  void _stopSliderAndCraft() {
    _sliderController.stop();
    final double finalVal = _sliderValue;

    // Calculate quality
    final double diff = (finalVal - 0.5).abs();
    ItemQuality quality = ItemQuality.normal;

    if (diff <= _perfectWindowHalfWidth) {
      quality = ItemQuality.perfect;
    } else if (diff <= _rareWindowHalfWidth) {
      quality = ItemQuality.rare;
    }

    // Add item to state
    ref.read(gameStateProvider.notifier).craftJewelry(_selectedRecipe!.resultId, quality);

    // Show result dialog
    _showResultDialog(quality);

    setState(() {
      _isPlayingMiniGame = false;
    });
  }

  void _showResultDialog(ItemQuality quality) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Center(
            child: Text(
              '${quality.label} 등급 세공 성공!',
              style: TextStyle(color: quality.color, fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SparkleEffectWidget(
                color: quality.color,
                child: Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: quality.color, width: 2),
                  ),
                  child: Text(_selectedRecipe!.icon, style: const TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedRecipe!.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                '판매가 배율: x${quality.multiplier}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '기본 가치: ${_selectedRecipe!.baseValue} 🪙  ➔  최종 가치: ${(_selectedRecipe!.baseValue * quality.multiplier).round()} 🪙',
                style: TextStyle(color: Colors.amberAccent.shade400, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('확인'),
              ),
            )
          ],
        );
      },
    );
  }

  bool _hasEnoughMaterials(CraftingRecipe recipe, GameState state) {
    for (var entry in recipe.ingredients.entries) {
      final itemId = entry.key;
      int reqCount = entry.value;

      // luxury_craft reduces royal recipes ingredients by 1
      if (state.unlockedTalents.contains('luxury_craft') &&
          (recipe.resultId == 'ocean_crown' || recipe.resultId == 'deepsea_amulet')) {
        reqCount = max(1, reqCount - 1);
      }

      final available = state.inventoryRaw[itemId] ?? 0;
      if (available < reqCount) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    _loadTalents();

    return Scaffold(
      body: UnderwaterBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🔨 세공 제작소',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Material count short summary
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: GameItem.rawMaterials.map((m) {
                          final count = state.inventoryRaw[m.id] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text('${m.icon}$count', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          );
                        }).toList(),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Main Crafting Layout
                Expanded(
                  child: Row(
                    children: [
                      // Recipes list (Left)
                      Expanded(
                        flex: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: recipes.length,
                            itemBuilder: (context, index) {
                              final recipe = recipes[index];
                              final isSelected = _selectedRecipe?.resultId == recipe.resultId;
                              final canCraft = _hasEnoughMaterials(recipe, state);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedRecipe = recipe;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.cyan.shade900.withOpacity(0.7)
                                        : Colors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? Colors.cyanAccent.withOpacity(0.7) : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(recipe.icon, style: const TextStyle(fontSize: 26)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              recipe.name,
                                              style: TextStyle(
                                                color: canCraft ? Colors.white : Colors.white60,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '가치: ${recipe.baseValue}🪙',
                                              style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (canCraft)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.greenAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Recipe Details & Mini Game (Right)
                      Expanded(
                        flex: 6,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: _selectedRecipe == null
                              ? const Center(child: Text('제작할 레시피를 선택해 주세요.', style: TextStyle(color: Colors.white60)))
                              : _isPlayingMiniGame
                                  ? _buildMiniGameUI()
                                  : _buildRecipeDetailsUI(state),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeDetailsUI(GameState state) {
    final recipe = _selectedRecipe!;
    final canCraft = _hasEnoughMaterials(recipe, state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipe Title Header
        Row(
          children: [
            Text(recipe.icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(recipe.description, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            )
          ],
        ),
        const Divider(color: Colors.white24, height: 32),

        // Ingredients Section
        const Text('필요 재료:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: recipe.ingredients.entries.map((entry) {
              final itemId = entry.key;
              int reqCount = entry.value;

              // Apply luxury_craft talent reduction
              if (state.unlockedTalents.contains('luxury_craft') &&
                  (recipe.resultId == 'ocean_crown' || recipe.resultId == 'deepsea_amulet')) {
                reqCount = max(1, reqCount - 1);
              }

              final item = GameItem.fromId(itemId);
              final available = state.inventoryRaw[itemId] ?? 0;
              final hasEnough = available >= reqCount;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasEnough ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Text(item.icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    Text(
                      '$available / $reqCount',
                      style: TextStyle(
                        color: hasEnough ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),
        // Crafting Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: canCraft ? _startCraftingGame : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.shade700,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white10,
              disabledForegroundColor: Colors.white24,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: const Text(
              '세공 세밀 작업 시작',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniGameUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '🎯 정밀 세공 작업',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          '슬라이더가 가운데에 위치할 때 정지 버튼을 누르세요!\n'
          '완벽 영역에 멈추면 보석 가치가 2.0배로 뜁니다.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.3),
        ),
        const SizedBox(height: 24),

        // Slider Mini-Game Bar
        LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double perfectLeft = width * (0.5 - _perfectWindowHalfWidth);
            final double perfectWidth = width * (_perfectWindowHalfWidth * 2);

            final double rareLeft = width * (0.5 - _rareWindowHalfWidth);
            final double rareWidth = width * (_rareWindowHalfWidth * 2);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Base background bar (Normal Zone)
                Container(
                  width: width,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                ),

                // Rare Zone (Blue)
                Positioned(
                  left: rareLeft,
                  child: Container(
                    width: rareWidth,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.5),
                      border: const Border.symmetric(vertical: BorderSide(color: Colors.blueAccent)),
                    ),
                  ),
                ),

                // Perfect Zone (Purple/Glow)
                Positioned(
                  left: perfectLeft,
                  child: Container(
                    width: perfectWidth,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent,
                      boxShadow: [
                        BoxShadow(color: Colors.purpleAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 1)
                      ],
                    ),
                  ),
                ),

                // Moving Needle/Pointer
                Positioned(
                  left: width * _sliderValue - 5,
                  top: -4,
                  child: Container(
                    width: 10,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ),

                // Center indicator line
                Positioned(
                  left: width * 0.5 - 1,
                  child: Container(
                    width: 2,
                    height: 24,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // STOP/HIT Button
        SizedBox(
          width: 140,
          height: 48,
          child: ElevatedButton(
            onPressed: _stopSliderAndCraft,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
              shadowColor: Colors.purpleAccent.withOpacity(0.3),
            ),
            child: const Text('정지! (STOP)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class SparkleEffectWidget extends StatefulWidget {
  final Widget child;
  final Color color;
  const SparkleEffectWidget({super.key, required this.child, required this.color});

  @override
  State<SparkleEffectWidget> createState() => _SparkleEffectWidgetState();
}

class _SparkleEffectWidgetState extends State<SparkleEffectWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<SparkleParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Spawn star particles radiating outward
    for (int i = 0; i < 20; i++) {
      final double angle = _random.nextDouble() * pi * 2;
      final double speed = _random.nextDouble() * 3.0 + 1.0;
      _particles.add(SparkleParticle(
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: _random.nextDouble() * 6 + 3,
        rotationSpeed: _random.nextDouble() * 3 - 1.5,
      ));
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: SparklePainter(
            particles: _particles,
            progress: _controller.value,
            color: widget.color,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class SparkleParticle {
  final double vx;
  final double vy;
  final double size;
  final double rotationSpeed;

  SparkleParticle({
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotationSpeed,
  });
}

class SparklePainter extends CustomPainter {
  final List<SparkleParticle> particles;
  final double progress;
  final Color color;

  SparklePainter({required this.particles, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final Paint paint = Paint()
      ..color = color.withOpacity(1.0 - progress)
      ..style = PaintingStyle.fill;

    for (var p in particles) {
      final double px = cx + p.vx * progress * 50;
      final double py = cy + p.vy * progress * 50;
      
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(progress * p.rotationSpeed * pi);
      
      final path = Path()
        ..moveTo(0, -p.size)
        ..quadraticBezierTo(0, 0, p.size, 0)
        ..quadraticBezierTo(0, 0, 0, p.size)
        ..quadraticBezierTo(0, 0, -p.size, 0)
        ..quadraticBezierTo(0, 0, 0, -p.size)
        ..close();
      
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant SparklePainter oldDelegate) => true;
}
