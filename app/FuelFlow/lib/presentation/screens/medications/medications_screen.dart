import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/medication_models.dart';
import '../../blocs/medication/medication.dart';
import '../../widgets/common/common.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<MedicationBloc>().add(const MedicationLoadAll());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MEDICATIONS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<MedicationBloc>().add(const MedicationRefresh());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'MY MEDS'),
            Tab(text: 'TODAY LOGS'),
          ],
        ),
      ),
      body: BlocConsumer<MedicationBloc, MedicationState>(
        listener: (context, state) {
          if (state is MedicationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is MedicationLoaded && state.statusMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.statusMessage!),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MedicationLoading) {
            return const StateFeedback(
              icon: Icons.medication_rounded,
              title: 'Loading medications',
              description: 'Fetching your medication plan and today logs.',
            );
          }

          if (state is MedicationLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildMedicationsTab(state),
                _buildTodayLogsTab(state),
              ],
            );
          }

          if (state is MedicationError) {
            return _buildErrorState(state.message);
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMedicationDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('ADD MED'),
      ),
    );
  }

  Widget _buildMedicationsTab(MedicationLoaded state) {
    if (state.medications.isEmpty) {
      return StateFeedback(
        icon: Icons.medication_rounded,
        title: 'No medications yet',
        description: 'Create your first medication to enable meal-safety checks.',
        actionLabel: 'ADD FIRST MEDICATION',
        onAction: _openAddMedicationDialog,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.medications.length,
      itemBuilder: (context, index) {
        final medication = state.medications[index];
        final isTakenToday = state.todayLogs
            .any((log) => log.medicationId == medication.id);

        return _buildMedicationCard(
          medication: medication,
          isTakenToday: isTakenToday,
        );
      },
    );
  }

  Widget _buildTodayLogsTab(MedicationLoaded state) {
    if (state.todayLogs.isEmpty) {
      return const StateFeedback(
        icon: Icons.checklist_rounded,
        title: 'No logs today',
        description: 'Medication logs will appear here once you mark doses as taken.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.todayLogs.length,
      itemBuilder: (context, index) {
        final log = state.todayLogs[index];
        final name = log.medication?.name ?? 'Medication #${log.medicationId}';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatLogTime(log.takenAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicationCard({
    required Medication medication,
    required bool isTakenToday,
  }) {
    final timingColor =
        medication.timing == 'before' ? AppColors.primary : AppColors.primaryBlue;
    final timingLabel =
        medication.timing == 'before' ? 'BEFORE ${medication.mealType.toUpperCase()}' : 'AFTER ${medication.mealType.toUpperCase()}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  medication.name,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: timingColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timingLabel,
                  style: TextStyle(
                    color: timingColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (medication.dosage?.trim().isNotEmpty == true)
            Text(
              'Dosage: ${medication.dosage}',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          if (medication.notes?.trim().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                medication.notes!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: BrutalButton(
                  label: isTakenToday ? 'TAKEN TODAY' : 'MARK AS TAKEN',
                  icon: isTakenToday
                      ? Icons.check_rounded
                      : Icons.medication_rounded,
                  isPrimary: !isTakenToday,
                  onPressed: isTakenToday
                      ? () {}
                      : () {
                          context.read<MedicationBloc>().add(
                                MedicationLogTakenRequested(
                                  medication: medication,
                                ),
                              );
                        },
                ),
              ),
              const SizedBox(width: 8),
              BrutalIconButton(
                icon: Icons.edit_rounded,
                tooltip: 'Edit',
                onPressed: () => _openEditMedicationDialog(medication),
              ),
              const SizedBox(width: 8),
              BrutalIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete',
                color: AppColors.error.withValues(alpha: 0.2),
                onPressed: () => _confirmDeleteMedication(medication),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return StateFeedback(
      icon: Icons.error_outline_rounded,
      title: 'Failed to load medications',
      description: message,
      actionLabel: 'RETRY',
      onAction: () {
        context.read<MedicationBloc>().add(const MedicationLoadAll());
      },
    );
  }

  String _formatLogTime(DateTime dateTime) {
    final now = DateTime.now();
    final delta = now.difference(dateTime);
    if (delta.inMinutes < 60) {
      return '${delta.inMinutes}m ago';
    }
    if (delta.inHours < 24) {
      return '${delta.inHours}h ago';
    }
    return '${delta.inDays}d ago';
  }

  void _openAddMedicationDialog() {
    _showMedicationFormDialog();
  }

  void _openEditMedicationDialog(Medication medication) {
    _showMedicationFormDialog(existing: medication);
  }

  void _showMedicationFormDialog({Medication? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final dosageController = TextEditingController(text: existing?.dosage ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    String timing = existing?.timing ?? 'before';
    String mealType = existing?.mealType ?? 'any';
    bool reminderEnabled = existing?.reminderEnabled ?? true;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(existing == null ? 'Add Medication' : 'Edit Medication'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dosageController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Dosage (optional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: timing,
                      items: const [
                        DropdownMenuItem(value: 'before', child: Text('Before meal')),
                        DropdownMenuItem(value: 'after', child: Text('After meal')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => timing = value);
                      },
                      decoration: const InputDecoration(labelText: 'Timing'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: mealType,
                      items: const [
                        DropdownMenuItem(value: 'any', child: Text('Any meal')),
                        DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                        DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                        DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => mealType = value);
                      },
                      decoration: const InputDecoration(labelText: 'Meal type'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: reminderEnabled,
                      onChanged: (value) {
                        setDialogState(() => reminderEnabled = value);
                      },
                      title: const Text('Enable reminders'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final now = DateTime.now();

                    final model = Medication(
                      id: existing?.id ?? '0',
                      userId: existing?.userId ?? '',
                      name: name,
                      timing: timing,
                      mealType: mealType,
                      dosage: dosageController.text.trim().isEmpty
                          ? null
                          : dosageController.text.trim(),
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                      reminderEnabled: reminderEnabled,
                      createdAt: existing?.createdAt ?? now,
                      updatedAt: now,
                    );

                    if (existing == null) {
                      context.read<MedicationBloc>().add(
                            MedicationCreateRequested(model),
                          );
                    } else {
                      context.read<MedicationBloc>().add(
                            MedicationUpdateRequested(
                              id: existing.id,
                              medication: model,
                            ),
                          );
                    }

                    Navigator.of(context).pop();
                  },
                  child: Text(existing == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteMedication(Medication medication) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Delete medication?'),
          content: Text('Delete ${medication.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context
                    .read<MedicationBloc>()
                    .add(MedicationDeleteRequested(medication.id));
                Navigator.of(context).pop();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}
