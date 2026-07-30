import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/bike_provider.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.email?.split('@').first ?? 'Rider';
    final bikeState = ref.watch(bikeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hey, $name',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('👋', style: TextStyle(fontSize: 24))
                        .animate(onPlay: (controller) => controller.repeat())
                        .shake(delay: 2.seconds, duration: 1.seconds),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Managing ${bikeState.selectedBike?.name ?? 'your bike'}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          _HeaderAction(
            icon: Icons.calendar_today_outlined,
            onTap: () => context.push(AppRoutes.calendar),
          ),
          const SizedBox(width: 12),
          _HeaderAction(
            icon: Icons.notifications_none_rounded,
            onTap: () {},
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
            color: theme.colorScheme.surface,
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
        ),
      ),
    );
  }
}
