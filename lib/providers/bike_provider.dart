// lib/providers/bike_provider.dart

import 'package:flutter/foundation.dart';
import '../models/bike_model.dart';
import '../services/bike_storage_service.dart';

class BikeProvider with ChangeNotifier {
  BikeModel? _selectedBike;
  bool _isLoading = true;
  String? _currentUserId;

  BikeModel? get selectedBike => _selectedBike;
  bool get isLoading => _isLoading;
  bool get hasBikeSelected => _selectedBike != null;

  /// Initialize provider with user ID
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();

    _selectedBike = await BikeStorageService.getSelectedBike(userId);
    _isLoading = false;
    notifyListeners();
  }

  /// Select a bike
  Future<bool> selectBike(BikeModel bike) async {
    if (_currentUserId == null) return false;

    final success = await BikeStorageService.saveSelectedBike(
      userId: _currentUserId!,
      bike: bike,
    );

    if (success) {
      _selectedBike = bike;
      notifyListeners();
    }
    return success;
  }

  /// Clear selection on logout
  Future<void> clearOnLogout() async {
    if (_currentUserId != null) {
      await BikeStorageService.clearSelectedBike(_currentUserId!);
    }
    _selectedBike = null;
    _currentUserId = null;
    notifyListeners();
  }
}
