import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/repositories.dart';
import '../../../domain/entities/entities.dart';
import '../../blocs/auth/auth.dart';
import '../../widgets/common/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifyOnLowEnergy = true;
  bool _notifyMealReminders = true;
  String _selectedSensitivity = 'Sensitive';
  String _selectedGoal = 'Maintenance';
  String _selectedUnits = 'metric';

  final UsersRepository _usersRepository = UsersRepositoryImpl();
  final AnalyticsRepository _analyticsRepository = AnalyticsRepositoryImpl();

  bool _saving = false;
  bool _initializedFromUser = false;

  SensitivityLevel get _sensitivityEnum =>
      SensitivityLevel.fromString(_selectedSensitivity);
  TargetGoal get _goalEnum => TargetGoal.fromString(_selectedGoal);

  Future<void> _savePreferences(User? user) async {
    if (user == null || _saving) return;
    setState(() => _saving = true);
    try {
      await _usersRepository.updateUserPreferences(
        userId: user.id,
        sensitivityLevel: _sensitivityEnum,
        targetGoal: _goalEnum,
        units: _selectedUnits,
        notifyOnLowEnergy: _notifyOnLowEnergy,
        notifyMealReminders: _notifyMealReminders,
      );
      if (mounted) _showMessage('Preferences saved');
    } catch (e) {
      if (mounted) _showMessage('Failed to save preferences: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SETTINGS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.unauthenticated) {
            context.go('/login');
          }
        },
        builder: (context, state) {
          final user = state.user;
          if (!_initializedFromUser && user != null) {
            _selectedSensitivity = user.sensitivityLevel.displayName;
            _selectedGoal = user.targetGoal.displayName;
            _selectedUnits = user.units;
            _initializedFromUser = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileSection(user?.displayName, user?.email),
                const SizedBox(height: 24),
                _buildSectionTitle('PREFERENCES'),
                const SizedBox(height: 12),
                _buildPreferencesCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('NOTIFICATIONS'),
                const SizedBox(height: 12),
                _buildNotificationsCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('DATA & PRIVACY'),
                const SizedBox(height: 12),
                _buildDataCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('ACCOUNT'),
                const SizedBox(height: 12),
                _buildAccountCard(context),
                const SizedBox(height: 32),
                _buildAppInfo(),
                if (_saving) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(String? name, String? email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (name ?? 'USER').toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email ?? 'NO EMAIL',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: AppColors.textSecondary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildListTile(
            'Sensitivity Level',
            _selectedSensitivity,
            Icons.tune_rounded,
            onTap: _showSensitivityDialog,
          ),
          _buildDivider(),
          _buildListTile(
            'Target Goal',
            _selectedGoal,
            Icons.flag_rounded,
            onTap: _showGoalDialog,
          ),
          _buildDivider(),
          _buildListTile(
            'Units',
            _selectedUnits == 'metric' ? 'Metric' : 'Imperial',
            Icons.straighten_rounded,
            onTap: _showUnitsDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Low Energy Alerts',
            'Get notified when energy is critical',
            Icons.battery_alert_rounded,
            _notifyOnLowEnergy,
            (value) {
              setState(() => _notifyOnLowEnergy = value);
              _savePreferences(context.read<AuthBloc>().state.user);
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            'Meal Reminders',
            'Remind me to log meals',
            Icons.notifications_rounded,
            _notifyMealReminders,
            (value) {
              setState(() => _notifyMealReminders = value);
              _savePreferences(context.read<AuthBloc>().state.user);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildListTile(
            'Export Data',
            'Download your data as JSON/CSV',
            Icons.download_rounded,
            onTap: _exportData,
          ),
          _buildDivider(),
          _buildListTile(
            'Clear Cache',
            'Free up storage space',
            Icons.cleaning_services_rounded,
            onTap: _clearCache,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildListTile(
            'Change Password',
            'Update your password',
            Icons.lock_rounded,
            onTap: _showChangePasswordDialog,
          ),
          _buildDivider(),
          _buildListTile(
            'Log Out',
            'Sign out of your account',
            Icons.logout_rounded,
            textColor: AppColors.error,
            onTap: () => _showLogoutDialog(context),
          ),
          _buildDivider(),
          _buildListTile(
            'Delete Account',
            'Permanently delete your account',
            Icons.delete_forever_rounded,
            textColor: AppColors.error,
            onTap: () => _showDeleteDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: textColor ?? AppColors.primaryBlue, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryBlue, size: 24),
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
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.border,
      indent: 80,
      endIndent: 20,
    );
  }

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          Text(
            'FuelFlow',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          TextActionButton(
            label: 'Privacy Policy',
            onPressed: () => _showMessage(
              'Privacy Policy: data is used for energy analytics and remains private to your account.',
            ),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  void _showSensitivityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sensitivity Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Sensitive', 'Normal', 'Low']
              .map(
                (level) => ListTile(
                  title: Text(level),
                  trailing: _selectedSensitivity == level
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedSensitivity = level);
                    Navigator.pop(context);
                    _savePreferences(context.read<AuthBloc>().state.user);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Target Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Maintenance', 'Bulking', 'Cutting']
              .map(
                (goal) => ListTile(
                  title: Text(goal),
                  trailing: _selectedGoal == goal
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedGoal = goal);
                    Navigator.pop(context);
                    _savePreferences(context.read<AuthBloc>().state.user);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showUnitsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Units'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Metric'),
              trailing: _selectedUnits == 'metric'
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _selectedUnits = 'metric');
                Navigator.pop(context);
                _savePreferences(context.read<AuthBloc>().state.user);
              },
            ),
            ListTile(
              title: const Text('Imperial'),
              trailing: _selectedUnits == 'imperial'
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _selectedUnits = 'imperial');
                Navigator.pop(context);
                _savePreferences(context.read<AuthBloc>().state.user);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final user = context.read<AuthBloc>().state.user;
    final nameCtrl = TextEditingController(text: user?.displayName ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              Navigator.pop(context);
              if (user == null || name.isEmpty) return;
              final authBloc = this.context.read<AuthBloc>();
              try {
                await _usersRepository.updateProfile(userId: user.id, displayName: name);
                if (!mounted) return;
                authBloc.add(const AuthCheckStatus());
                _showMessage('Profile updated');
              } catch (e) {
                _showMessage('Failed to update profile: $e');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final authRepo = AuthRepositoryImpl();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await authRepo.changePassword(
                  currentPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                );
                _showMessage('Password changed successfully');
              } catch (e) {
                _showMessage('Failed to change password: $e');
              }
            },
            child: const Text('Change'),
          ),
        ],
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
              this.context.read<AuthBloc>().add(const AuthLogout());
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('LOG OUT'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authBloc = this.context.read<AuthBloc>();
              final user = authBloc.state.user;
              if (user == null) return;
              try {
                await _usersRepository.deleteUser(userId: user.id);
                if (!mounted) return;
                authBloc.add(const AuthLogout());
                _showMessage('Account deleted');
              } catch (e) {
                _showMessage('Failed to delete account: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final export = await _analyticsRepository.exportData();
      final length = export.toString().length;
      _showMessage('Export generated ($length chars)');
    } catch (e) {
      _showMessage('Export failed: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      await Hive.box('meals').clear();
      await Hive.box('activities').clear();
      _showMessage('Local cache cleared');
    } catch (e) {
      _showMessage('Failed to clear cache: $e');
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
