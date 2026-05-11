import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/repositories.dart';
import '../../widgets/common/common.dart';
import '../../blocs/blocs.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'week';
  final GoalsRepository _goalsRepository = GoalsRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<AnalyticsBloc>().add(AnalyticsLoadData(_selectedPeriod));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ANALYTICS'),
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
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'day', child: Text('Today')),
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _selectedPeriod,
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsLoading) {
            return const StateFeedback(
              icon: Icons.analytics_rounded,
              title: 'Loading analytics',
              description: 'Crunching your energy and meal trends.',
            );
          }

          if (state is AnalyticsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading analytics',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  BrutalButton(onPressed: _loadData, label: 'RETRY'),
                ],
              ),
            );
          }

          if (state is! AnalyticsLoaded) {
            return const StateFeedback(
              icon: Icons.analytics_outlined,
              title: 'No analytics yet',
              description:
                  'Log meals and activity to unlock actionable insights.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AnalyticsBloc>().add(AnalyticsRefresh());
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Energy Overview
                  _buildEnergyOverviewCard(state),
                  const SizedBox(height: 16),

                  // Activity Breakdown
                  _buildActivityBreakdownCard(state),
                  const SizedBox(height: 16),

                  // Meal Stats
                  _buildMealStatsCard(state),
                  const SizedBox(height: 16),

                  // Goals Progress
                  _buildGoalsCard(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnergyOverviewCard(AnalyticsLoaded state) {
    final report = state.weeklyReport;
    if (report == null) {
      return const StateFeedback(
        icon: Icons.insights_rounded,
        title: 'Energy overview unavailable',
        description:
            'Add more activity and meal logs to populate this section.',
      );
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.battery_charging_full_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Energy Overview',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Avg Level',
                  '${report.avgEnergyLevel.toStringAsFixed(0)}%',
                  Icons.trending_up_rounded,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Warning Time',
                  '${(report.timeInWarning / 60).toStringAsFixed(1)}h',
                  Icons.warning_amber_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Time Optimal',
                  '${(report.timeInOptimal / 60).toStringAsFixed(1)}h',
                  Icons.check_circle_rounded,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Critical Time',
                  '${(report.timeInCritical / 60).toStringAsFixed(1)}h',
                  Icons.local_fire_department_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityBreakdownCard(AnalyticsLoaded state) {
    final activityStats = state.activityStats;
    if (activityStats == null || activityStats.activityMinutes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            'No activity data yet',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Breakdown',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          ...activityStats.activityMinutes.entries.map((entry) {
            final activityName = entry.key;
            final hours = entry.value / 60.0;
            final color = _getColorForActivity(activityName);
            return _buildActivityRow(activityName, hours, color);
          }),
        ],
      ),
    );
  }

  Color _getColorForActivity(String activityName) {
    final lower = activityName.toLowerCase();
    if (lower.contains('rest')) return AppColors.modeResting;
    if (lower.contains('cod') || lower.contains('focus')) {
      return AppColors.modeCoding;
    }
    if (lower.contains('stud')) return AppColors.modeStudying;
    if (lower.contains('gym') || lower.contains('strength')) {
      return AppColors.modeGymStrength;
    }
    if (lower.contains('cardio')) return AppColors.modeGymCardio;
    return AppColors.primaryBlue;
  }

  Widget _buildActivityRow(String name, double hours, Color color) {
    final percentage = (hours / 14 * 100).toInt();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${hours.toStringAsFixed(1)}h',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealStatsCard(AnalyticsLoaded state) {
    final mealStats = state.mealStats;
    if (mealStats == null) {
      return const StateFeedback(
        icon: Icons.restaurant_rounded,
        title: 'Meal stats unavailable',
        description:
            'Log meals consistently to get reliable nutrition patterns.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meal Statistics',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildMealStat(
                  'Total Meals',
                  '${mealStats.totalMeals}',
                  Icons.restaurant_rounded,
                ),
              ),
              Expanded(
                child: _buildMealStat(
                  'Avg Fullness',
                  '${mealStats.avgFullness.toStringAsFixed(0)}%',
                  Icons.pie_chart_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMealStat(
                  'Avg GI',
                  mealStats.avgGlycemicIndex.toStringAsFixed(0),
                  Icons.speed_rounded,
                ),
              ),
              Expanded(
                child: _buildMealStat(
                  'Per Day',
                  mealStats.mealsPerDay.toStringAsFixed(1),
                  Icons.calendar_today_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsCard(AnalyticsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Goals Progress',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              TextActionButton(
                label: 'Manage',
                onPressed: _showManageGoalsDialog,
                color: AppColors.primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (state.goals.isEmpty)
            Text(
              'No goals configured yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            )
          else
            ...state.goals.asMap().entries.map((entry) {
              final goal = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == state.goals.length - 1 ? 0 : 12,
                ),
                child: _buildGoalItem(
                  goal.activityType,
                  goal.progress.clamp(0, 1),
                  '${goal.completedMinutes}/${goal.targetMinutes} mins',
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildGoalItem(String title, double progress, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: progress >= 1.0
                    ? AppColors.success
                    : AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surfaceElevated,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? AppColors.success : AppColors.secondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Future<void> _showManageGoalsDialog() async {
    try {
      final goals = await _goalsRepository.getGoals();
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Manage Goals'),
            content: SizedBox(
              width: 420,
              child: goals.isEmpty
                  ? Text(
                      'No goals yet. Create one to start tracking progress.',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: goals
                            .map(
                              (goal) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(goal.activityType),
                                subtitle: Text(
                                  '${goal.targetMinutes} min • ${goal.period}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded),
                                      onPressed: () async {
                                        final edited = await _showGoalEditor(
                                          activityType: goal.activityType,
                                          targetMinutes: goal.targetMinutes,
                                          period: goal.period,
                                          title: 'Edit Goal',
                                        );
                                        if (edited == null) return;
                                        await _goalsRepository.updateGoal(
                                          id: goal.id,
                                          activityType: edited.$1,
                                          targetMinutes: edited.$2,
                                          period: edited.$3,
                                        );
                                        final refreshed = await _goalsRepository
                                            .getGoals();
                                        goals
                                          ..clear()
                                          ..addAll(refreshed);
                                        setDialogState(() {});
                                        _loadData();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded),
                                      color: AppColors.error,
                                      onPressed: () async {
                                        await _goalsRepository.deleteGoal(
                                          id: goal.id,
                                        );
                                        goals.removeWhere(
                                          (g) => g.id == goal.id,
                                        );
                                        setDialogState(() {});
                                        _loadData();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () async {
                  final created = await _showGoalEditor(
                    activityType: '',
                    targetMinutes: 30,
                    period: 'daily',
                    title: 'Create Goal',
                  );
                  if (created == null) return;
                  await _goalsRepository.createGoal(
                    activityType: created.$1,
                    targetMinutes: created.$2,
                    period: created.$3,
                  );
                  final refreshed = await _goalsRepository.getGoals();
                  goals
                    ..clear()
                    ..addAll(refreshed);
                  setDialogState(() {});
                  _loadData();
                },
                child: const Text('Add Goal'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to manage goals: $e')));
    }
  }

  Future<(String, int, String)?> _showGoalEditor({
    required String activityType,
    required int targetMinutes,
    required String period,
    required String title,
  }) async {
    final activityCtrl = TextEditingController(text: activityType);
    final targetCtrl = TextEditingController(text: targetMinutes.toString());
    String selectedPeriod = period;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: activityCtrl,
                decoration: const InputDecoration(labelText: 'Activity type'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target minutes'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedPeriod,
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                ],
                onChanged: (value) =>
                    setDialogState(() => selectedPeriod = value ?? 'daily'),
                decoration: const InputDecoration(labelText: 'Period'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (shouldSave != true) return null;
    final parsedTarget = int.tryParse(targetCtrl.text.trim());
    if (activityCtrl.text.trim().isEmpty ||
        parsedTarget == null ||
        parsedTarget <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter valid activity and target minutes'),
          ),
        );
      }
      return null;
    }
    return (activityCtrl.text.trim(), parsedTarget, selectedPeriod);
  }
}
