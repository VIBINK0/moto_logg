import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bike_model.dart';
import '../services/bike_storage_service.dart';
import 'auth_provider.dart';

class BikeState {
  final BikeModel? selectedBike;
  final bool isLoading;
  final String? currentUserId;

  BikeState({
    this.selectedBike,
    this.isLoading = true,
    this.currentUserId,
  });

  bool get hasBikeSelected => selectedBike != null;

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
  BikeState build() {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return BikeState(isLoading: false);
    }
    _loadBike(user.uid);
    return BikeState(isLoading: true, currentUserId: user.uid);
  }

  Future<void> _loadBike(String userId) async {
    final bike = await BikeStorageService.getSelectedBike(userId);
    if (state.currentUserId == userId) {
      state = state.copyWith(selectedBike: bike, isLoading: false);
    }
  }

  Future<void> initialize(String userId) async {
    state = state.copyWith(currentUserId: userId, isLoading: true);
    final bike = await BikeStorageService.getSelectedBike(userId);
    state = state.copyWith(selectedBike: bike, isLoading: false, currentUserId: userId);
  }

  Future<bool> selectBike(BikeModel bike) async {
    final uid = state.currentUserId ?? ref.read(currentUserProvider)?.uid;
    if (uid == null) return false;

    final success = await BikeStorageService.saveSelectedBike(
      userId: uid,
      bike: bike,
    );

    if (success) {
      state = state.copyWith(selectedBike: bike, currentUserId: uid);
    }
    return success;
  }

  Future<void> clearOnLogout() async {
    state = BikeState(isLoading: false);
  }
}

final bikeProvider = NotifierProvider<BikeNotifier, BikeState>(BikeNotifier.new);

