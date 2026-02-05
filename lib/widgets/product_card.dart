import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ronoch_coffee/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardHeight = constraints.maxHeight;
        final double cardWidth = constraints.maxWidth;
        const Color themeColor = Color(0xFF9B7E66);

        final bool hasDiscount =
            product.discount != null && product.discount! > 0;
        final double? discountedPrice =
            hasDiscount
                ? product.price - (product.price * product.discount! / 100)
                : null;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    size: Size(cardWidth, cardHeight * 0.48),
                    painter: CurvePainter(color: themeColor),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: cardHeight * 0.02,
                    right: cardWidth * 0.02,
                    child: Transform.rotate(
                      angle: 0.1, // Slight tilt for visual interest
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardWidth * 0.04,
                          vertical: cardHeight * 0.012,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '${product.discount!.toStringAsFixed(0)}% OFF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: cardHeight * 0.04,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: cardHeight * 0.1,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Hero(
                      tag: 'product-${product.imageUrl}',
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        height: cardHeight * 0.45,
                        fit: BoxFit.contain,
                        placeholder:
                            (context, url) => const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => const Icon(
                              Icons.coffee,
                              color: Colors.white,
                              size: 40,
                            ),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    SizedBox(height: cardHeight * 0.55),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          cardWidth * 0.08,
                          0,
                          cardWidth * 0.08,
                          cardHeight * 0.05,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: cardHeight * 0.07,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.favorite_border,
                                  color: themeColor,
                                  size: cardHeight * 0.09,
                                ),
                              ],
                            ),
                            Text(
                              product.description,
                              style: TextStyle(
                                fontSize: cardHeight * 0.05,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasDiscount)
                                  Row(
                                    children: [
                                      Text(
                                        'WAS ',
                                        style: TextStyle(
                                          fontSize: cardHeight * 0.035,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '\$${product.price.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: cardHeight * 0.035,
                                          color: Colors.grey[500],
                                          decoration:
                                              TextDecoration.lineThrough,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),

                                SizedBox(height: cardHeight * 0.005),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              '\$',
                                              style: TextStyle(
                                                fontSize: cardHeight * 0.055,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    hasDiscount
                                                        ? const Color(
                                                          0xFFE63946,
                                                        )
                                                        : Colors.black,
                                              ),
                                            ),
                                            SizedBox(width: cardWidth * 0.005),
                                            Text(
                                              hasDiscount
                                                  ? discountedPrice!
                                                      .toStringAsFixed(2)
                                                  : product.price
                                                      .toStringAsFixed(2),
                                              style: TextStyle(
                                                fontSize: cardHeight * 0.075,
                                                fontWeight: FontWeight.w800,
                                                color:
                                                    hasDiscount
                                                        ? const Color(
                                                          0xFFE63946,
                                                        )
                                                        : Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (hasDiscount)
                                          Container(
                                            margin: EdgeInsets.only(
                                              top: cardHeight * 0.005,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: cardWidth * 0.03,
                                              vertical: cardHeight * 0.005,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF4CAF50,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'You save \$${(product.price - discountedPrice!).toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: cardHeight * 0.032,
                                                color: const Color(0xFF4CAF50),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: themeColor,
                                        borderRadius: BorderRadius.circular(15),
                                        gradient: LinearGradient(
                                          colors: [
                                            themeColor,
                                            Color.lerp(
                                              themeColor,
                                              Colors.brown,
                                              0.3,
                                            )!,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_shopping_cart,
                                            color: Colors.white,
                                            size: cardHeight * 0.05,
                                          ),
                                          SizedBox(width: cardWidth * 0.02),
                                          Text(
                                            'Add',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: cardHeight * 0.045,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CurvePainter extends CustomPainter {
  final Color color;
  CurvePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = color;
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.75);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width * 0.7,
      size.height,
    );
    path.lineTo(0, size.height);
    path.close();
    canvas.clipRRect(
      RRect.fromLTRBAndCorners(
        0,
        0,
        size.width,
        size.height,
        topLeft: const Radius.circular(25),
        topRight: const Radius.circular(25),
      ),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
