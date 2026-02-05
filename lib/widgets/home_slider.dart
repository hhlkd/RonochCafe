import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/image_model.dart';

class HomeSlider extends StatefulWidget {
  final List<AppImage> images;
  final double height;

  const HomeSlider({super.key, required this.images, this.height = 280});

  @override
  State<HomeSlider> createState() => _HomeSliderState();
}

class _HomeSliderState extends State<HomeSlider> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // CRITICAL: Set viewportFraction to exactly 1.0
    _pageController = PageController(initialPage: 0, viewportFraction: 1.0);

    if (widget.images.isNotEmpty) {
      _startAutoSlider();
    }
  }

  void _startAutoSlider() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _pageController.hasClients) {
        _currentPage = (_currentPage + 1) % widget.images.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        SizedBox(
          height: widget.height,
          // Use MediaQuery to ensure the width is the physical screen width
          width: MediaQuery.of(context).size.width,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: widget.images[index].imageUrl,
                // BoxFit.cover makes the image fill the entire container
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width,
                placeholder:
                    (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              );
            },
          ),
        ),

        // Custom Indicators (Matching image_f46ad8.png)
        Positioned(
          bottom: 15,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (index) => Container(
                width:
                    _currentPage == index
                        ? 18
                        : 8, // Active indicator is a pill shape
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color:
                      _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
