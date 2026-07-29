import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                 Navigator.pushNamed(context, AppRoutes.bikeSettings);
               },
               child: SettingsTile(
                icon: Icons.directions_bike_rounded,
                title: 'Change Bike',
                subtitle: '${bikeProvider.selectedBike?.brandName} ${bikeProvider.selectedBike?.name}',
               ),
             ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.mileageTracker),
              child: const SettingsTile(
                icon: Icons.speed_rounded,
                title: 'Mileage Tracker',
                subtitle: 'Compare fuel records & calculate efficiency',
              ),
            ),
            const SettingsTile(
              icon: Icons.notifications_rounded,
              title: 'Notifications',
              subtitle: 'Enabled',
            ),
            GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: AppColors.border),
                    ),
                    title: const Text("Total Wipeout?", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    content: const Text(
                      "This will delete ALL expenses. Even the ones you're proud of. Are you absolutely sure you want to go back to financial zero?",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("NEVERMIND", style: TextStyle(color: AppColors.textDim)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("GO NUKULAR", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  // TODO: Implement clear all data logic in provider
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Everything has been vaporized! 💨',style: TextStyle(color: Colors.white),),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.cardBg,
                    ),
                  );
                }
              },
              child: const SettingsTile(
                icon: Icons.delete_sweep_rounded,
                title: 'Clear All Data',
                subtitle: 'Permanently remove all expenses',
              ),
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
