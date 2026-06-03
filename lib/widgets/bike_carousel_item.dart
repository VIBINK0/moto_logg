// lib/widgets/bike_carousel_item.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/bike_model.dart';

class BikeCarouselItem extends StatelessWidget {
  final BikeModel bike;
  final bool isActive;
  final VoidCallback onTap;

  const BikeCarouselItem({
    super.key,
    required this.bike,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isActive ? 20 : 40,
        ),
        transform: Matrix4.identity()..scale(isActive ? 1.0 : 0.85),
        child: Stack(
          children: [
            // Glassmorphism card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isActive
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  width: isActive ? 2 : 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(isActive ? 0.15 : 0.08),
                    Colors.white.withOpacity(isActive ? 0.05 : 0.02),
                  ],
                ),
                boxShadow: isActive
                    ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: isActive
                      ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                      : ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Bike image
                        Expanded(
                          flex: 3,
                          child: Hero(
                            tag: 'bike_${bike.id}',
                            child: Image.asset(
                              bike.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Bike name
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: isActive ? 28 : 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 3,
                          ),
                          child: Text(
                            bike.name,
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Tagline
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isActive ? 1 : 0.5,
                          child: Text(
                            bike.tagline,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 2,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),

                        if (isActive) ...[
                          const SizedBox(height: 20),
                          // Specs row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSpec('${bike.engineCC}', 'CC'),
                              Container(
                                width: 1,
                                height: 30,
                                margin: const EdgeInsets.symmetric(horizontal: 24),
                                color: Colors.white.withOpacity(0.3),
                              ),
                              _buildSpec('${bike.horsepower}', 'HP'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Active glow effect
            if (isActive)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.5,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpec(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.two_wheeler,
        size: 100,
        color: Colors.white.withOpacity(0.3),
      ),
    );
  }
}
