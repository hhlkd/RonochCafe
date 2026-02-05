import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:ronoch_coffee/provider/order_provider.dart';
import 'package:ronoch_coffee/screens/auth/forgot_password_screen.dart';
import 'package:ronoch_coffee/screens/auth/register_screen.dart';
import 'package:ronoch_coffee/screens/home_screen.dart';
import 'package:ronoch_coffee/services/user_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Custom colors from Ronoch design
  final Color _mainBrown = const Color(0xFF9E8470);
  final Color _forgotPwdBlue = const Color(0xFF4A90E2);
  final String _mockApiUrl =
      'https://6958c2cc6c3282d9f1d5ba0a.mockapi.io/users';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Full Background Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Ronoch_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Content Layer
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 290),

                  // Title
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _mainBrown,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Phone or Email Input
                  _buildInputLabel('Phone or Email'),
                  _buildTextField(
                    _phoneEmailController,
                    'Enter Phone or Email',
                  ),

                  const SizedBox(height: 20),

                  // Password Input
                  _buildInputLabel('Password'),
                  _buildTextField(
                    _passwordController,
                    'Enter Password',
                    isPassword: true,
                  ),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const ForgotPasswordScreen(),
                            ),
                          ),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: _forgotPwdBlue, fontSize: 15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mainBrown,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Register Redirection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: _mainBrown, fontSize: 15),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Register',
                          style: TextStyle(
                            color: _forgotPwdBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildInputLabel(String label) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 15, bottom: 5),
      child: Text(label, style: TextStyle(color: _mainBrown, fontSize: 16)),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: TextStyle(color: _mainBrown),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _mainBrown.withOpacity(0.5)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 25,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(35),
          borderSide: BorderSide(color: _mainBrown, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(35),
          borderSide: BorderSide(color: _mainBrown, width: 2),
        ),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: _mainBrown,
                  ),
                  onPressed:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                )
                : null,
      ),
    );
  }

  // --- Login Logic ---

  Future<void> _loginUser() async {
    final String input = _phoneEmailController.text.trim();
    final String password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _showError('Please enter your credentials.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(_mockApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);

        // Find user by matching email/phone AND password
        Map<String, dynamic>? foundUser;
        for (var u in users) {
          bool matchesIdentifier =
              (u['phone'].toString() == input ||
                  u['email'].toString().toLowerCase() == input.toLowerCase());
          bool matchesPassword = (u['password'].toString() == password);

          if (matchesIdentifier && matchesPassword) {
            foundUser = u;
            break;
          }
        }

        if (foundUser != null) {
          // Save session using your UserSession service
          // Check for both 'name' and 'username' to prevent crashes
          await UserSession.saveUser(
            foundUser['id'].toString(),
            foundUser['name'] ?? foundUser['username'] ?? 'User',
            foundUser['email'] ?? '',
          );

          // Set userId in OrderProvider
          if (mounted) {
            Provider.of<OrderProvider>(
              context,
              listen: false,
            ).setUserId(foundUser['id'].toString());
          }

          _showSuccess('Welcome back to Ronoch Cafè!');

          // Delay briefly so the success alert is visible
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            }
          });
        } else {
          _showError('Invalid email/phone or password.');
        }
      } else {
        _showError('Server error. Please try again later.');
      }
    } catch (e) {
      _showError('Connection failed. Check your internet.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Ronoch Custom Alerts ---

  void _showRonochAlert({
    required String title,
    required String message,
    required bool isError,
  }) {
    final Color bgColor =
        isError ? const Color(0xFFC72C41) : const Color(0xFF2D6A4F);

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isError ? Icons.close : Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
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

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
  }

  void _showError(String message) {
    _showRonochAlert(title: "Login Failed", message: message, isError: true);
  }

  void _showSuccess(String message) {
    _showRonochAlert(title: "Success!", message: message, isError: false);
  }

  @override
  void dispose() {
    _phoneEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
