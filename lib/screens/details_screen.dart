import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../provider/cart_provider.dart';

class DetailsScreen extends StatefulWidget {
  final Product product;

  const DetailsScreen({super.key, required this.product});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  // Selection states
  String _selectedSize = 'M';
  String _selectedSugar = '0%';
  String _selectedIce = '0%';
  int _quantity = 1;
  bool _isFavorite = false;

  final Map<String, double> _sizePrices = {
    'S': 1.99,
    'M': 2.50,
    'L': 3.50,
    'XL': 4.50,
  };

  bool get _isDrink {
    final category = widget.product.category.toLowerCase();
    return category.contains('coffee') ||
        category.contains('tea') ||
        category.contains('drink');
  }

  double get _currentPrice =>
      _isDrink
          ? (_sizePrices[_selectedSize] ?? widget.product.price)
          : widget.product.price;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopHeader(),
                  _buildProductInfo(),
                  if (_isDrink) _buildDrinkCustomization(),
                  if (!_isDrink) _buildFoodDescription(),
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  // --- NEW IMPROVED HEADER ---
  Widget _buildTopHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFA68A73),
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(100)),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _headerCircleButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                _headerCircleButton(
                  icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                  iconColor: _isFavorite ? Colors.red : Colors.black,
                  onTap: () => setState(() => _isFavorite = !_isFavorite),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: Center(
            child: Hero(
              tag: 'product-${widget.product.imageUrl}',
              child: CachedNetworkImage(
                imageUrl: widget.product.imageUrl,
                height: 250,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        width: 45,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  // --- PRODUCT INFO (NAME, RATINGS, TIME) ---
  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 30, 25, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!_isDrink)
                Text(
                  "\$${widget.product.price}",
                  style: const TextStyle(
                    fontSize: 24,
                    color: Color(0xFFA68A73),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              const Text("4.8", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 15),
              const Icon(Icons.timer_outlined, color: Colors.grey, size: 20),
              const SizedBox(width: 4),
              const Text("5-10 min", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // --- DRINK CUSTOMIZATION LAYOUT ---
  Widget _buildDrinkCustomization() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Cup Size"),
          _buildOptionRow('size'),
          const SizedBox(height: 25),
          _buildSectionTitle("Sugar Level"),
          _buildOptionRow('sugar'),
          const SizedBox(height: 25),
          _buildSectionTitle("Ice Level"),
          _buildOptionRow('ice'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- FOOD DESCRIPTION LAYOUT ---
  Widget _buildFoodDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Description",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Our ${widget.product.name} is prepared fresh daily with premium ingredients to ensure the best taste and quality for your meal.",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- SHARED UI LOGIC ---
  Widget _buildOptionRow(String type) {
    List<Map<String, String>> options = [];
    String currentSelection = '';
    String assetName = '';

    if (type == 'size') {
      options = [
        {'label': 'S', 'sub': '\$1.99'},
        {'label': 'M', 'sub': '\$2.50'},
        {'label': 'L', 'sub': '\$3.50'},
        {'label': 'XL', 'sub': '\$4.50'},
      ];
      currentSelection = _selectedSize;
      assetName = 'size-icon.png';
    } else if (type == 'sugar') {
      options = [
        {'label': '0%'},
        {'label': '50%'},
        {'label': '100%'},
        {'label': '125%'},
      ];
      currentSelection = _selectedSugar;
      assetName = 'surga-icon.png';
    } else {
      options = [
        {'label': '0%'},
        {'label': '50%'},
        {'label': '100%'},
        {'label': '125%'},
      ];
      currentSelection = _selectedIce;
      assetName = 'ice-icon.png';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:
            options.map((opt) {
              bool isSelected = currentSelection == opt['label'];
              return GestureDetector(
                onTap:
                    () => setState(() {
                      if (type == 'size') _selectedSize = opt['label']!;
                      if (type == 'sugar') _selectedSugar = opt['label']!;
                      if (type == 'ice') _selectedIce = opt['label']!;
                    }),
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xFFA68A73)
                                : const Color(0xFFFFEBD8),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/Icons/$assetName',
                          width: 28,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      opt['label']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Subtotal", style: TextStyle(color: Colors.grey)),
                  Text(
                    '\$${(_currentPrice * _quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _quantityButton(Icons.remove, () {
                    if (_quantity > 1) setState(() => _quantity--);
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      "$_quantity",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _quantityButton(Icons.add, () => setState(() => _quantity++)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () async {
                final cartProvider = Provider.of<CartProvider>(
                  context,
                  listen: false,
                );
                await cartProvider.addToCart(
                  widget.product.id,
                  widget.product.name,
                  _currentPrice,
                  widget.product.imageUrl,
                  quantity: _quantity,
                  size: _isDrink ? _selectedSize : '',
                  sugarLevel: _isDrink ? _selectedSugar : '',
                  iceLevel: _isDrink ? _selectedIce : '',
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFFA68A73),
                    content: Text("${widget.product.name} added to cart!"),
                    action: SnackBarAction(
                      label: "VIEW CART",
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.pushNamed(context, '/cart');
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA68A73),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Add to Cart",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.black, size: 28),
    );
  }
}
