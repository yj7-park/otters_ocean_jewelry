import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/main_game_screen.dart';
import 'widgets/underwater_background.dart';

void main() {
  runApp(
    const ProviderScope(
      child: OceanJewelryApp(),
    ),
  );
}

class OceanJewelryApp extends StatelessWidget {
  const OceanJewelryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Otter's Ocean Jewelry",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
          primary: Colors.cyanAccent,
          secondary: Colors.tealAccent,
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const TitleScreen(),
    );
  }
}

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UnderwaterBackground(
        child: FadeTransition(
          opacity: _opacity,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game Logo / Title
                Text(
                  '🦦',
                  style: GoogleFonts.outfit(fontSize: 84),
                ),
                const SizedBox(height: 16),
                Text(
                  "Otter's Ocean Jewelry",
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      const Shadow(
                        color: Colors.black45,
                        offset: Offset(3, 3),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "수달의 바다 보석상",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    color: Colors.cyanAccent.shade200,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 64),

                // Start Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainGameScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(color: Colors.white24),
                    ),
                    elevation: 10,
                    shadowColor: Colors.cyanAccent.withOpacity(0.4),
                  ),
                  child: Text(
                    "게임 시작하기",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 160),
                const Text(
                  "Inspired by Budgie's Bug Shop • Developed in Flutter Web",
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
