import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bike_model.dart';
import '../services/bike_storage_service.dart';

class BikeState {
  final BikeModel? selectedBike;
  final bool isLoading;
  final String? currentUserId;

  BikeState({
    this.selectedBike,
    this.isLoading = true,
    this.currentUserId,
  });

  BikeState copyWith({
    BikeModel? selectedBike,
    bool? isLoading,
    String? currentUserId,
    bool clearBike = false,
  }) {
    return BikeState(
      selectedBike: clearBike ? null : (selectedBike ?? this.selectedBike),
      isLoading: isLoading ?? this.isLoading,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}

class BikeNotifier extends Notifier<BikeState> {
  @override
  BikeState build() => BikeState();

  Future<void> initialize(String userId) async {
    state = state.copyWith(currentUserId: userId, isLoading: true);
    final bike = await BikeStorageService.getSelectedBike(userId);
    state = state.copyWith(selectedBike: bike, isLoading: false);
  }

  Future<bool> selectBike(BikeModel bike) async {
    if (state.currentUserId == null) return false;

    final success = await BikeStorageService.saveSelectedBike(
      userId: state.currentUserId!,
      bike: bike,
    );

    if (success) {
      state = state.copyWith(selectedBike: bike);
    }
    return success;
  }

  Future<void> clearOnLogout() async {
    if (state.currentUserId != null) {
      await BikeStorageService.clearSelectedBike(state.currentUserId!);
    }
    state = BikeState(isLoading: false);
  }
}

final bikeProvider = NotifierProvider<BikeNotifier, BikeState>(BikeNotifier.new);
