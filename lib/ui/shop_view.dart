import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import '../models/item_model.dart';
import '../widgets/underwater_background.dart';

class ShopView extends ConsumerStatefulWidget {
  final VoidCallback onGoDiving;
  final VoidCallback onGoCrafting;
  const ShopView({super.key, required this.onGoDiving, required this.onGoCrafting});

  @override
  ConsumerState<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends ConsumerState<ShopView> {
  final Random _random = Random();
  Timer? _customerTimer;
  Timer? _trendTimer;
  int _trendCountdown = 60;

  // Active Customers
  final List<CustomerNpc> _customers = [];

  // Floaters for coins
  final List<CoinFloater> _coinFloaters = [];

  @override
  void initState() {
    super.initState();
    _startCustomerSpawnLoop();
    _startTrendTimer();
  }

  @override
  void dispose() {
    _customerTimer?.cancel();
    _trendTimer?.cancel();
    super.dispose();
  }

  void _startCustomerSpawnLoop() {
    // Check spawn speed depending on talent
    final state = ref.read(gameStateProvider);
    double interval = 7.0;
    if (state.unlockedTalents.contains('customer_visit')) {
      interval = 4.5;
    }

    _customerTimer?.cancel();
    _customerTimer = Timer.periodic(Duration(milliseconds: (interval * 1000).round()), (timer) {
      if (mounted) {
        _spawnCustomer();
      }
    });
  }

  void _startTrendTimer() {
    _trendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_trendCountdown > 0) {
          _trendCountdown--;
        } else {
          _trendCountdown = 60;
          ref.read(gameStateProvider.notifier).rollTrend();
          _showToast('📢 오늘의 트렌드가 변경되었습니다!');
        }
      });
    });
  }

  void _spawnCustomer() {
    final size = MediaQuery.of(context).size;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Choose a random shelf slot that has an item to target
    final state = ref.read(gameStateProvider);
    final occupiedSlots = <int>[];
    for (int i = 0; i < state.showcase.length; i++) {
      if (state.showcase[i] != null) {
        occupiedSlots.add(i);
      }
    }

    // Customer appearance
    final types = ['🐢 거북이', '🐙 문어', '🦀 꽃게', '🦑 오징어', '🐠 물고기', '🌟 불가사리'];
    final name = types[_random.nextInt(types.length)];

    final double startX = -100.0;
    final double targetX = size.width * 0.25 + _random.nextDouble() * (size.width * 0.45);
    final double targetY = size.height * 0.45 + _random.nextDouble() * (size.height * 0.15);

    final newCustomer = CustomerNpc(
      id: id,
      name: name,
      x: startX,
      y: targetY,
      targetX: targetX,
      targetY: targetY,
      state: CustomerState.walkingIn,
      targetShelfIdx: occupiedSlots.isNotEmpty ? occupiedSlots[_random.nextInt(occupiedSlots.length)] : null,
    );

    setState(() {
      _customers.add(newCustomer);
    });

    // Animate move in
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _updateCustomer(id, x: targetX, state: CustomerState.arrived);
      
      // Stand and shop for 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _handleShoppingAction(id);
      });
    });
  }

  void _updateCustomer(String id, {double? x, double? y, CustomerState? state}) {
    setState(() {
      final idx = _customers.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _customers[idx] = CustomerNpc(
          id: id,
          name: _customers[idx].name,
          x: x ?? _customers[idx].x,
          y: y ?? _customers[idx].y,
          targetX: _customers[idx].targetX,
          targetY: _customers[idx].targetY,
          state: state ?? _customers[idx].state,
          targetShelfIdx: _customers[idx].targetShelfIdx,
        );
      }
    });
  }

  void _handleShoppingAction(String id) {
    final idx = _customers.indexWhere((c) => c.id == id);
    if (idx == -1) return;

    final customer = _customers[idx];
    final gameState = ref.read(gameStateProvider);
    final targetIdx = customer.targetShelfIdx;

    if (targetIdx != null && targetIdx < gameState.showcase.length && gameState.showcase[targetIdx] != null) {
      // Item is still there! Sell it
      final earned = ref.read(gameStateProvider.notifier).sellItem(targetIdx);
      
      // Update customer bubble
      _updateCustomer(id, state: CustomerState.buying);

      // Create floating coin animation
      setState(() {
        _coinFloaters.add(CoinFloater(
          x: customer.x + 30,
          y: customer.y - 40,
          goldAmount: earned,
        ));
      });

      // Walk out after buying
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        final size = MediaQuery.of(context).size;
        _updateCustomer(id, x: size.width + 120, state: CustomerState.walkingOut);

        // Delete from list after walked away
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() {
            _customers.removeWhere((c) => c.id == id);
          });
        });
      });
    } else {
      // Nothing to buy, walk out sad
      _updateCustomer(id, state: CustomerState.sad);

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        final size = MediaQuery.of(context).size;
        _updateCustomer(id, x: size.width + 120, state: CustomerState.walkingOut);

        // Delete from list
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() {
            _customers.removeWhere((c) => c.id == id);
          });
        });
      });
    }
  }

  void _showShowcasePlacementSelector(int slotIdx) {
    final state = ref.read(gameStateProvider);
    if (state.inventoryJewelry.isEmpty) {
      _showToast('💎 진열할 완성품 보석이 인벤토리에 없습니다. 먼저 제작해 주세요!');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.blueGrey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentState = ref.watch(gameStateProvider);
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '진열할 보석 선택',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (currentState.inventoryJewelry.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('진열할 완성품이 없습니다.', style: TextStyle(color: Colors.white60)),
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: currentState.inventoryJewelry.length,
                        itemBuilder: (context, index) {
                          final item = currentState.inventoryJewelry[index];
                          final recipe = recipes.firstWhere((r) => r.resultId == item.recipeId);
                          final isTrend = currentState.todayTrendId == recipe.resultId;

                          return GestureDetector(
                            onTap: () {
                              ref.read(gameStateProvider.notifier).placeOnShowcase(slotIdx, item);
                              Navigator.pop(context);
                              _showToast('🏪 ${recipe.name}(${item.quality.label})을 진열대에 올렸습니다!');
                              // Restart loop with new targets
                              _startCustomerSpawnLoop();
                            },
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 16, bottom: 8, top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isTrend ? Colors.amberAccent : Colors.cyanAccent.withOpacity(0.2),
                                  width: isTrend ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(recipe.icon, style: const TextStyle(fontSize: 32)),
                                  const SizedBox(height: 8),
                                  Text(
                                    recipe.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: item.quality.color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.quality.label,
                                      style: TextStyle(color: item.quality.color, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('보유량: ${item.count}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    final trendItem = recipes.firstWhere((r) => r.resultId == state.todayTrendId, orElse: () => recipes.first);

    return Scaffold(
      body: UnderwaterBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Title/Header Info Bar
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Gold Display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.amberAccent.withOpacity(0.1), blurRadius: 10)
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙 ', style: TextStyle(fontSize: 20)),
                          Text(
                            '${state.gold}',
                            style: GoogleFonts.outfit(
                              color: Colors.amberAccent,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Today's Trend Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.pinkAccent.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📢 트렌드: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text(
                            '${trendItem.icon} ${trendItem.name}',
                            style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            ' (${state.trendMultiplier}배!) ',
                            style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          // Countdown circle
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  value: _trendCountdown / 60.0,
                                  strokeWidth: 2,
                                  color: Colors.pinkAccent,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                              Text(
                                '$_trendCountdown',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Active Customer NPCs (walking, looking, buying)
              ..._customers.map((c) {
                String bubbleText = '';
                Color bubbleColor = Colors.white;
                bool showBubble = false;

                switch (c.state) {
                  case CustomerState.walkingIn:
                    break;
                  case CustomerState.arrived:
                    final item = c.targetShelfIdx != null ? state.showcase[c.targetShelfIdx!] : null;
                    bubbleText = item != null ? '음.. ${recipes.firstWhere((r) => r.resultId == item.recipeId).name}인가..' : '흠.. 뭘 살까?';
                    showBubble = true;
                    break;
                  case CustomerState.buying:
                    bubbleText = '❤️ 이거 살게요!';
                    bubbleColor = Colors.greenAccent;
                    showBubble = true;
                    break;
                  case CustomerState.sad:
                    bubbleText = '🌧️ 살 게 없네..';
                    bubbleColor = Colors.orangeAccent;
                    showBubble = true;
                    break;
                  case CustomerState.walkingOut:
                    break;
                }

                return AnimatedPositioned(
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  left: c.x,
                  top: c.y,
                  child: Column(
                    children: [
                      if (showBubble)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: Text(
                            bubbleText,
                            style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade800.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                        ),
                        child: Text(
                          c.name,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // 3. Floating Coins
              ..._coinFloaters.map((f) {
                return CoinFloaterWidget(
                  floater: f,
                  onFinished: () {
                    setState(() {
                      _coinFloaters.remove(f);
                    });
                  },
                );
              }),

              // 4. Shop Counters & Showcase Slots (Center)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80.0, bottom: 120.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '🐚 수달의 진열 매대 🐚',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Grid representation of counters
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20,
                        runSpacing: 20,
                        children: List.generate(state.showcase.length, (idx) {
                          final item = state.showcase[idx];

                          return GestureDetector(
                            onTap: () {
                              if (item == null) {
                                _showShowcasePlacementSelector(idx);
                              } else {
                                // Take it back
                                ref.read(gameStateProvider.notifier).takeFromShowcase(idx);
                                _showToast('📥 진열대에서 다시 수거했습니다.');
                              }
                            },
                            child: Container(
                              width: 130,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade900.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: item != null
                                      ? (state.todayTrendId == item.recipeId ? Colors.pinkAccent : Colors.cyanAccent)
                                      : Colors.white24,
                                  width: item != null ? 2 : 1,
                                ),
                                boxShadow: [
                                  if (item != null)
                                    BoxShadow(
                                      color: (state.todayTrendId == item.recipeId ? Colors.pinkAccent : Colors.cyanAccent).withOpacity(0.25),
                                      blurRadius: 12,
                                    )
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Shelf background drawing
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 35,
                                      decoration: BoxDecoration(
                                        color: Colors.brown.shade800.withOpacity(0.9),
                                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '진열대 ${idx + 1}',
                                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                                      ),
                                    ),
                                  ),

                                  // Showcase contents
                                  if (item != null) ...[
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            recipes.firstWhere((r) => r.resultId == item.recipeId).icon,
                                            style: const TextStyle(fontSize: 40),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            recipes.firstWhere((r) => r.resultId == item.recipeId).name,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: item.quality.color.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item.quality.label,
                                              style: TextStyle(color: item.quality.color, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(height: 15), // space for shelf
                                        ],
                                      ),
                                    ),
                                    // Trend Tag
                                    if (state.todayTrendId == item.recipeId)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.pinkAccent,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'HOT',
                                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ] else
                                    const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_circle_outline, color: Colors.white38, size: 28),
                                          SizedBox(height: 6),
                                          Text('진열하기', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                          SizedBox(height: 15),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Bottom Navigation / Quick Actions Panel
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Row(
                  children: [
                    // Crafting Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onGoCrafting,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade800.withOpacity(0.9),
                          foregroundColor: Colors.white,
                          shadowColor: Colors.black45,
                          elevation: 6,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.cyanAccent.withOpacity(0.4)),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🔨 ', style: TextStyle(fontSize: 18)),
                            Text('세공 제작소', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Diving Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onGoDiving,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan.shade700.withOpacity(0.9),
                          foregroundColor: Colors.white,
                          shadowColor: Colors.cyanAccent.withOpacity(0.3),
                          elevation: 6,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.cyanAccent),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🌊 ', style: TextStyle(fontSize: 18)),
                            Text('바다 잠수', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// NPC Customer Data Model
enum CustomerState { walkingIn, arrived, buying, sad, walkingOut }

class CustomerNpc {
  final String id;
  final String name;
  final double x;
  final double y;
  final double targetX;
  final double targetY;
  final CustomerState state;
  final int? targetShelfIdx;

  CustomerNpc({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
    required this.state,
    this.targetShelfIdx,
  });
}

// Coin Floater Animation Model
class CoinFloater {
  final double x;
  final double y;
  final int goldAmount;
  CoinFloater({required this.x, required this.y, required this.goldAmount});
}

class CoinFloaterWidget extends StatefulWidget {
  final CoinFloater floater;
  final VoidCallback onFinished;
  const CoinFloaterWidget({super.key, required this.floater, required this.onFinished});

  @override
  State<CoinFloaterWidget> createState() => _CoinFloaterWidgetState();
}

class _CoinFloaterWidgetState extends State<CoinFloaterWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateY;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _translateY = Tween<double>(begin: 0.0, end: -60.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0)),
    );

    _controller.forward().then((_) => widget.onFinished());
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
        return Positioned(
          left: widget.floater.x,
          top: widget.floater.y + _translateY.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '+${widget.floater.goldAmount}',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
