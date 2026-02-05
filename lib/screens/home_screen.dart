import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ronoch_coffee/screens/account_screen.dart';
import 'package:ronoch_coffee/screens/history_screen.dart';
import 'package:ronoch_coffee/screens/menu_screen.dart';
import '../services/mockapi_service.dart';
import '../services/user_session.dart';
import '../models/announcement_model.dart';
import '../models/image_model.dart';
import '../widgets/home_slider.dart';
import '../routes/animated_bottom_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AppImage> _sliderImages = [];
  AppImage? _pickupImage;
  AppImage? _deliveryImage;
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String _userName = '';
  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userData = await UserSession.getUser();
      _userName = userData['username'] ?? 'Guest';
      final allImages = await MockApiService.getImages();
      setState(() {
        _sliderImages = allImages.where((img) => img.type == 'slider').toList();
        _pickupImage = allImages.firstWhere(
          (img) => img.type == 'home_icon',
          orElse: () => _getFallbackPickup(),
        );
        _deliveryImage = allImages.firstWhere(
          (img) => img.type == 'delivery_icon',
          orElse: () => _getFallbackDelivery(),
        );
      });
      _announcements = await MockApiService.getActiveAnnouncements();
    } catch (e) {
      debugPrint('Error loading home data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadHomeData,
      color: const Color(0xFF6F4E37),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_sliderImages.isNotEmpty)
              HomeSlider(images: _sliderImages)
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6F4E37), Color(0xFF8B7355)],
                  ),
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.coffee, color: Colors.white, size: 50),
                      const SizedBox(height: 10),
                      const Text(
                        'RONOCH COFFEE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Greetings! $_userName',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Greetings! $_userName',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,

                  color: Color(0xFF6F4E37),
                ),
              ),
            ),

            const SizedBox(height: 5),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "LET'S ENJOY MOMENT WITH COFFEE & MATCHA ",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Service Icons (Pick Up & Delivery circular style)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_pickupImage != null)
                  _buildServiceIcon(_pickupImage!, "Pick Up"),
                if (_deliveryImage != null)
                  _buildServiceIcon(_deliveryImage!, "Delivery"),
              ],
            ),

            const SizedBox(height: 25),

            // 4. Announcements Section Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Announcements",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6F4E37),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Vertical list of announcements as per your UI design
            if (_announcements.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _announcements.length,
                itemBuilder:
                    (context, index) =>
                        _buildAnnouncementItem(_announcements[index]),
              )
            else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.announcement, color: Colors.grey, size: 40),
                    SizedBox(height: 10),
                    Text(
                      'No announcements available',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Footer Banner matching your design
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6F4E37), Color(0xFF8B7355)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'BEST COFFEE EVER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Experience the perfect cup of coffee crafted with passion and precision.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to order screen
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6F4E37),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'ORDER NOW',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Build all screens for IndexedStack
  List<Widget> _buildAllScreens() {
    return [
      _buildHomeContent(),
      const MenuScreen(), // Index 1: Menu
      const HistoryScreen(), // Index 2: Order/Cart
      const AccountScreen(), // Index 3: Profile
      // call other screens here
    ];
  }

  Widget _buildServiceIcon(AppImage img, String label) {
    return GestureDetector(
      onTap: () {
        print('$label tapped');
        if (label == 'Pick Up') {
          //go to pick up menu screen
          setState(() {
            _selectedIndex = 1;
          });
        } else {
          // Handle delivery
        }
      },
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4D6), // Light peach background from UI
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: CachedNetworkImage(
                imageUrl: img.imageUrl,
                width: 50,
                height: 50,
                placeholder:
                    (context, url) => const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF6F4E37),
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Icon(
                      label == 'Pick Up' ? Icons.store : Icons.delivery_dining,
                      size: 40,
                      color: const Color(0xFF6F4E37),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF6F4E37),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementItem(Announcement item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image with discount badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                  placeholder:
                      (context, url) => Container(
                        height: 180,
                        color: const Color(0xFF6F4E37),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        height: 180,
                        color: const Color(0xFF6F4E37),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.announcement,
                                color: Colors.white,
                                size: 40,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Announcement',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
              ),
              // Discount badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '20% OFF',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF6F4E37),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Valid until date
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Color(0xFF6F4E37),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Valid until ${item.validUntil.split('T')[0]}',
                      style: const TextStyle(
                        color: Color(0xFF6F4E37),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6F4E37),
                  strokeWidth: 3,
                ),
              )
              : IndexedStack(
                index: _selectedIndex,
                children: _buildAllScreens(),
              ),
      bottomNavigationBar: AnimatedBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  // Fallbacks
  AppImage _getFallbackPickup() => AppImage(
    id: '6',
    name: 'Pick Up',
    imageUrl:
        'https://res.cloudinary.com/dlfbpzhic/image/upload/v1767776618/pickup_icon_ykckuj.png',
    type: 'home_icon',
    category: '',
  );
  AppImage _getFallbackDelivery() => AppImage(
    id: '7',
    name: 'Delivery',
    imageUrl:
        'https://res.cloudinary.com/dlfbpzhic/image/upload/v1767776618/delivery_icon_vcrrwk.png',
    type: 'delivery_icon',
    category: '',
  );
}
