import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ronoch_coffee/models/product_model.dart';
import 'package:ronoch_coffee/widgets/product_card.dart';
import 'package:ronoch_coffee/screens/details_screen.dart';
import 'package:ronoch_coffee/provider/cart_provider.dart';
import 'package:ronoch_coffee/provider/product_provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  List<String> _getCategories(List<Product> products) {
    final uniqueCategories = products.map((p) => p.category).toSet().toList();
    return ['All', ...uniqueCategories];
  }

  String _formatCategoryName(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('dessert') || lower.contains('pastri'))
      return 'Pastries';
    if (lower.contains('noodle') && lower.contains('snack'))
      return 'Noodle & Snack';
    if (lower.contains('noodle')) return 'Noodle';
    if (lower.contains('snack')) return 'Snack';

    // Capitalize first letter
    return category.isNotEmpty
        ? '${category[0].toUpperCase()}${category.substring(1)}'
        : category;
  }

  // Group products for display - UPDATED
  Map<String, List<Product>> _groupProducts(List<Product> filtered) {
    final Map<String, List<Product>> groups = {};

    if (_selectedCategory == 'All') {
      // ONLY show featured sections when "All" is selected

      // 1. Popular Drink
      final popDrinks =
          filtered.where((p) => p.section == 'Popular Drink').toList();
      if (popDrinks.isNotEmpty) groups['Popular Drink'] = popDrinks;

      // 2. Popular Pastries
      final popPastries =
          filtered
              .where(
                (p) =>
                    p.section == 'Popular Pastries' ||
                    (p.category.toLowerCase().contains('dessert') &&
                        p.popular == true),
              )
              .toList();
      if (popPastries.isNotEmpty) groups['Popular Pastries'] = popPastries;

      // 3. Promotion Drink
      final promoDrinks =
          filtered
              .where(
                (p) =>
                    p.section == 'Promotion Drink' ||
                    p.promotion == true ||
                    p.discount != null,
              )
              .toList();
      if (promoDrinks.isNotEmpty) groups['Promotion Drink'] = promoDrinks;

      // 4. Remove already displayed items
      final displayedItems = [...popDrinks, ...popPastries, ...promoDrinks];
      final remainingItems =
          filtered.where((p) => !displayedItems.contains(p)).toList();

      // 5. Noodle & Snack section ONLY
      final noodleSnackItems =
          remainingItems
              .where(
                (p) =>
                    p.category.toLowerCase().contains('noodle') ||
                    p.category.toLowerCase().contains('snack'),
              )
              .toList();
      if (noodleSnackItems.isNotEmpty) {
        groups['Noodle & Snack'] = noodleSnackItems;
      }

      // DO NOT show other categories when "All" is selected
      // Tea, Coffee, Pastries will only show when their category is clicked
    } else {
      // Single category selected - show ALL products in that category
      final categoryName = _formatCategoryName(_selectedCategory);
      groups[categoryName] = filtered;
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    final List<Product> allProducts = productProvider.products;
    final bool isLoading = productProvider.isLoading;

    // Filter products based on search and category
    List<Product> filteredProducts = allProducts;

    if (_selectedCategory != 'All') {
      filteredProducts =
          filteredProducts
              .where((p) => p.category == _selectedCategory)
              .toList();
    }

    if (_searchController.text.isNotEmpty) {
      filteredProducts =
          filteredProducts
              .where(
                (p) => p.name.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
              )
              .toList();
    }

    final categories = _getCategories(allProducts);
    final groupedProducts = _groupProducts(filteredProducts);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MENU',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Right side icons (Order History and Cart)
                      Row(
                        children: [
                          // Order History Icon
                          IconButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/history');
                            },
                            icon: const Icon(Icons.history_outlined, size: 28),
                            tooltip: 'Order History',
                          ),
                          // Cart icon with badge
                          Stack(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/cart');
                                },
                                icon: const Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 28,
                                ),
                                tooltip: 'Shopping Cart',
                              ),
                              if (cartProvider.itemCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      cartProvider.itemCount > 9
                                          ? '9+'
                                          : cartProvider.itemCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search for drinks, pastries, etc',
                      prefixIcon: const Icon(Icons.search, color: Colors.brown),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Categories Section
            Container(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Browse by categories',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = _selectedCategory == category;
                        return _buildCategoryItem(category, isSelected);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Products Section
            Expanded(
              child:
                  isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.brown),
                      )
                      : filteredProducts.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.coffee,
                              size: 60,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No products found for "${_searchController.text}"'
                                  : 'No products available',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                      : _selectedCategory == 'All'
                      ? _buildAllProductsView(groupedProducts, context)
                      : _buildCategoryGridView(filteredProducts, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, bool isSelected) {
    // Icon mapping with correct paths
    final iconMap = {
      'all': 'assets/Icons/all-icon.png',
      'coffee': 'assets/Icons/coffe-icon.png',
      'tea': 'assets/Icons/Tea-icon.png',
      'pastries': 'assets/Icons/bread.png',
      'dessert': 'assets/Icons/bread.png',
      'noodle': 'assets/Icons/noodle-icon.png',
      'snack': 'assets/Icons/snack-icon.png',
    };

    final normalizedKey = category.toLowerCase();
    String iconKey = 'all';

    if (normalizedKey.contains('coffee')) {
      iconKey = 'coffee';
    } else if (normalizedKey.contains('tea')) {
      iconKey = 'tea';
    } else if (normalizedKey.contains('pastr') ||
        normalizedKey.contains('dessert')) {
      iconKey = 'pastries';
    } else if (normalizedKey.contains('noodle')) {
      iconKey = 'noodle';
    } else if (normalizedKey.contains('snack')) {
      iconKey = 'snack';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        width: 85,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            Container(
              height: 65,
              width: 65,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFFFFEBD8)
                        : const Color(0xFFFFEBD8).withOpacity(0.5),
                shape: BoxShape.circle,
                border:
                    isSelected
                        ? Border.all(color: Colors.brown, width: 2)
                        : null,
              ),
              child: Center(
                child: Image.asset(
                  iconMap[iconKey] ?? 'assets/Icons/all.png',
                  height: 30,
                  width: 30,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCategoryName(category),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.brown : Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllProductsView(
    Map<String, List<Product>> groupedProducts,
    BuildContext context,
  ) {
    // When "All" is selected, only show featured sections in this order
    const List<String> featuredSectionOrder = [
      'Popular Drink',
      'Popular Pastries',
      'Promotion Drink',
      'Noodle & Snack',
    ];

    final List<Widget> sections = [];

    // Add featured sections in order if they exist
    for (var sectionTitle in featuredSectionOrder) {
      if (groupedProducts.containsKey(sectionTitle) &&
          groupedProducts[sectionTitle]!.isNotEmpty) {
        sections.add(
          _buildProductSection(
            sectionTitle,
            groupedProducts[sectionTitle]!,
            context,
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: sections,
    );
  }

  Widget _buildProductSection(
    String title,
    List<Product> products,
    BuildContext context,
  ) {
    // ALL featured sections use horizontal scroll when "All" is selected
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Horizontal scroll for ALL featured sections
          SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Container(
                  width: 170,
                  margin: const EdgeInsets.only(right: 15),
                  child: ProductCard(
                    product: product,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailsScreen(product: product),
                          ),
                        ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGridView(List<Product> products, BuildContext context) {
    // Check if this is a combined "Noodle & Snack" category
    final isNoodleSnack =
        _selectedCategory.toLowerCase().contains('noodle') &&
        _selectedCategory.toLowerCase().contains('snack');

    // If it's a single category (like Tea, Coffee, Noodle, or Snack), use 2-column grid
    // If it's combined "Noodle & Snack", also use 2-column grid
    final useGrid =
        !isNoodleSnack ||
        (_selectedCategory.toLowerCase().contains('noodle') &&
            _selectedCategory.toLowerCase().contains('snack'));

    if (useGrid) {
      return CustomScrollView(
        slivers: [
          // Category header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
              child: Text(
                _formatCategoryName(_selectedCategory),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          // Product grid (2 columns)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailsScreen(product: product),
                        ),
                      ),
                );
              }, childCount: products.length),
            ),
          ),

          // Add some bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      );
    } else {
      // If for some reason we need horizontal scroll for a specific category
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
            child: Text(
              _formatCategoryName(_selectedCategory),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              children: [
                SizedBox(
                  height: 260,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Container(
                        width: 170,
                        margin: const EdgeInsets.only(right: 15),
                        child: ProductCard(
                          product: product,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => DetailsScreen(product: product),
                                ),
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}
