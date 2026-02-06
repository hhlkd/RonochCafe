import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../provider/user_provider.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isSaving = false;
  bool _isEditing = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocalProfileImage();
  }

  Future<void> _loadLocalProfileImage() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final imagePath = prefs.getString('profile_image_${user.id}');

        if (imagePath != null) {
          final file = File(imagePath);
          if (await file.exists()) {
            setState(() {
              _imageFile = file;
            });
            print('📸 Loaded local profile image for user ${user.id}');
          } else {
            // Remove invalid path from storage
            await prefs.remove('profile_image_${user.id}');
          }
        }
      }
    } catch (e) {
      print('Error loading local image: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final user = userProvider.currentUser;
        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Updating profile...'),
              backgroundColor: Color(0xFF6F4E37),
            ),
          );
          await _saveImageLocally(imageFile, user.id);
          setState(() {
            _imageFile = imageFile;
          });
          final avatarUrl =
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.username)}&background=6F4E37&color=fff&size=200';
          final updatedUser = user.copyWith(profileImage: avatarUrl);
          final success = await userProvider.updateProfile(updatedUser);

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile image updated!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveImageLocally(File imageFile, String userId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${appDir.path}/profile_images');

      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${userId}_$timestamp.jpg';
      final newPath = '${profileDir.path}/$fileName';

      await imageFile.copy(newPath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_$userId', newPath);
      await prefs.setString('profile_image_current_user', userId);

      print('💾 Saved profile image to: $newPath');
    } catch (e) {
      print('Error saving image locally: $e');
    }
  }

  Future<Directory> getApplicationDocumentsDirectory() async {
    return Directory.current;
  }

  void _initializeControllers(User user) {
    _usernameController.text = user.username;
    _emailController.text = user.email;
    _phoneController.text = user.phone;
    _addressController.text = user.address;
  }

  Future<void> _saveProfileChanges() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;

    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // Create updated user object
      final updatedUser = User(
        id: user.id,
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: user.password,
        address: _addressController.text.trim(),
        profileImage: user.profileImage,
        point: user.point,
        createdAt: user.createdAt,
      );

      // Validate inputs
      if (updatedUser.username.isEmpty || updatedUser.email.isEmpty) {
        throw Exception('Username and email are required');
      }

      // Save to API
      final success = await userProvider.updateProfile(updatedUser);

      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.error ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  ImageProvider? _getProfileImage(User? user) {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    }
    if (user != null &&
        user.profileImage.isNotEmpty &&
        user.profileImage.startsWith('http')) {
      return NetworkImage(user.profileImage);
    }

    return null;
  }

  bool _shouldShowDefaultIcon(User user) {
    return _imageFile == null &&
        (user.profileImage.isEmpty ||
            user.profileImage == "https://example.com/profile.jpg" ||
            user.profileImage ==
                "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ5TEZBPnxAX2tEkyDpelKLAWcnau14Iu2Iug&s");
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user != null && !_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_usernameController.text.isEmpty) {
          _initializeControllers(user);
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F4E37),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          if (user != null)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit,
                color: Colors.white,
              ),
              onPressed: () {
                if (_isEditing) {
                  // Cancel editing - reset controllers to original values
                  _initializeControllers(user);
                  setState(() => _isEditing = false);
                } else {
                  // Start editing
                  _initializeControllers(user);
                  setState(() => _isEditing = true);
                }
              },
            ),
        ],
      ),
      body:
          userProvider.isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6F4E37)),
              )
              : user == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_off, size: 80, color: Colors.grey),
                    const SizedBox(height: 20),
                    const Text(
                      'Please log in to view profile',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6F4E37),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 30, top: 20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6F4E37),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Profile Image
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white,
                                  backgroundImage: _getProfileImage(user),
                                  child:
                                      _shouldShowDefaultIcon(user)
                                          ? Text(
                                            user.username
                                                .substring(0, 2)
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF6F4E37),
                                            ),
                                          )
                                          : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF8B7355),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 15),

                          // User Info
                          Text(
                            "Welcome back,",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            user.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Profile Form
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Username field
                          _buildEditableInfoRow(
                            label: "Username",
                            value: user.username,
                            controller: _usernameController,
                            isEditing: _isEditing,
                          ),
                          const SizedBox(height: 20),

                          // Email field
                          _buildEditableInfoRow(
                            label: "Email",
                            value: user.email,
                            controller: _emailController,
                            isEditing: _isEditing,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),

                          // Phone field
                          _buildEditableInfoRow(
                            label: "Phone",
                            value:
                                user.phone.isNotEmpty ? user.phone : "Not set",
                            controller: _phoneController,
                            isEditing: _isEditing,
                            keyboardType: TextInputType.phone,
                            placeholder: "Add phone number",
                          ),
                          const SizedBox(height: 20),

                          // Address field
                          _buildEditableInfoRow(
                            label: "Address",
                            value:
                                user.address.isNotEmpty
                                    ? user.address
                                    : "Not set",
                            controller: _addressController,
                            isEditing: _isEditing,
                            maxLines: 2,
                            placeholder: "Add address",
                          ),

                          const SizedBox(height: 30),

                          // Edit/Save Profile Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isEditing
                                      ? (_isSaving ? null : _saveProfileChanges)
                                      : () {
                                        setState(() => _isEditing = true);
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6F4E37),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  _isSaving
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                      : Text(
                                        _isEditing
                                            ? 'Save Changes'
                                            : 'Edit Profile',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ),

                          // Cancel Button (only when editing)
                          if (_isEditing) ...[
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  _initializeControllers(user);
                                  setState(() => _isEditing = false);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(color: Colors.grey),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildEditableInfoRow({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String placeholder = "",
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF6F4E37),
          ),
        ),
        const SizedBox(height: 8),

        if (!isEditing)
          // Display mode
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          )
        else
          // Edit mode
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6F4E37),
                  width: 2,
                ),
              ),
              hintText: placeholder.isNotEmpty ? placeholder : value,
              hintStyle: TextStyle(
                fontSize: 16,
                color:
                    value == "Not set" || placeholder.isNotEmpty
                        ? Colors.grey.shade500
                        : Colors.black87,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
      ],
    );
  }
}
