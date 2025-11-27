import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'homepage.dart';

class LoadingScreen extends StatefulWidget {
  final String firstName;
  final int durationMillis;

  const LoadingScreen({
    super.key,
    required this.firstName,
    this.durationMillis = 1500,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  Timer? _timer;
  bool _useJpg = false;

  Future<void> _checkAssetFallback() async {
    try {
      await rootBundle.load('assets/images/loading.png');
      if (mounted) setState(() => _useJpg = false);
      // precache png
      if (mounted) {
        precacheImage(const AssetImage('assets/images/loading.png'), context);
      }
    } catch (_) {
      // try jpg fallback
      try {
        await rootBundle.load('assets/images/loading.jpg');
        if (mounted) setState(() => _useJpg = true);
        // precache jpg
        if (mounted) {
          precacheImage(const AssetImage('assets/images/loading.jpg'), context);
        }
      } catch (_) {
        // no asset found; keep default behavior (errorBuilder will show gradient)
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // start asset check then navigate to homepage after duration
    _checkAssetFallback();
    _timer = Timer(Duration(milliseconds: widget.durationMillis), () {
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full screen loading image (fills entire area)
          Positioned.fill(
            child: Image.asset(
              _useJpg
                  ? 'assets/images/loading.jpg'
                  : 'assets/images/loading.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFEFEF1),
                        Color(0xFFFFFF99),
                        Color(0xFFFFFF00),
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // Greeting text overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 80, left: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hello,',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF099509),
                      height: 1.1,
                    ),
                  ),
                  Text(
                    widget.firstName,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF099509),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
