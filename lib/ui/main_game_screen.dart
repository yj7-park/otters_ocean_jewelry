import 'package:flutter/material.dart';
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
      body: IndexedStack(
        index: _currentTabIdx,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B0E14).withOpacity(0.9),
          border: const Border(
            top: BorderSide(color: Colors.white10, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIdx,
          onTap: (index) {
            setState(() {
              _currentTabIdx = index;
            });
          },
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront, color: Colors.cyanAccent),
              label: '진열 상점',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.gavel_outlined),
              activeIcon: Icon(Icons.gavel, color: Colors.cyanAccent),
              label: '세공 공방',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome, color: Colors.cyanAccent),
              label: '특성 연구',
            ),
          ],
        ),
      ),
    );
  }
}
