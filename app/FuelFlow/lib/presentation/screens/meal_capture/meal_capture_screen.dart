import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  Future<void> _openCamera() async {
    if (_pickerOpened) return;
    _pickerOpened = true;
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    
    if (!mounted) return;
    
    if (photo != null) {
      context.read<MealCaptureBloc>().add(MealCaptureTakePhoto(File(photo.path)));
    } else {
      context.pop();
    }
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
              context.read<FuelBloc>().add(FuelAddMeal(
                fullnessAmount: result.estimatedFullnessPercentage,
                glycemicIndex: result.glycemicIndex,
                mealName: result.foodName,
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white),
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
          if (state.status == MealCaptureStatus.initial || state.status == MealCaptureStatus.cameraReady) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.status == MealCaptureStatus.analyzing) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
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
                  const SizedBox(height: 12),
                  Text(
                    'Powered by Gemini AI',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state.status == MealCaptureStatus.error) {
            return _buildErrorState(state.errorMessage ?? 'UNKNOWN ERROR');
          }

          if (state.status == MealCaptureStatus.analyzed && state.analysisResult != null) {
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
            child: const Icon(Icons.error_outline_rounded, size: 80, color: AppColors.error),
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
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
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
                child: Image.file(
                  state.capturedImage!,
                  fit: BoxFit.cover,
                ),
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
                const Icon(Icons.restaurant_rounded, color: Colors.white, size: 32),
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
          
          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Fullness',
                  '${result.estimatedFullnessPercentage.toInt()}%',
                  Icons.pie_chart_rounded,
                  AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'GI',
                  result.glycemicIndex.toStringAsFixed(1),
                  Icons.speed_rounded,
                  AppColors.accent,
                ),
              ),
            ],
          ),
          
          if (result.estimatedSatietyMinutes > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_rounded, color: AppColors.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Duration',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '~${result.estimatedSatietyMinutes} min at 1.0x',
                          style: const TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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
}
