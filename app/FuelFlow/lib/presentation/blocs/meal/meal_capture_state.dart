import 'package:equatable/equatable.dart';
import 'dart:io';
import '../../../domain/entities/entities.dart';

/// State for MealCapture bloc
class MealCaptureState extends Equatable {
  /// Current status
  final MealCaptureStatus status;

  /// Captured image file
  final File? capturedImage;

  /// Analysis result from Gemini AI
  final MealAnalysisResult? analysisResult;

  /// Error message if any
  final String? errorMessage;

  /// Whether camera permission is granted
  final bool hasCameraPermission;

  /// Whether the capture overlay is visible
  final bool isOverlayVisible;

  const MealCaptureState({
    this.status = MealCaptureStatus.initial,
    this.capturedImage,
    this.analysisResult,
    this.errorMessage,
    this.hasCameraPermission = false,
    this.isOverlayVisible = false,
  });

  /// Factory for initial state
  factory MealCaptureState.initial() {
    return const MealCaptureState();
  }

  /// Check if we have an image ready for analysis
  bool get hasImage => capturedImage != null;

  /// Check if analysis is complete
  bool get hasAnalysis => analysisResult != null;

  /// Check if we can confirm the meal
  bool get canConfirm => hasImage && hasAnalysis && status == MealCaptureStatus.analyzed;

  MealCaptureState copyWith({
    MealCaptureStatus? status,
    File? capturedImage,
    MealAnalysisResult? analysisResult,
    String? errorMessage,
    bool? hasCameraPermission,
    bool? isOverlayVisible,
    bool clearImage = false,
    bool clearAnalysis = false,
    bool clearError = false,
  }) {
    return MealCaptureState(
      status: status ?? this.status,
      capturedImage: clearImage ? null : (capturedImage ?? this.capturedImage),
      analysisResult: clearAnalysis ? null : (analysisResult ?? this.analysisResult),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasCameraPermission: hasCameraPermission ?? this.hasCameraPermission,
      isOverlayVisible: isOverlayVisible ?? this.isOverlayVisible,
    );
  }

  @override
  List<Object?> get props => [
        status,
        capturedImage,
        analysisResult,
        errorMessage,
        hasCameraPermission,
        isOverlayVisible,
      ];
}

/// Status enum for MealCapture
enum MealCaptureStatus {
  /// Initial state
  initial,

  /// Camera is open and ready
  cameraReady,

  /// Image has been captured, waiting for analysis
  captured,

  /// Image is being analyzed by Gemini AI
  analyzing,

  /// Analysis complete, showing results
  analyzed,

  /// Meal confirmed and added to fuel
  confirmed,

  /// Error state
  error,
}
