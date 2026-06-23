import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/main_game_screen.dart';
import 'widgets/underwater_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    const ProviderScope(
      child: OceanJewelryApp(),
    ),
  );
}

class LandscapeOrientationWrapper extends StatelessWidget {
  final Widget child;
  const LandscapeOrientationWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        
        // If height > width, it means portrait mode on mobile browser
        if (height > width && width < 600) {
          return const RotationWarningScreen();
        }
        return child;
      },
    );
  }
}

class RotationWarningScreen extends StatefulWidget {
  const RotationWarningScreen({super.key});

  @override
  State<RotationWarningScreen> createState() => _RotationWarningScreenState();
}

class _RotationWarningScreenState extends State<RotationWarningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      body: UnderwaterBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // Rotate back and forth 0 to 90 degrees (0 to 0.25 turns)
                    double val = sin(_controller.value * 2 * pi) * 0.125 + 0.125;
                    return Transform.rotate(
                      angle: val * 2 * pi,
                      child: const Icon(
                        Icons.screen_rotation_rounded,
                        size: 72,
                        color: Colors.cyanAccent,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  "화면을 가로로 돌려주세요!",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "수달의 바다 보석상은 가로 모드에 최적화되어 있습니다.\n스마트폰을 가로로 눕히거나 브라우저 비율을 조절해 주세요.",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white60,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
      builder: (context, child) {
        return LandscapeOrientationWrapper(child: child!);
      },
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
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: UnderwaterBackground(
        child: FadeTransition(
          opacity: _opacity,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Game Logo / Title
                  Text(
                    '🦦',
                    style: GoogleFonts.outfit(fontSize: screenHeight < 400 ? 56 : 76),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Otter's Ocean Jewelry",
                    style: GoogleFonts.outfit(
                      fontSize: screenHeight < 400 ? 32 : 44,
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
                  const SizedBox(height: 4),
                  Text(
                    "수달의 바다 보석상",
                    style: GoogleFonts.outfit(
                      fontSize: screenHeight < 400 ? 16 : 18,
                      color: Colors.cyanAccent.shade200,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 24),

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
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      elevation: 8,
                      shadowColor: Colors.cyanAccent.withOpacity(0.4),
                    ),
                    child: Text(
                      "게임 시작하기",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Inspired by Budgie's Bug Shop • Developed in Flutter Web",
                    style: TextStyle(color: Colors.white30, fontSize: 10),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
