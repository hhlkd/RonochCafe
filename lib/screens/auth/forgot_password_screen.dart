import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ronoch_coffee/screens/auth/OTP_screen.dart';
import 'dart:convert';
import 'dart:math'; // Added for OTP generation

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _phoneEmailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  final Color _mainBrown = const Color(0xFF9E8470);
  final Color _linkBlue = const Color(0xFF4A90E2);
  final String _mockApiUrl =
      'https://6958c2cc6c3282d9f1d5ba0a.mockapi.io/users';

  // --- Logical Methods ---

  Future<Map<String, dynamic>?> _findUserByPhoneOrEmail(
    String identifier,
  ) async {
    try {
      final response = await http.get(Uri.parse(_mockApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> users = jsonDecode(response.body);
        final String searchKey = identifier.trim().toLowerCase();

        for (final user in users) {
          final String email = (user['email'] ?? '').toString().toLowerCase();
          final String phone = (user['phone'] ?? '').toString().toLowerCase();
          final String name = (user['name'] ?? '').toString().toLowerCase();
          final String username =
              (user['username'] ?? '').toString().toLowerCase();

          if (email == searchKey ||
              phone == searchKey ||
              name == searchKey ||
              username == searchKey) {
            return user;
          }
        }
      }
    } catch (e) {
      debugPrint("Search Error: $e");
    }
    return null;
  }

  Future<void> _handleContinue() async {
    // 1. Validation
    if (_phoneEmailController.text.isEmpty ||
        _newPasswordController.text.isEmpty) {
      _showRonochAlert('Please fill in all fields', true);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showRonochAlert('Passwords do not match', true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Check if user exists
      final user = await _findUserByPhoneOrEmail(_phoneEmailController.text);

      if (user == null) {
        _showRonochAlert('User not found in our system', true);
      } else {
        // 3. GENERATE OTP (Simulating a real system)
        String generatedOtp = (Random().nextInt(900000) + 100000).toString();

        // In a real app, you'd call an SMS/Email API here.
        // For now, we print it to the console so you can test.
        debugPrint("DEBUG: Sent OTP $generatedOtp to ${user['name']}");

        _showRonochAlert('Verification code sent!', false);

        // 4. Navigate to OTP Screen with Data
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => OtpVerificationScreen(
                      correctOtp: generatedOtp,
                      userId: user['id'].toString(),
                      newPassword: _newPasswordController.text,
                    ),
              ),
            );
          }
        });
      }
    } catch (e) {
      _showRonochAlert('Connection error', true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Better Custom Notification (Top Overlay) ---
  void _showRonochAlert(String message, bool isError) {
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
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color:
                      isError
                          ? const Color(0xFFC72C41)
                          : const Color(0xFF2D6A4F),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                children: [
                  const SizedBox(height: 250),
                  Text(
                    'Forgot Password',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _mainBrown,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildInputLabel('Phone or Email'),
                  _buildTextField(
                    controller: _phoneEmailController,
                    hintText: 'Enter Phone or Email',
                    prefixIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),
                  _buildInputLabel('New Password'),
                  _buildTextField(
                    controller: _newPasswordController,
                    hintText: 'Enter New Password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    obscureText: _obscureNewPassword,
                    onToggle:
                        () => setState(
                          () => _obscureNewPassword = !_obscureNewPassword,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _buildInputLabel('Confirm Password'),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm New Password',
                    prefixIcon: Icons.lock_reset_outlined,
                    isPassword: true,
                    obscureText: _obscureConfirmPassword,
                    onToggle:
                        () => setState(
                          () =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                        ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _mainBrown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Remember password? ",
                        style: TextStyle(color: _mainBrown),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: _linkBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: _mainBrown),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: _mainBrown),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: _mainBrown,
                  ),
                  onPressed: onToggle,
                )
                : null,
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
      ),
    );
  }

  @override
  void dispose() {
    _phoneEmailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
