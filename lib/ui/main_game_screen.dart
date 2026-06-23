import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shop_view.dart';
import 'crafting_view.dart';
import 'talent_tree_view.dart';
import '../game/diving_game_widget.dart';

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  int _currentTabIdx = 0;
  bool _isDiving = false;

  @override
  Widget build(BuildContext context) {
    if (_isDiving) {
      return DivingGameWidget(
        onFinish: () {
          setState(() {
            _isDiving = false;
            _currentTabIdx = 0; // Return to shop
          });
        },
      );
    }

    final List<Widget> tabs = [
      ShopView(
        onGoDiving: () {
          setState(() {
            _isDiving = true;
          });
        },
        onGoCrafting: () {
          setState(() {
            _currentTabIdx = 1; // Go to crafting tab
          });
        },
      ),
      const CraftingView(),
      const TalentTreeView(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          children: [
            // Left Navigation Sidebar
            Container(
              width: 76,
              decoration: const BoxDecoration(
                color: Color(0xFF0B0E14),
                border: Border(
                  right: BorderSide(color: Colors.white10, width: 1),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    '🦦',
                    style: GoogleFonts.outfit(fontSize: 26),
                  ),
                  const Spacer(),
                  _buildNavItem(0, Icons.storefront, Icons.storefront_outlined, '진열 상점'),
                  const SizedBox(height: 20),
                  _buildNavItem(1, Icons.gavel, Icons.gavel_outlined, '세공 공방'),
                  const SizedBox(height: 20),
                  _buildNavItem(2, Icons.auto_awesome, Icons.auto_awesome_outlined, '특성 연구'),
                  const Spacer(),
                  const Text(
                    'v1.0',
                    style: TextStyle(color: Colors.white12, fontSize: 10),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: IndexedStack(
                index: _currentTabIdx,
                children: tabs,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentTabIdx == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTabIdx = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.cyanAccent.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? Colors.cyanAccent.withOpacity(0.3) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? Colors.cyanAccent : Colors.white38,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.cyanAccent : Colors.white38,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
