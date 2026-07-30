import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../models/bike_model.dart';
import '../../providers/bike_provider.dart';
import '../../widgets/bike_carousel_item.dart';
import '../../widgets/industrial_background.dart';

// Selection State
final _carouselIndexProvider = StateProvider.autoDispose<int>((ref) => 0);
final _isSelectingProvider = StateProvider.autoDispose<bool>((ref) => false);

class BikeSelectionScreen extends ConsumerWidget {
  const BikeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(_carouselIndexProvider);
    final isSelecting = ref.watch(_isSelectingProvider);
    final bikes = BikeModel.availableBikes;

    Future<void> selectBike() async {
      if (isSelecting) return;

      ref.read(_isSelectingProvider.notifier).state = true;
      HapticFeedback.mediumImpact();

      final provider = ref.read(bikeProvider.notifier);
      final selectedBike = bikes[currentIndex];

      final success = await provider.selectBike(selectedBike);

      if (success && context.mounted) {
        context.go(AppRoutes.dashboard);
      } else if (context.mounted) {
        ref.read(_isSelectingProvider.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save selection')),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndustrialBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildCarousel(context, ref, bikes),
              const Spacer(),
              _buildPaginationIndicators(bikes, currentIndex),
              const SizedBox(height: 24),
              _buildSelectButton(context, ref, isSelecting, selectBike),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
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
        ],
      ),
    );
  }

  Widget _buildCarousel(BuildContext context, WidgetRef ref, List<BikeModel> bikes) {
    return CarouselSlider.builder(
      itemCount: bikes.length,
      itemBuilder: (context, index, realIndex) {
        return BikeCarouselItem(
          bike: bikes[index],
          isActive: index == ref.watch(_carouselIndexProvider),
          onTap: () {},
        );
      },
      options: CarouselOptions(
        height: 400,
        viewportFraction: 0.8,
        enlargeCenterPage: true,
        onPageChanged: (index, _) {
          ref.read(_carouselIndexProvider.notifier).state = index;
        },
      ),
    );
  }

  Widget _buildPaginationIndicators(List<BikeModel> bikes, int currentIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(bikes.length, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  Widget _buildSelectButton(BuildContext context, WidgetRef ref, bool isSelecting, VoidCallback onSelect) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: _SelectButton(
        isLoading: isSelecting,
        onPressed: onSelect,
      ),
    );
  }
}

class _SelectButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _SelectButton({required this.isLoading, required this.onPressed});

  @override
  State<_SelectButton> createState() => _SelectButtonState();
}

class _SelectButtonState extends State<_SelectButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Center(
            child: widget.isLoading
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text(
                    'SELECT BIKE',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
