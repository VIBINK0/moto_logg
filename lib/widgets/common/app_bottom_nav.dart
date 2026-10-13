import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/navigation_provider.dart';
import '../sheets/add_expense_sheet.dart';

class AppBottomNav extends ConsumerWidget {
  final int current;
  final VoidCallback? onAdd;

  const AppBottomNav({
    super.key,
    required this.current,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const items = [
      (Icons.grid_view_rounded, 'Overview'),
      (Icons.receipt_long_rounded, 'Logs'),
      (Icons.analytics_outlined, 'Stats'),
      (Icons.settings_outlined, 'Account'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 74,
        padding: const EdgeInsets.only(left: 18, right: 18, bottom: 12),
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            height: 62,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1B1B1E),
                    Color(0xFF111113),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.04),
                    blurRadius: 2,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle top specular highlight curve
                  Positioned(
                    top: 0,
                    left: 28,
                    right: 28,
                    height: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Navigation Items + Center Action
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Tab 0: Overview
                        _NavTabItem(
                          icon: items[0].$1,
                          label: items[0].$2,
                          isActive: current == 0,
                          onTap: () => ref
                              .read(navigationProvider.notifier)
                              .setIndex(0),
                        ),

                        // Tab 1: Logs
                        _NavTabItem(
                          icon: items[1].$1,
                          label: items[1].$2,
                          isActive: current == 1,
                          onTap: () => ref
                              .read(navigationProvider.notifier)
                              .setIndex(1),
                        ),

                        // Center Quick Add Button
                        _QuickAddButton(
                          onTap: onAdd ??
                              () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) => const AddExpenseSheet(),
                                  ),
                        ),

                        // Tab 2: Stats
                        _NavTabItem(
                          icon: items[2].$1,
                          label: items[2].$2,
                          isActive: current == 2,
                          onTap: () => ref
                              .read(navigationProvider.notifier)
                              .setIndex(2),
                        ),

                        // Tab 3: Account
                        _NavTabItem(
                          icon: items[3].$1,
                          label: items[3].$2,
                          isActive: current == 3,
                          onTap: () => ref
                              .read(navigationProvider.notifier)
                              .setIndex(3),
                        ),
                      ],
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

/// Expanding modern minimalist tab item with fluid spring transition
class _NavTabItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavTabItem> createState() => _NavTabItemState();
}

class _NavTabItemState extends State<_NavTabItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isActive ? 13 : 9,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isActive
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.transparent,
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 19,
                color: widget.isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.42),
              ),
              if (widget.isActive) ...[
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimalist tactile Quick-Add action button in pure monochrome
class _QuickAddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _QuickAddButton({required this.onTap});

  @override
  State<_QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<_QuickAddButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Color(0xFF101012),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
