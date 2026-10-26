import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../models/bike_model.dart';
import '../../providers/bike_provider.dart';
import '../../providers/expense_provider.dart';

class ManageGarageScreen extends ConsumerStatefulWidget {
  const ManageGarageScreen({super.key});

  @override
  ConsumerState<ManageGarageScreen> createState() => _ManageGarageScreenState();
}

class _ManageGarageScreenState extends ConsumerState<ManageGarageScreen> {
  final Set<String> _selectedBikeNames = {};
  final List<BikeModel> _customBikes = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final owned = ref.read(userOwnedBikesProvider);
    if (owned.isNotEmpty) {
      _selectedBikeNames.addAll(owned);
    } else {
      final current = ref.read(bikeProvider).selectedBike;
      if (current != null) {
        _selectedBikeNames.add(current.name);
      } else {
        _selectedBikeNames.add(BikeModel.defaultBike.name);
      }
    }

    // Add any existing owned bikes that are not in availableBikes as custom bikes
    for (final name in _selectedBikeNames) {
      final inPresets = BikeModel.availableBikes.any(
        (b) => b.name.toLowerCase() == name.toLowerCase(),
      );
      if (!inPresets) {
        _customBikes.add(
          BikeModel(
            id: name.toLowerCase().replaceAll(' ', '-'),
            name: name,
            imageUrl: 'asset/ns.png',
            tagline: 'Custom Machine',
            engineCC: 200,
            horsepower: 20,
            brandName: 'Custom',
          ),
        );
      }
    }
  }

  void _toggleBike(String name) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedBikeNames.contains(name)) {
        if (_selectedBikeNames.length == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('At least one bike must remain in your garage.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.cardBg,
            ),
          );
          return;
        }
        _selectedBikeNames.remove(name);
      } else {
        _selectedBikeNames.add(name);
      }
    });
  }

  Future<void> _showAddCustomBikeDialog() async {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final ccController = TextEditingController(text: '350');

    final result = await showDialog<BikeModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Text(
          'Add Custom Machine',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Model Name (e.g. Speed 400)',
                labelStyle: TextStyle(color: Colors.white60),
                hintText: 'e.g. Duke 390',
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: brandController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Brand / Make (e.g. Triumph)',
                labelStyle: TextStyle(color: Colors.white60),
                hintText: 'e.g. KTM',
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ccController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Engine CC',
                labelStyle: TextStyle(color: Colors.white60),
                hintText: '350',
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF88),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final brand = brandController.text.trim().isEmpty ? 'Custom' : brandController.text.trim();
              final cc = int.tryParse(ccController.text.trim()) ?? 250;

              final newBike = BikeModel(
                id: name.toLowerCase().replaceAll(' ', '-'),
                name: name,
                imageUrl: 'asset/ns.png',
                tagline: 'Custom Ride',
                engineCC: cc,
                horsepower: 25,
                brandName: brand,
              );
              Navigator.pop(ctx, newBike);
            },
            child: const Text('Add Machine', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _customBikes.add(result);
        _selectedBikeNames.add(result.name);
      });
    }
  }

  Future<void> _saveGarage() async {
    if (_selectedBikeNames.isEmpty) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final list = _selectedBikeNames.toList();
      final success = await ref.read(bikeProvider.notifier).setOwnedBikes(list);

      if (success) {
        // Also sync the active expense filter
        final currentSelected = ref.read(bikeProvider).selectedBike?.name;
        if (currentSelected != null && list.contains(currentSelected)) {
          ref.read(expenseFilterProvider.notifier).setSelectedBikeName(currentSelected);
        } else {
          ref.read(expenseFilterProvider.notifier).setSelectedBikeName(list.first);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Garage updated! Tracking ${list.length} machine${list.length > 1 ? "s" : ""} 🏍️⚡'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.cardBg,
            ),
          );
          Navigator.pop(context);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update garage. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine preset catalog with custom bikes
    final allBikes = [...BikeModel.availableBikes, ..._customBikes];
    final selectedCount = _selectedBikeNames.length;
    final isSingleBike = selectedCount == 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F11),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Garage',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Custom Bike',
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF00FF88)),
            onPressed: _showAddCustomBikeDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status & Info Banner
            Container(
              margin: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.garage_rounded, color: Color(0xFF00FF88), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$selectedCount machine${selectedCount == 1 ? "" : "s"} selected',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSingleBike
                              ? 'Single bike mode: Multi-bike switchers will be hidden.'
                              : 'Multi-machine fleet: Easy quick-switching enabled.',
                          style: TextStyle(
                            color: isSingleBike ? const Color(0xFF00FF88) : Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SELECT MACHINES YOU OWN',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF00FF88)),
                    label: const Text(
                      'Custom Bike',
                      style: TextStyle(color: Color(0xFF00FF88), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _showAddCustomBikeDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Bike Catalog List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                itemCount: allBikes.length,
                itemBuilder: (context, index) {
                  final bike = allBikes[index];
                  final isOwned = _selectedBikeNames.contains(bike.name);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isOwned
                          ? const Color(0xFF00FF88).withValues(alpha: 0.08)
                          : const Color(0xFF161619),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isOwned
                            ? const Color(0xFF00FF88)
                            : Colors.white.withValues(alpha: 0.06),
                        width: isOwned ? 1.5 : 0.8,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _toggleBike(bike.name),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Machine Thumbnail
                              Container(
                                width: 56,
                                height: 56,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.asset(
                                  bike.imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.two_wheeler_rounded,
                                    color: Colors.white60,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Name & Specs
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bike.name,
                                      style: TextStyle(
                                        color: isOwned ? Colors.white : Colors.white70,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${bike.brandName} • ${bike.engineCC}cc • ${bike.horsepower} HP',
                                      style: TextStyle(
                                        color: isOwned
                                            ? const Color(0xFF00FF88).withValues(alpha: 0.9)
                                            : Colors.white38,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Selection Checkbox / Icon
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isOwned ? const Color(0xFF00FF88) : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isOwned
                                        ? const Color(0xFF00FF88)
                                        : Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: isOwned
                                    ? const Icon(Icons.check_rounded, color: Colors.black, size: 18)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms);
                },
              ),
            ),

            // Bottom Save Button
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF88),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveGarage,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'Save Garage ($selectedCount Selected)',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
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
}
