import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ronoch_coffee/provider/order_provider.dart';
import 'package:ronoch_coffee/provider/product_provider.dart';
import 'package:ronoch_coffee/provider/reward_provider.dart';
import 'package:ronoch_coffee/provider/user_provider.dart';
import 'package:ronoch_coffee/screens/Checkout_screen.dart';
import 'package:ronoch_coffee/screens/auth/login_screen.dart';
import 'package:ronoch_coffee/screens/auth/splash_screen.dart';
import 'package:ronoch_coffee/provider/cart_provider.dart';
import 'package:ronoch_coffee/screens/cart_screen.dart';
import 'package:ronoch_coffee/screens/history_screen.dart';
import 'package:ronoch_coffee/screens/menu_screen.dart';
import 'package:ronoch_coffee/screens/profile_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => RewardProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ronoch Coffee',
      theme: ThemeData(
        primaryColor: const Color(0xFF6F4E37),
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      home: SplashScreen(),
      routes: {
        '/cart': (context) => const CartScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/history': (context) => const HistoryScreen(),
        '/login':
            (context) => const LoginScreen(), // Placeholder for Login Screen
        '/profile':
            (context) =>
                const ProfileScreen(), // Placeholder for Profile Screen
        '/menu': (context) => const MenuScreen(),
      },
    );
  }
}
