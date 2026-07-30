import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationState {
  final int currentIndex;
  final PageController pageController;

  NavigationState({
    required this.currentIndex,
    required this.pageController,
  });

  NavigationState copyWith({int? currentIndex}) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      pageController: pageController,
    );
  }
}

class NavigationNotifier extends AutoDisposeNotifier<NavigationState> {
  @override
  NavigationState build() {
    final controller = PageController();
    ref.onDispose(() => controller.dispose());
    return NavigationState(
      currentIndex: 0,
      pageController: controller,
    );
  }

  void setIndex(int index) {
    if (state.currentIndex == index) return;
    state = state.copyWith(currentIndex: index);
    state.pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void updateIndex(int index) {
    if (state.currentIndex == index) return;
    state = state.copyWith(currentIndex: index);
  }
}

final navigationProvider = NotifierProvider.autoDispose<NavigationNotifier, NavigationState>(
  NavigationNotifier.new,
);
