import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ronoch_coffee/provider/order_provider.dart';
import 'package:ronoch_coffee/screens/auth/login_screen.dart';
import 'package:ronoch_coffee/screens/home_screen.dart';
import 'package:ronoch_coffee/services/mockapi_service.dart';
import 'package:ronoch_coffee/services/user_session.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _phoneEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final Color _labelColor = const Color(0xFF9E8470);
  final Color _btnColor = const Color(0xFF9E8470);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  Center(child: SizedBox(height: 260, width: 220)),

                  Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: _labelColor,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _buildLabel('Username'),
                  _buildTextField(_usernameController, 'Enter Username'),

                  const SizedBox(height: 20),

                  _buildLabel('Phone or Email'),
                  _buildTextField(
                    _phoneEmailController,
                    'Enter Phone or Email',
                  ),

                  const SizedBox(height: 20),

                  _buildLabel('Password'),
                  _buildTextField(
                    _passwordController,
                    'Enter Password',
                    isPassword: true,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _btnColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: _labelColor, fontSize: 15),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.blue,
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

  Widget _buildLabel(String text) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 15, bottom: 5),
      child: Text(text, style: TextStyle(color: _labelColor, fontSize: 16)),
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
      style: TextStyle(color: _labelColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _labelColor.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: _labelColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: _labelColor, width: 2),
        ),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: _labelColor,
                  ),
                  onPressed:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                )
                : null,
      ),
    );
  }

  // ================ LOGIC METHODS ================

  Future<void> _registerUser() async {
    if (_usernameController.text.isEmpty ||
        _phoneEmailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if input is email or phone
      final contact = _phoneEmailController.text.trim();
      final isEmail = contact.contains('@');

      // Call your MockApiService.register() method
      final user = await MockApiService.register(
        _usernameController.text.trim(), // username
        isEmail ? contact : '', // email (if email)
        isEmail ? '' : contact, // phone (if phone)
        _passwordController.text, // password
        '', // address (empty for now)
      );

      // Save user to session
      await UserSession.saveUser(user.id, user.username, user.email);

      // Set userId in OrderProvider
      if (mounted) {
        Provider.of<OrderProvider>(context, listen: false).setUserId(user.id);
      }

      _showSuccess('✅ Registration successful!');

      // Navigate to home after delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      });
    } catch (e) {
      print('Registration error: $e');
      _showError('Registration failed: $e');

      // Fallback to local registration
      final localUserId = DateTime.now().millisecondsSinceEpoch.toString();
      await UserSession.saveUser(
        localUserId,
        _usernameController.text.trim(),
        '',
      );

      if (mounted) {
        Provider.of<OrderProvider>(
          context,
          listen: false,
        ).setUserId(localUserId);
      }

      _showSuccess('✅ Registered locally!');

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
