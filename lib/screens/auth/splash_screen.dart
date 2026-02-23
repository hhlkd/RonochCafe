import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ronoch_coffee/provider/product_provider.dart';
import 'package:ronoch_coffee/provider/user_provider.dart';
import 'package:ronoch_coffee/screens/auth/welcome_screen.dart';
import 'package:ronoch_coffee/screens/home_screen.dart';
import 'package:ronoch_coffee/services/user_session.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _steamAnimation;
  late Animation<Offset> _slideAnimation;
  bool _productsLoaded = false;
  bool _animationCompleted = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _steamAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      setState(() {
        _animationCompleted = true;
      });
      _checkAndNavigate();
    });

    _loadProducts();
    _loadUserSession();
  }

  Future<void> _loadProducts() async {
    try {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );

      await productProvider.loadProducts();

      setState(() {
        _productsLoaded = true;
      });

      _checkAndNavigate();
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _productsLoaded = true;
      });
      _checkAndNavigate();
    }
  }

  Future<void> _loadUserSession() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await userProvider.loadUserFromSession();
    } catch (e) {
      print('Error loading user session: $e');
    }
  }

  Future<void> _checkAndNavigate() async {
    if (_animationCompleted && _productsLoaded && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        final isLoggedIn = await UserSession.isLoggedIn();

        if (isLoggedIn) {
          print('✅ User already logged in - navigating to HomeScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          print('👤 User not logged in - navigating to WelcomeScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6F4E37),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: CoffeeBeansPainter(animation: _controller),
                  ),
                ),

                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8B7355),
                                    Color(0xFF6F4E37),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.coffee_maker_rounded,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          if (_steamAnimation.value > 0)
                            Positioned(
                              top: -40,
                              child: Opacity(
                                opacity: _steamAnimation.value,
                                child: Container(
                                  width: 80,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.8),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 40),
                      FadeTransition(
                        opacity: _textFadeAnimation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _controller,
                              curve: const Interval(
                                0.5,
                                1.0,
                                curve: Curves.easeOutBack,
                              ),
                            ),
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [Colors.white, Color(0xFFD7CCC8)],
                              ).createShader(bounds);
                            },
                            child: Text(
                              'RONOCH COFFEE',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _textFadeAnimation,
                          child: Text(
                            'Elevating coffee excellence',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                      FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(
                              0.7,
                              1.0,
                              curve: Curves.easeIn,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Stack(
                                children: [
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      double progress =
                                          _productsLoaded
                                              ? 1.0
                                              : _controller.value;
                                      return AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        width: constraints.maxWidth * progress,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFD7CCC8),
                                              Colors.white,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _productsLoaded
                                  ? 'Products loaded!'
                                  : 'Loading products...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _textFadeAnimation,
                    child: const Column(
                      children: [
                        Text(
                          '© Ronoch Coffee 2024',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Crafted with ❤️',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class CoffeeBeansPainter extends CustomPainter {
  final Animation<double> animation;

  CoffeeBeansPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 15; i++) {
      final beanX = (size.width / 15) * i;
      final beanY =
          size.height *
          (0.5 + 0.4 * math.sin(animation.value * 2 * math.pi + i * 0.5));

      final beanOpacity = math.min(
        1.0,
        (animation.value - (i * 0.05)).clamp(0.0, 1.0) * 0.1,
      );

      if (beanOpacity > 0) {
        final beanPaint =
            Paint()
              ..color = Colors.white.withOpacity(beanOpacity)
              ..style = PaintingStyle.fill;

        canvas.drawOval(
          Rect.fromCenter(center: Offset(beanX, beanY), width: 30, height: 15),
          beanPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CoffeeBeansPainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}
