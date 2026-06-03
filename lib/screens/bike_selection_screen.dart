// lib/screens/bike_selection_screen.dart

import 'dart:ui';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/bike_model.dart';
import '../providers/bike_provider.dart';
import '../widgets/bike_carousel_item.dart';
import '../widgets/industrial_background.dart';

class BikeSelectionScreen extends StatefulWidget {
  const BikeSelectionScreen({super.key});

  @override
  State<BikeSelectionScreen> createState() => _BikeSelectionScreenState();
}

class _BikeSelectionScreenState extends State<BikeSelectionScreen>
    with SingleTickerProviderStateMixin {
  late CarouselSliderController _pageController;
  int _currentIndex = 0;
  bool _isSelecting = false;
  late AnimationController _buttonAnimController;
  late Animation<double> _buttonScaleAnim;

  final List<BikeModel> _bikes = BikeModel.availableBikes;

  @override
  void initState() {
    super.initState();
    _pageController = CarouselSliderController();

    _buttonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonAnimController, curve: Curves.easeInOut),
    );

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _buttonAnimController.dispose();
    super.dispose();
  }

  Future<void> _selectBike() async {
    if (_isSelecting) return;

    setState(() => _isSelecting = true);
    HapticFeedback.mediumImpact();

    final provider = context.read<BikeProvider>();
    final selectedBike = _bikes[_currentIndex];

    final success = await provider.selectBike(selectedBike);

    if (success && mounted) {
      // Navigate to dashboard
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else if (mounted) {
      setState(() => _isSelecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save selection. Please try again.'),
          backgroundColor: Colors.red.shade900,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndustrialBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Carousel
              Expanded(child: _buildCarousel()),

              // Pagination indicators
              _buildPaginationIndicators(),

              const SizedBox(height: 24),

              // Select button
              _buildSelectButton(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          // Logo / Title
          Text(
            'BIKE LOGG',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'SELECT YOUR\nMACHINE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 60,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return CarouselSlider.builder(
      carouselController: _pageController,
      itemCount: _bikes.length,
      itemBuilder: (BuildContext context, int index, int pageViewIndex) {
        return BikeCarouselItem(
          bike: _bikes[index],
          isActive: true,
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          },
        );
      },
      options: CarouselOptions(
        height: 400,
        aspectRatio: 16 / 9,
        viewportFraction: 0.8,
        initialPage: 0,
        enableInfiniteScroll: true,
        reverse: false,
        autoPlayAnimationDuration: Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
        enlargeCenterPage: true,
        enlargeFactor: 0.3,
        onPageChanged: (index, _) {
          setState(() => _currentIndex = index);
        },
        scrollDirection: Axis.horizontal,
      ),
    );
    // return PageView.builder(
    //   controller: _pageController,
    //   itemCount: _bikes.length,
    //   scrollBehavior: ScrollBehavior().copyWith(
    //     dragDevices: {
    //       PointerDeviceKind.touch,
    //       PointerDeviceKind.mouse,
    //       PointerDeviceKind.trackpad,
    //     }
    //   ),
    //   onPageChanged: (index) {
    //     setState(() => _currentIndex = index);
    //     HapticFeedback.selectionClick();
    //   },
    //   itemBuilder: (context, index) {
    //     return BikeCarouselItem(
    //       bike: _bikes[index],
    //       isActive: index == _currentIndex,
    //       onTap: () {
    //         _pageController.animateToPage(
    //           index,
    //           duration: const Duration(milliseconds: 400),
    //           curve: Curves.easeOutCubic,
    //         );
    //       },
    //     );
    //   },
    // );
  }

  Widget _buildPaginationIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_bikes.length, (index) {
        final isActive = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildSelectButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onTapDown: (_) => _buttonAnimController.forward(),
        onTapUp: (_) {
          _buttonAnimController.reverse();
          _selectBike();
        },
        onTapCancel: () => _buttonAnimController.reverse(),
        child: ScaleTransition(
          scale: _buttonScaleAnim,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFE0E0E0)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: _isSelecting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SELECT BIKE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: 3,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
