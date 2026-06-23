import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_state.dart';
import '../models/talent_model.dart';
import '../widgets/underwater_background.dart';

class TalentTreeView extends ConsumerStatefulWidget {
  const TalentTreeView({super.key});

  @override
  ConsumerState<TalentTreeView> createState() => _TalentTreeViewState();
}

class _TalentTreeViewState extends ConsumerState<TalentTreeView> {
  TalentNode? _selectedNode;

  @override
  void initState() {
    super.initState();
    _selectedNode = talentNodes.first;
  }

  bool _isTalentUnlockable(TalentNode node, GameState state) {
    if (state.unlockedTalents.contains(node.id)) return false; // Already unlocked

    if (node.prerequisiteId != null) {
      // Must have prerequisite
      return state.unlockedTalents.contains(node.prerequisiteId);
    }
    return true; // No prerequisite
  }

  void _buyTalent(TalentNode node) {
    final success = ref.read(gameStateProvider.notifier).unlockTalent(node.id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 [${node.name}] 특성이 해금되었습니다!'),
          backgroundColor: Colors.purple.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🪙 골드가 부족하거나 해금 조건을 만족하지 못했습니다.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);

    return Scaffold(
      body: UnderwaterBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header display with Gold
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🔮 특성 연구 트리',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Text('🪙 ', style: TextStyle(fontSize: 16)),
                          Text(
                            '보유 골드: ${state.gold}',
                            style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          )
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // Main Content area
                Expanded(
                  child: Row(
                    children: [
                      // Talent Columns grid (Left)
                      Expanded(
                        flex: 7,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white10),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // 1. Diving Column
                              Expanded(
                                child: _buildTalentCategoryColumn(
                                  '🌊 잠수 연구',
                                  TalentCategory.diving,
                                  state,
                                  Colors.cyan,
                                ),
                              ),
                              const VerticalDivider(color: Colors.white12, width: 20),

                              // 2. Crafting Column
                              Expanded(
                                child: _buildTalentCategoryColumn(
                                  '🔨 세공 장인',
                                  TalentCategory.crafting,
                                  state,
                                  Colors.purpleAccent,
                                ),
                              ),
                              const VerticalDivider(color: Colors.white12, width: 20),

                              // 3. Shop Column
                              Expanded(
                                child: _buildTalentCategoryColumn(
                                  '🏪 매장 관리',
                                  TalentCategory.shop,
                                  state,
                                  Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Details and Purchase Panel (Right)
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: _selectedNode == null
                              ? const Center(child: Text('조사할 특성을 선택해 주세요.', style: TextStyle(color: Colors.white60)))
                              : _buildDetailsPanel(state),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTalentCategoryColumn(String title, TalentCategory category, GameState state, Color color) {
    final nodes = talentNodes.where((n) => n.category == category).toList();

    // Group nodes by row
    final Map<int, List<TalentNode>> rows = {};
    for (var node in nodes) {
      rows.putIfAbsent(node.row, () => []).add(node);
    }

    final maxRow = rows.keys.fold(0, (maxVal, val) => val > maxVal ? val : maxVal);

    return Column(
      children: [
        // Category Title
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),

        // Nodes vertical path
        Expanded(
          child: ListView.builder(
            itemCount: maxRow + 1,
            itemBuilder: (context, rowIdx) {
              final rowNodes = rows[rowIdx] ?? [];
              if (rowNodes.isEmpty) return const SizedBox(height: 50);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: rowNodes.map((node) {
                    final isUnlocked = state.unlockedTalents.contains(node.id);
                    final isUnlockable = _isTalentUnlockable(node, state);
                    final isSelected = _selectedNode?.id == node.id;

                    Color nodeBorderColor = Colors.white24;
                    Color nodeBgColor = Colors.transparent;

                    if (isUnlocked) {
                      nodeBorderColor = color;
                      nodeBgColor = color.withOpacity(0.25);
                    } else if (isUnlockable) {
                      nodeBorderColor = Colors.white70;
                      nodeBgColor = Colors.white.withOpacity(0.08);
                    } else {
                      nodeBorderColor = Colors.black45;
                      nodeBgColor = Colors.black.withOpacity(0.2);
                    }

                    if (isSelected) {
                      nodeBorderColor = Colors.white;
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedNode = node;
                        });
                      },
                      child: Tooltip(
                        message: node.name,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: nodeBgColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: nodeBorderColor,
                              width: isSelected ? 3.0 : 1.5,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(node.icon, style: const TextStyle(fontSize: 22)),
                              if (!isUnlocked && !isUnlockable)
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.lock, color: Colors.white60, size: 9),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsPanel(GameState state) {
    final node = _selectedNode!;
    final isUnlocked = state.unlockedTalents.contains(node.id);
    final isUnlockable = _isTalentUnlockable(node, state);
    final hasGold = state.gold >= node.cost;

    TalentNode? prereq;
    if (node.prerequisiteId != null) {
      prereq = talentNodes.firstWhere((n) => n.id == node.prerequisiteId);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node Large Icon and Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  ),
                  child: Text(node.icon, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 10),
                Text(
                  node.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 24),

          // Description
          const Text('연구 설명:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            node.description,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Status
          const Text('연구 상태:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? Colors.green.withOpacity(0.15)
                  : (isUnlockable ? Colors.blue.withOpacity(0.15) : Colors.red.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isUnlocked ? '완료됨' : (isUnlockable ? '연구 가능' : '잠김'),
              style: TextStyle(
                color: isUnlocked
                    ? Colors.greenAccent
                    : (isUnlockable ? Colors.blueAccent : Colors.redAccent),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Prerequisites if any
          if (prereq != null) ...[
            const Text('선행 조건:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(prereq.icon, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Text(
                  '${prereq.name} 해금 필요',
                  style: TextStyle(
                    color: state.unlockedTalents.contains(prereq.id) ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          const Divider(color: Colors.white12, height: 20),

          // Cost and Buy Button
          if (!isUnlocked) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('필요 재화:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  '🪙 ${node.cost} 골드',
                  style: TextStyle(
                    color: hasGold ? Colors.amberAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: (isUnlockable && hasGold) ? () => _buyTalent(node) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white24,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('특성 해금 연구 시작', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('✅ 연구 완료된 특성입니다.', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}
