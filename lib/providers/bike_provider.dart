import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bike_model.dart';
import '../services/bike_storage_service.dart';
import 'auth_provider.dart';

class BikeState {
  final BikeModel? selectedBike;
  final List<String> ownedBikeNames;
  final bool isLoading;
  final String? currentUserId;

  BikeState({
    this.selectedBike,
    this.ownedBikeNames = const [],
    this.isLoading = true,
    this.currentUserId,
  });

  bool get hasBikeSelected => selectedBike != null;
  bool get hasMultipleBikes => ownedBikeNames.length > 1;

  BikeState copyWith({
    BikeModel? selectedBike,
    List<String>? ownedBikeNames,
    bool? isLoading,
    String? currentUserId,
    bool clearBike = false,
  }) {
    return BikeState(
      selectedBike: clearBike ? null : (selectedBike ?? this.selectedBike),
      ownedBikeNames: ownedBikeNames ?? this.ownedBikeNames,
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
    final owned = await BikeStorageService.getOwnedBikes(userId);
    var bike = await BikeStorageService.getSelectedBike(userId);

    // If no bike selected or selected bike was removed from owned bikes, fallback to first owned bike
    if (bike == null || (owned.isNotEmpty && !owned.any((n) => n.toLowerCase() == bike!.name.toLowerCase()))) {
      if (owned.isNotEmpty) {
        bike = BikeModel.findByName(owned.first) ??
            BikeModel(
              id: owned.first.toLowerCase().replaceAll(' ', '-'),
              name: owned.first,
              imageUrl: 'asset/ns.png',
              tagline: 'Custom Machine',
              engineCC: 200,
              horsepower: 20,
              brandName: 'Custom',
            );
        await BikeStorageService.saveSelectedBike(userId: userId, bike: bike);
      }
    }

    if (state.currentUserId == userId) {
      state = state.copyWith(
        selectedBike: bike,
        ownedBikeNames: owned,
        isLoading: false,
      );
    }
  }

  Future<void> initialize(String userId) async {
    state = state.copyWith(currentUserId: userId, isLoading: true);
    await _loadBike(userId);
  }

  Future<bool> selectBike(BikeModel bike) async {
    final uid = state.currentUserId ??
        ref.read(currentUserProvider)?.uid ??
        FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final success = await BikeStorageService.saveSelectedBike(
      userId: uid,
      bike: bike,
    );

    if (success) {
      // Ensure the selected bike is also recorded in owned bikes
      final updatedOwned = List<String>.from(state.ownedBikeNames);
      final alreadyPresent = updatedOwned.any((n) => n.toLowerCase() == bike.name.toLowerCase());
      if (!alreadyPresent) {
        updatedOwned.add(bike.name);
        await BikeStorageService.saveOwnedBikes(userId: uid, bikes: updatedOwned);
      }

      state = state.copyWith(
        selectedBike: bike,
        ownedBikeNames: updatedOwned,
        currentUserId: uid,
      );
    }
    return success;
  }

  /// Sets the user's customized owned bikes list and persists to Firestore and local storage.
  Future<bool> setOwnedBikes(List<String> bikes) async {
    final uid = state.currentUserId ??
        ref.read(currentUserProvider)?.uid ??
        FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || bikes.isEmpty) return false;

    final success = await BikeStorageService.saveOwnedBikes(
      userId: uid,
      bikes: bikes,
    );

    if (success) {
      BikeModel? newSelected = state.selectedBike;
      final stillOwned = newSelected != null &&
          bikes.any((n) => n.toLowerCase() == newSelected!.name.toLowerCase());

      if (!stillOwned && bikes.isNotEmpty) {
        newSelected = BikeModel.findByName(bikes.first) ??
            BikeModel(
              id: bikes.first.toLowerCase().replaceAll(' ', '-'),
              name: bikes.first,
              imageUrl: 'asset/ns.png',
              tagline: 'Custom Machine',
              engineCC: 200,
              horsepower: 20,
              brandName: 'Custom',
            );
        await BikeStorageService.saveSelectedBike(userId: uid, bike: newSelected);
      }

      state = state.copyWith(
        selectedBike: newSelected,
        ownedBikeNames: bikes,
        currentUserId: uid,
      );
    }

    return success;
  }

  Future<void> clearOnLogout() async {
    state = BikeState(isLoading: false);
  }
}

final bikeProvider = NotifierProvider<BikeNotifier, BikeState>(BikeNotifier.new);

final userOwnedBikesProvider = Provider<List<String>>((ref) {
  return ref.watch(bikeProvider).ownedBikeNames;
});

final hasMultipleBikesProvider = Provider<bool>((ref) {
  return ref.watch(bikeProvider).hasMultipleBikes;
});

