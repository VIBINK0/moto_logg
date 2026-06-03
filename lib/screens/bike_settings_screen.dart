// lib/screens/bike_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/bike_model.dart';
import '../providers/bike_provider.dart';

class BikeSettingsScreen extends StatelessWidget {
  const BikeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'BIKE SETTINGS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<BikeProvider>(
        builder: (context, provider, _) {
          final currentBike = provider.selectedBike;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current selection card
                if (currentBike != null) _buildCurrentBikeCard(currentBike),

                const SizedBox(height: 32),

                Text(
                  'AVAILABLE BIKES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 16),

                // Bike list
                ...BikeModel.availableBikes.map(
                      (bike) => _buildBikeOption(
                    context,
                    bike,
                    isSelected: currentBike?.id == bike.id,
                    provider: provider,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentBikeCard(BikeModel bike) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'CURRENT SELECTION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Image.asset(
            bike.imageUrl,
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.two_wheeler,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            bike.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${bike.engineCC}cc • ${bike.horsepower}hp',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBikeOption(
      BuildContext context,
      BikeModel bike, {
        required bool isSelected,
        required BikeProvider provider,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSelected
              ? null
              : () async {
            HapticFeedback.mediumImpact();
            await provider.selectBike(bike);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Switched to ${bike.name}'),
                  backgroundColor: Colors.grey.shade900,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.03),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                // Bike thumbnail
                Container(
                  width: 60,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: Image.asset(
                    bike.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.two_wheeler,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Bike info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bike.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(isSelected ? 1 : 0.8),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${bike.engineCC}cc • ${bike.horsepower}hp',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.black,
                      size: 16,
                    ),
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
