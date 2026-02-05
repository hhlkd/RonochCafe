import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ronoch_coffee/services/mockapi_service.dart';
import 'package:ronoch_coffee/services/user_session.dart';
import '../models/address_model.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _latLong = "No location selected";
  bool _isLoading = false;
  Position? _selectedPosition;
  Placemark? _selectedPlacemark;
  String? _selectedAddress;

  Future<void> _pickLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError("Location services are disabled. Please enable GPS.");
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError("Location permission denied.");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showError(
        "Location permissions are permanently denied. Enable in settings.",
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _getAddressFromCoordinates(position);
      await _showMapOptions(position);
    } catch (e) {
      _showError("Error getting location: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        setState(() {
          _selectedPosition = position;
          _selectedPlacemark = placemark;
          _latLong =
              "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
          _selectedAddress = _buildAddressString(placemark);
          _addressController.text = _selectedAddress!;
        });
      } else {
        setState(() {
          _selectedPosition = position;
          _latLong =
              "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
          _addressController.text = "Location at coordinates: $_latLong";
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _selectedPosition = position;
        _latLong =
            "${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
        _addressController.text = "Location at coordinates: $_latLong";
      });
    }
  }

  String _buildAddressString(Placemark placemark) {
    List<String> addressParts = [];
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      addressParts.add(placemark.street!);
    }
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      addressParts.add(placemark.subLocality!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      addressParts.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null &&
        placemark.administrativeArea!.isNotEmpty) {
      addressParts.add(placemark.administrativeArea!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      addressParts.add(placemark.country!);
    }

    return addressParts.join(', ');
  }

  Future<void> _showMapOptions(Position position) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Select Map Option",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.map, color: Colors.blue),
                  title: const Text("Open in Google Maps (if installed)"),
                  subtitle: const Text("Will open in Google Maps app"),
                  onTap: () => Navigator.pop(context, 'google_maps'),
                ),
                ListTile(
                  leading: const Icon(Icons.map, color: Colors.green),
                  title: const Text("Open in Google Maps Web"),
                  subtitle: const Text("Will open in browser"),
                  onTap: () => Navigator.pop(context, 'google_maps_web'),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.orange),
                  title: const Text("Just use current location"),
                  subtitle: const Text("Don't open any map"),
                  onTap: () => Navigator.pop(context, 'current'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ),
    );

    if (result == 'google_maps') {
      await _openGoogleMapsApp(position);
    } else if (result == 'google_maps_web') {
      await _openGoogleMapsWeb(position);
    }
  }

  Future<void> _openGoogleMapsApp(Position position) async {
    String url =
        "geo:${position.latitude},${position.longitude}?q=${position.latitude},${position.longitude}";
    String googleMapsUrl =
        "comgooglemaps://?q=${position.latitude},${position.longitude}";
    String googleMapsSearch =
        "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        return;
      }
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl));
        return;
      }
      if (await canLaunchUrl(Uri.parse(googleMapsSearch))) {
        await launchUrl(
          Uri.parse(googleMapsSearch),
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      _showError(
        "Cannot open Google Maps. Please install the app or use a different method.",
      );
    } catch (e) {
      print('Error opening Google Maps: $e');
      _showError("Error opening Google Maps: $e");
    }
  }

  Future<void> _openGoogleMapsWeb(Position position) async {
    String url =
        "https://www.google.com/maps?q=${position.latitude},${position.longitude}";
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showError("Cannot open browser. Please check your device settings.");
      }
    } catch (e) {
      print('Error opening web maps: $e');
      _showError("Error opening maps in browser: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _save() async {
    if (_addressController.text.isEmpty) {
      _showError("Please enter your address first");
      return;
    }

    if (_phoneController.text.isEmpty) {
      _showError("Please enter your phone number");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = await UserSession.getUser();
      final userId = userData['userId'] ?? "1";
      String fullAddress = _addressController.text.trim();
      String city = 'Phnom Penh';
      String district = '';
      String street = '';

      if (_selectedPlacemark != null) {
        city = _selectedPlacemark!.locality ?? 'Phnom Penh';
        district = _selectedPlacemark!.subLocality ?? '';
        street = _selectedPlacemark!.street ?? '';
      }
      final newAddress = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        label: 'Home',
        city: city,
        district: district,
        street: street,
        fullAddress: fullAddress,
        phoneNumber: _phoneController.text.trim(),
        remarks:
            _remarkController.text.trim().isNotEmpty
                ? _remarkController.text.trim()
                : null,
        isDefault: true,
      );
      await MockApiService.saveUserAddress(newAddress);

      Map<String, dynamic> result = {
        'address': fullAddress,
        'phone': _phoneController.text.trim(),
        'addressObject': newAddress,
      };

      if (_selectedPosition != null) {
        result['latitude'] = _selectedPosition!.latitude;
        result['longitude'] = _selectedPosition!.longitude;
        result['coordinates'] = _latLong;
      }

      Navigator.pop(context, result);
    } catch (e) {
      _showError('Failed to save address: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Choose Location",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add Delivery Address",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Add your delivery location for order",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Location Picker Card
            GestureDetector(
              onTap: _pickLocation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    if (_isLoading)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFA68A73),
                        ),
                      )
                    else
                      Icon(
                        Icons.location_on,
                        size: 50,
                        color:
                            _latLong == "No location selected"
                                ? Colors.grey
                                : const Color(0xFFA68A73),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      _latLong == "No location selected"
                          ? "Tap to select location"
                          : "Location Selected",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            _latLong == "No location selected"
                                ? Colors.grey
                                : const Color(0xFFA68A73),
                      ),
                    ),
                    if (_latLong != "No location selected") ...[
                      const SizedBox(height: 10),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            if (_selectedAddress != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.green),
                        SizedBox(width: 5),
                        Text(
                          "Selected Address:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAddress!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _latLong,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Address Field
            _buildField(
              "Full Address",
              _addressController,
              "Enter your complete address",
              lines: 2,
              icon: Icons.home,
            ),

            const SizedBox(height: 20),

            // Phone Field
            _buildField(
              "Phone Number",
              _phoneController,
              "Enter phone number for delivery",
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 20),

            // Instructions Field
            _buildField(
              "Delivery Instructions",
              _remarkController,
              "e.g. Floor 2, Ring bell, Call before arriving...",
              lines: 3,
              icon: Icons.note,
            ),

            const SizedBox(height: 30),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA68A73),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          "Save Address",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    int lines = 1,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: lines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFA68A73),
                width: 1.5,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: lines > 1 ? 12 : 0,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _remarkController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
