import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/medication_models.dart';
import '../../../data/repositories/medication_repository.dart';
import '../../../core/constants/app_colors.dart';
import '../../blocs/meal/meal.dart';
import '../../blocs/fuel/fuel.dart';
import '../../widgets/common/common.dart';

class MealCaptureScreen extends StatefulWidget {
  const MealCaptureScreen({super.key});

  @override
  State<MealCaptureScreen> createState() => _MealCaptureScreenState();
}

class _MealCaptureScreenState extends State<MealCaptureScreen> {
  bool _pickerOpened = false;
  bool _beforeMealValidated = false;
  bool _isCheckingMeds = false;
  final MedicationRepository _medicationRepository = MedicationRepositoryImpl();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  Future<void> _openCamera() async {
    if (_pickerOpened || _isCheckingMeds) return;
    if (!_beforeMealValidated) {
      await _ensureBeforeMealMedsTaken();
      if (!_beforeMealValidated || !mounted) {
        return;
      }
    }
    _pickerOpened = true;
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (!mounted) return;

    if (photo != null) {
      context.read<MealCaptureBloc>().add(
        MealCaptureTakePhoto(File(photo.path)),
      );
    } else {
      context.pop();
    }
  }

  Future<void> _ensureBeforeMealMedsTaken() async {
    setState(() => _isCheckingMeds = true);
    try {
      final check = await _medicationRepository.checkBeforeMeal(
        mealType: _inferMealType(DateTime.now()),
      );
      if (!mounted) return;

      if (!check.hasRequiredMedications || check.medications.isEmpty) {
        _beforeMealValidated = true;
        return;
      }

      final allowed = await _showBeforeMealMedicationDialog(check);
      if (!mounted) return;
      if (!allowed) {
        context.pop();
        return;
      }

      _beforeMealValidated = true;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Medication check failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
      context.pop();
    } finally {
      if (mounted) {
        setState(() => _isCheckingMeds = false);
      }
    }
  }

  Future<bool> _showBeforeMealMedicationDialog(
    BeforeMealCheckResult check,
  ) async {
    final toTake = Set<String>.from(
      check.medications.map((medication) => medication.id),
    );
    final taken = <String>{};
    final now = DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final allChecked = taken.length == toTake.length;

            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Take medications first'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      check.message,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ...check.medications.map((medication) {
                      final id = medication.id;
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: taken.contains(id),
                        title: Text(
                          medication.name,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                        subtitle: medication.dosage == null
                            ? null
                            : Text(
                                medication.dosage!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                        onChanged: (value) {
                          if (value == true) {
                            taken.add(id);
                          } else {
                            taken.remove(id);
                          }
                          setDialogState(() {});
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: allChecked
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  child: const Text('Confirm & Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      return false;
    }

    for (final medication in check.medications) {
      if (!taken.contains(medication.id)) continue;

      final log = MedicationLog(
        id: '0',
        userId: medication.userId,
        medicationId: medication.id,
        takenAt: now,
        notes: 'Confirmed before meal logging in app',
      );
      await _medicationRepository.logMedication(log);
    }

    return true;
  }

  String _inferMealType(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 11) return 'breakfast';
    if (hour >= 11 && hour < 16) return 'lunch';
    if (hour >= 16 && hour < 23) return 'dinner';
    return 'any';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SNAP & FUEL'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            context.read<MealCaptureBloc>().add(const MealCaptureCancel());
            context.pop();
          },
        ),
      ),
      body: BlocConsumer<MealCaptureBloc, MealCaptureState>(
        listener: (context, state) {
          if (state.status == MealCaptureStatus.confirmed) {
            final result = state.analysisResult;
            if (result != null) {
              context.read<FuelBloc>().add(
                FuelAddMeal(
                  fullnessAmount: result.estimatedFullnessPercentage,
                  glycemicIndex: result.glycemicIndex,
                  mealName: result.foodName,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'FUEL DEPLOYED!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            context.pop();
          }
        },
        builder: (context, state) {
          if (_isCheckingMeds) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == MealCaptureStatus.initial ||
              state.status == MealCaptureStatus.cameraReady) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == MealCaptureStatus.analyzing) {
            return _ScanningOverlay(image: state.capturedImage);
          }

          if (state.status == MealCaptureStatus.error) {
            return _buildErrorState(
              state.errorMessage ??
                  'Could not analyze this meal. Try better lighting or retake the photo.',
            );
          }

          if (state.status == MealCaptureStatus.analyzed &&
              state.analysisResult != null) {
            return _buildAnalysisResult(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'ANALYSIS FAILED',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 48),
          BrutalButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: () {
              _pickerOpened = false;
              _openCamera();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult(MealCaptureState state) {
    final result = state.analysisResult!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image Preview
          if (state.capturedImage != null)
            Container(
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(state.capturedImage!, fit: BoxFit.cover),
              ),
            ),
          const SizedBox(height: 32),

          // Food Name
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.restaurant_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  result.foodName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Energy metrics card
          GlassCard(
            borderColor: AppColors.border,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ENERGY METRICS',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.pie_chart_rounded,
                        label: 'Fullness',
                        value: '${result.estimatedFullnessPercentage.toInt()}%',
                        color: AppColors.secondary,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: AppColors.border,
                    ),
                    Expanded(
                      child: _buildMetricTile(
                        icon: Icons.speed_rounded,
                        label: 'GI',
                        value: result.glycemicIndex.toStringAsFixed(1),
                        color: AppColors.accent,
                      ),
                    ),
                    if (result.estimatedSatietyMinutes > 0) ...[
                      Container(
                        width: 1,
                        height: 48,
                        color: AppColors.border,
                      ),
                      Expanded(
                        child: _buildMetricTile(
                          icon: Icons.timer_rounded,
                          label: 'Duration',
                          value: '${result.estimatedSatietyMinutes}m',
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          BrutalButton(
            label: 'Confirm',
            icon: Icons.check_rounded,
            height: 60,
            onPressed: () {
              context.read<MealCaptureBloc>().add(const MealCaptureConfirm());
            },
          ),
          const SizedBox(height: 12),
          OutlineButton(
            label: 'Retake',
            icon: Icons.camera_alt_rounded,
            color: AppColors.primaryBlue,
            onPressed: () {
              _pickerOpened = false;
              context.read<MealCaptureBloc>().add(const MealCaptureReset());
              _openCamera();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Animated scanning overlay shown during AI analysis.
class _ScanningOverlay extends StatefulWidget {
  final File? image;
  const _ScanningOverlay({this.image});

  @override
  State<_ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<_ScanningOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _pulseController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _scanAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview with scan line
            if (widget.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(widget.image!, fit: BoxFit.cover),
                      // Dark tinted overlay
                      Container(
                        color: AppColors.background.withValues(alpha: 0.55),
                      ),
                      // Scan line
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Align(
                              alignment: Alignment(0, _scanAnimation.value),
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.primaryBlue,
                                      AppColors.primaryBlue,
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withValues(alpha: 0.6),
                                      blurRadius: 16,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Corner brackets
                      ..._buildCornerBrackets(),
                    ],
                  ),
                ),
              )
            else
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.4),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 36),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: const Text(
                    'ANALYZING NUTRITION',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Estimating nutrition profile...',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primaryBlue),
                  minHeight: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerBrackets() {
    const size = 24.0;
    const thickness = 2.5;
    const color = AppColors.primaryBlue;
    const offset = 8.0;

    Widget bracket(Alignment alignment, {bool flipH = false, bool flipV = false}) {
      return Positioned(
        top: alignment == Alignment.topLeft || alignment == Alignment.topRight ? offset : null,
        bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? offset : null,
        left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? offset : null,
        right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? offset : null,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            flipH ? -1.0 : 1.0,
            flipV ? -1.0 : 1.0,
            1.0,
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(painter: _BracketPainter(color: color, strokeWidth: thickness)),
          ),
        ),
      );
    }

    return [
      bracket(Alignment.topLeft),
      bracket(Alignment.topRight, flipH: true),
      bracket(Alignment.bottomLeft, flipV: true),
      bracket(Alignment.bottomRight, flipH: true, flipV: true),
    ];
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _BracketPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.4), Offset.zero, paint);
    canvas.drawLine(Offset.zero, Offset(size.width * 0.4, 0), paint);
  }

  @override
  bool shouldRepaint(covariant _BracketPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
