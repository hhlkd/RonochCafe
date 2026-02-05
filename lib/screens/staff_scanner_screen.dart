import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ronoch_coffee/models/redemption_record_model.dart';
import 'package:intl/intl.dart';

class StaffScannerScreen extends StatefulWidget {
  const StaffScannerScreen({super.key});

  @override
  State<StaffScannerScreen> createState() => _StaffScannerScreenState();
}

class _StaffScannerScreenState extends State<StaffScannerScreen> {
  MobileScannerController? controller;
  bool _isProcessing = false;
  List<RedemptionRecord> _allRedemptions = [];
  bool _showScanner = true;
  final TextEditingController _manualCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _determineDeviceAndInit();
  }

  Future<void> _determineDeviceAndInit() async {
    bool physical = true;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        physical = info.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        physical = info.isPhysicalDevice;
      }
    } catch (e) {
      physical = true;
    }

    controller = MobileScannerController();
    await _loadAllRedemptions();
    if (physical) {
      await _requestCameraPermission();
    }

    if (mounted) {
      setState(() {
        _showScanner = physical;
      });
    }
  }

  Future<void> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      if (status.isDenied) {
        if (mounted) {
          _showDialog(
            'Camera Permission Denied',
            'Please enable camera permission in app settings to use the scanner.',
            Colors.red,
            onClose: () => Navigator.pop(context),
          );
        }
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          _showDialog(
            'Camera Permission Required',
            'Camera permission is permanently denied. Please enable it in app settings.',
            Colors.red,
            onClose: () => openAppSettings(),
          );
        }
      }
    } catch (e) {
      print('Error requesting camera permission: $e');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAllRedemptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      final List<RedemptionRecord> allRedemptions = [];

      for (String key in keys) {
        if (key.startsWith('user_redemptions_')) {
          final redemptionData = prefs.getStringList(key) ?? [];
          for (var json in redemptionData) {
            final record = RedemptionRecord.fromJson(jsonDecode(json));
            allRedemptions.add(record);
          }
        }
      }

      setState(() {
        _allRedemptions = allRedemptions;
      });
    } catch (e) {
      print('Error loading redemptions: $e');
    }
  }

  Future<void> _handleScannedCode(String code) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Find matching redemption by code
      final matching = _allRedemptions.firstWhere(
        (r) => r.redemptionCode == code.trim(),
      );

      if (matching.isUsed) {
        _showDialog(
          'Already Collected',
          'This reward was already collected on ${DateFormat('MMM dd, yyyy HH:mm').format(matching.collectedAt ?? DateTime.now())}',
          Colors.orange,
        );
      } else if (matching.isExpired) {
        _showDialog(
          'Reward Expired',
          'This reward expired on ${DateFormat('MMM dd, yyyy').format(matching.validUntil)}',
          Colors.red,
        );
      } else {
        // Show confirmation dialog
        _showConfirmCollectionDialog(matching);
      }
    } catch (e) {
      _showDialog(
        'Invalid Code',
        'This redemption code was not found. Please try again.',
        Colors.red,
      );
    }

    setState(() => _isProcessing = false);
  }

  void _showConfirmCollectionDialog(RedemptionRecord redemption) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Confirm Collection',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D2D2D),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reward Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        redemption.rewardName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${redemption.pointsUsed} points',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Code: ${redemption.redemptionCode}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Redeemed: ${DateFormat('MMM dd, yyyy').format(redemption.redeemedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Confirm that the customer has collected this reward?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmCollection(redemption);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Confirm Collected'),
              ),
            ],
          ),
    );
  }

  Future<void> _confirmCollection(RedemptionRecord redemption) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Find and update the redemption in local storage
      for (String key in prefs.getKeys()) {
        if (key.startsWith('user_redemptions_')) {
          final redemptionData = prefs.getStringList(key) ?? [];
          final updatedData = <String>[];

          for (var json in redemptionData) {
            final record = RedemptionRecord.fromJson(jsonDecode(json));

            if (record.id == redemption.id) {
              // Update status to collected
              final updated = record.copyWith(
                status: 'used',
                collectedAt: DateTime.now(),
                collectedBy: 'Staff',
              );
              updatedData.add(jsonEncode(updated.toJson()));
            } else {
              updatedData.add(json);
            }
          }

          if (updatedData.length != redemptionData.length ||
              redemptionData.any(
                (json) =>
                    RedemptionRecord.fromJson(jsonDecode(json)).id ==
                    redemption.id,
              )) {
            await prefs.setStringList(key, updatedData);
          }
        }
      }

      // Reload and show success
      await _loadAllRedemptions();

      _showDialog(
        'Collection Confirmed',
        '${redemption.rewardName} has been marked as collected.',
        Colors.green,
        onClose: () {
          // Reset scanner
          controller?.start();
        },
      );
    } catch (e) {
      _showDialog(
        'Error',
        'Failed to confirm collection: ${e.toString()}',
        Colors.red,
      );
    }
  }

  void _showDialog(
    String title,
    String message,
    Color color, {
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  color == Colors.green
                      ? Icons.check_circle
                      : color == Colors.orange
                      ? Icons.info
                      : Icons.error,
                  color: color,
                ),
                const SizedBox(width: 10),
                Text(title),
              ],
            ),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onClose?.call();
                },
                style: ElevatedButton.styleFrom(backgroundColor: color),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan Redemption',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Camera Scanner (only shown on physical devices)
          if (_showScanner)
            MobileScanner(
              controller: controller,
              onDetect: (capture) {
                for (var barcode in capture.barcodes) {
                  if (barcode.rawValue != null && !_isProcessing) {
                    controller?.stop();
                    _handleScannedCode(barcode.rawValue!);
                  }
                }
              },
              errorBuilder: (context, error, child) {
                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Camera Error',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Text(
                                error.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Troubleshooting:\n• Check camera permissions\n• Restart the app\n• Restart your device',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await openAppSettings();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB08968),
                              ),
                              child: const Text('Open Settings'),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                              child: const Text('Go Back'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            // Manual code entry fallback for emulators / when scanner unavailable
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.smartphone, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Scanner unavailable on this device',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter redemption code manually to confirm collection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _manualCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelText: 'Redemption Code',
                        hintText: 'ENTER CODE',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isProcessing
                                ? null
                                : () {
                                  final code =
                                      _manualCodeController.text.trim();
                                  if (code.isEmpty) {
                                    _showDialog(
                                      'Empty Code',
                                      'Please enter a redemption code.',
                                      Colors.red,
                                    );
                                    return;
                                  }
                                  _handleScannedCode(code);
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB08968),
                        ),
                        child: const Text('Confirm Code'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Overlay UI
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.qr_code_2,
                    size: 48,
                    color: Color(0xFFB08968),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ready to Scan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Position the QR code in the camera frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        controller?.toggleTorch();
                      },
                      icon: const Icon(Icons.flashlight_on),
                      label: const Text('Toggle Flashlight'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB08968),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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
