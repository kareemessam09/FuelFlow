import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/analytics_repository.dart';
import '../../../data/repositories/users_repository.dart';
import '../../../domain/entities/entities.dart';
import '../../blocs/blocs.dart';
import '../../widgets/common/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  int _calculateMemberDays(User? user) {
    if (user == null) return 0;
    final joinedAt = DateTime(
      user.createdAt.year,
      user.createdAt.month,
      user.createdAt.day,
    );
    final now = DateTime.now();
    final days = now.difference(joinedAt).inDays + 1;
    return days < 1 ? 1 : days;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PROFILE'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.unauthenticated) {
            context.go('/login');
          }
        },
        builder: (context, state) {
          final user = state.user;
          final displayName = user?.displayName?.trim();
          final email = user?.email?.trim();
          final profileName = (displayName != null && displayName.isNotEmpty)
              ? displayName
              : 'FuelFlow User';
          final profileEmail = (email != null && email.isNotEmpty)
              ? email
              : 'No email linked';
          final memberDays = _calculateMemberDays(user);
          final analyticsState = context.watch<AnalyticsBloc>().state;
          if (analyticsState is AnalyticsInitial) {
            context.read<AnalyticsBloc>().add(const AnalyticsLoadData('week'));
          }
          int totalMeals = 0;
          String avgEnergy = '--';
          int activities = 0;
          if (analyticsState is AnalyticsLoaded) {
            totalMeals = analyticsState.weeklyReport?.totalMeals ?? 0;
            avgEnergy =
                '${(analyticsState.weeklyReport?.avgEnergyLevel ?? 0).toStringAsFixed(0)}%';
            activities =
                analyticsState.activityStats?.activityMinutes.length ?? 0;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Profile Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        profileName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profileEmail,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Meals',
                        '$totalMeals',
                        Icons.restaurant_rounded,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Member Days',
                        '$memberDays',
                        Icons.calendar_today_rounded,
                        AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Avg Energy',
                        avgEnergy,
                        Icons.battery_charging_full_rounded,
                        AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Activities',
                        '$activities',
                        Icons.fitness_center_rounded,
                        AppColors.accent,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Quick Actions
                _buildActionCard(
                  'Edit Profile',
                  'Update your personal information',
                  Icons.edit_rounded,
                  () => _showEditProfileDialog(context, user),
                  accentColor: AppColors.primaryBlue,
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  'Export Data',
                  'Download your energy and meal data',
                  Icons.download_rounded,
                  () => _exportProfileData(context),
                  accentColor: AppColors.primary,
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  'Share Profile',
                  'Share your progress with friends',
                  Icons.share_rounded,
                  () => _shareProfileSummary(
                    context,
                    user: user,
                    totalMeals: totalMeals,
                    avgEnergy: avgEnergy,
                    activities: activities,
                    memberDays: memberDays,
                  ),
                  accentColor: AppColors.accent,
                ),

                const SizedBox(height: 40),

                BrutalButton(
                  label: 'Log Out',
                  icon: Icons.logout_rounded,
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, color: accentColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textTertiary,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogout());
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('LOG OUT'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context, User? user) async {
    if (user == null) {
      _showMessage(context, 'Sign in to update your profile');
      return;
    }

    final nameCtrl = TextEditingController(text: user.displayName ?? '');
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!context.mounted || shouldSave != true) return;
    final displayName = nameCtrl.text.trim();
    if (displayName.isEmpty) {
      _showMessage(context, 'Display name cannot be empty');
      return;
    }

    try {
      await UsersRepositoryImpl().updateProfile(
        userId: user.id,
        displayName: displayName,
      );
      if (!context.mounted) return;
      context.read<AuthBloc>().add(const AuthCheckStatus());
      _showMessage(context, 'Profile updated');
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, 'Failed to update profile: $error');
    }
  }

  Future<void> _exportProfileData(BuildContext context) async {
    try {
      final export = await AnalyticsRepositoryImpl().exportData();
      if (!context.mounted) return;

      final pretty = const JsonEncoder.withIndent('  ').convert(export);
      final preview = pretty.length > 2000
          ? '${pretty.substring(0, 2000)}\n\n...'
          : pretty;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => FractionallySizedBox(
          heightFactor: 0.8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Export Preview',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${export.length} sections ready for export',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        preview,
                        style: const TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlineButton(
                        label: 'Close',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlineButton(
                        label: 'Copy',
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: pretty));
                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop();
                          _showMessage(context, 'Export copied to clipboard');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BrutalButton(
                        label: 'Share',
                        icon: Icons.share_rounded,
                        onPressed: () async {
                          await SharePlus.instance.share(
                            ShareParams(
                              text: pretty,
                              subject: 'FuelFlow Profile Export',
                            ),
                          );
                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, 'Export failed: $error');
    }
  }

  Future<void> _shareProfileSummary(
    BuildContext context, {
    required User? user,
    required int totalMeals,
    required String avgEnergy,
    required int activities,
    required int memberDays,
  }) async {
    final displayName = user?.displayName?.trim();
    final email = user?.email?.trim();
    final name = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : 'FuelFlow User';

    final summary = [
      'FuelFlow progress snapshot',
      'Name: $name',
      if (email != null && email.isNotEmpty) 'Email: $email',
      'Member days: $memberDays',
      'Meals logged: $totalMeals',
      'Average energy: $avgEnergy',
      'Activity modes tracked: $activities',
    ].join('\n');

    await SharePlus.instance.share(
      ShareParams(text: summary, subject: 'FuelFlow Progress Snapshot'),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
