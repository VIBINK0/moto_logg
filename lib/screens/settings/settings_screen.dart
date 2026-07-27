import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/bike_provider.dart';
import '../../providers/expense_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/settings_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bikeProvider = context.watch<BikeProvider>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),

            // Logged-in user info card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Signed in as',
                          style: TextStyle(color: AppColors.textDim, fontSize: 10),
                        ),
                        Text(
                          user?.email ?? '—',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

             GestureDetector(
               onTap: (){
                 bikeProvider.clearSelectedBike();
                 context.read<ExpenseProvider>().setTab(0);
               },
               child: SettingsTile(
                icon: Icons.directions_bike_rounded,
                title: 'Change Bike',
                subtitle: '${bikeProvider.selectedBike?.brandName} ${bikeProvider.selectedBike?.name}',
               ),
             ),
            const SettingsTile(
              icon: Icons.notifications_rounded,
              title: 'Notifications',
              subtitle: 'Enabled',
            ),
            const SettingsTile(
              icon: Icons.delete_sweep_rounded,
              title: 'Clear All Data',
              subtitle: 'Permanently remove all expenses',
            ),
            const SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About',
              subtitle: 'MOTO LOGG v1.0.0',
            ),

            const SizedBox(height: 8),

            // Sign Out button
            GestureDetector(
              onTap: () async {
                AuthService.signOut(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.logout_rounded,
                        color: Color(0xFF888888),
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 14),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
