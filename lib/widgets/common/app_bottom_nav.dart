import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/navigation_provider.dart';

class AppBottomNav extends ConsumerWidget {
  final int current;
  const AppBottomNav({super.key, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final items = [
      (Icons.grid_view_rounded, 'Overview'),
      (Icons.receipt_long_rounded, 'Logs'),
      (Icons.analytics_outlined, 'Stats'),
      (Icons.settings_outlined, 'Account'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withOpacity(0.05), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == current;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => ref.read(navigationProvider.notifier).setIndex(i),
                    borderRadius: BorderRadius.circular(16),
                    highlightColor: theme.colorScheme.primary.withOpacity(0.05),
                    splashColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: 300.ms,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: active 
                                ? theme.colorScheme.primary.withOpacity(0.1) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            items[i].$1,
                            size: 24,
                            color: active 
                                ? theme.colorScheme.primary 
                                : theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                        ).animate(target: active ? 1 : 0)
                         .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), curve: Curves.easeOutBack),
                        const SizedBox(height: 4),
                        Text(
                          items[i].$2,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: active 
                                ? theme.colorScheme.primary 
                                : theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                            fontWeight: active ? FontWeight.bold : FontWeight.normal,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
