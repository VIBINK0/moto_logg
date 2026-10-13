import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/sms_permission_helper.dart';
import '../../services/sms_transaction_service.dart';

class SmsDetectionSettingsSheet extends ConsumerStatefulWidget {
  const SmsDetectionSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SmsDetectionSettingsSheet(),
    );
  }

  @override
  ConsumerState<SmsDetectionSettingsSheet> createState() => _SmsDetectionSettingsSheetState();
}

class _SmsDetectionSettingsSheetState extends ConsumerState<SmsDetectionSettingsSheet> {
  bool _isLoading = true;
  bool _isSyncing = false;
  SmsPermissionStatus? _status;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _isLoading = true);
    final status = await SmsPermissionHelper.checkPermissions();
    if (mounted) {
      setState(() {
        _status = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRequestPermissions() async {
    await SmsPermissionHelper.requestPermissions();
    await _refreshStatus();
  }

  Future<void> _handleRequestIgnoreBattery() async {
    await SmsPermissionHelper.requestIgnoreBatteryOptimization();
    // Allow system dialog time to dismiss
    await Future.delayed(const Duration(milliseconds: 600));
    await _refreshStatus();
  }

  Future<void> _handleOpenSettings() async {
    await SmsPermissionHelper.openBatterySettings();
  }

  Future<void> _handleCatchUpSync() async {
    setState(() {
      _isSyncing = true;
      _syncMessage = null;
    });

    final found = await ref.read(smsTransactionProvider.notifier).syncMissedTransactions(lookbackHours: 48);

    if (mounted) {
      setState(() {
        _isSyncing = false;
        if (found.isEmpty) {
          _syncMessage = '✨ All caught up! No unlogged transactions found in the last 48 hours.';
        } else {
          _syncMessage = '🎉 Found ${found.length} transaction(s)! Opening confirmation...';
        }
      });

      if (found.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Title & Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sms_rounded, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMS Detection & Background Sync',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Reliable auto-logging even when app is closed',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          else ...[
            // Card 1: SMS & Notification Permissions
            _buildStatusCard(
              icon: Icons.mark_email_read_rounded,
              title: 'SMS & Notification Permissions',
              subtitle: 'Allows MotoLogg to inspect incoming bank debit SMS alerts.',
              isPositive: _status?.isFullyGranted ?? false,
              positiveLabel: 'Granted',
              negativeLabel: 'Not Granted',
              actionButtonText: (_status?.isFullyGranted ?? false) ? null : 'Grant Permissions',
              onAction: _handleRequestPermissions,
            ),
            const SizedBox(height: 12),

            // Card 2: Battery Optimization (The root cause fix)
            _buildStatusCard(
              icon: Icons.battery_charging_full_rounded,
              title: 'Background Activity / Battery Saver',
              subtitle: (_status?.isBatteryOptimizationIgnored ?? false)
                  ? 'Unrestricted: Android will not kill the SMS receiver when closed.'
                  : 'Optimized: Android may freeze detection if app is closed for hours.',
              isPositive: _status?.isBatteryOptimizationIgnored ?? false,
              positiveLabel: 'Unrestricted (Optimal)',
              negativeLabel: 'Restricted by OS',
              actionButtonText: (_status?.isBatteryOptimizationIgnored ?? false)
                  ? 'Manage in Settings'
                  : 'Disable Battery Restrictions',
              onAction: (_status?.isBatteryOptimizationIgnored ?? false)
                  ? _handleOpenSettings
                  : _handleRequestIgnoreBattery,
            ),
            const SizedBox(height: 12),

            // OEM Tip Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.textDim, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'For Xiaomi, Samsung, OnePlus & Vivo devices:',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Turn on "Autostart" and set Battery to "Unrestricted" in App Info so the OS allows instant detection even after days of closure.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _handleOpenSettings,
                          child: const Text(
                            'Open App Info Settings →',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 3: Manual Catch-Up Sync
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history_rounded, color: AppColors.accent, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Catch-Up Inbox Sync',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Did you receive an SMS while the phone was asleep or in battery saver? Sync the inbox from the last 48 hours now.',
                    style: TextStyle(color: AppColors.textDim, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceLight,
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isSyncing ? null : _handleCatchUpSync,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                            )
                          : const Icon(Icons.sync_rounded, size: 18, color: AppColors.accent),
                      label: Text(
                        _isSyncing ? 'Scanning SMS Inbox...' : 'Scan Missed Bank SMS (48 hrs)',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                  if (_syncMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _syncMessage!,
                      style: const TextStyle(color: AppColors.accent, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isPositive,
    required String positiveLabel,
    required String negativeLabel,
    String? actionButtonText,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isPositive ? AppColors.success : AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isPositive ? AppColors.success : AppColors.warning).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  isPositive ? positiveLabel : negativeLabel,
                  style: TextStyle(
                    color: isPositive ? AppColors.success : AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
          if (actionButtonText != null && onAction != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: Text(
                  actionButtonText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
