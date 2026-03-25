import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/repositories/meal_repository.dart';
import 'meal_capture_event.dart';
import 'meal_capture_state.dart';

/// MealCaptureBloc - Handles the "Snap & Fuel" feature
/// 
/// Responsibilities:
/// 1. Camera capture and gallery selection
/// 2. Image upload to backend for Gemini AI analysis
/// 3. Display analysis results
/// 4. Confirm meal and dispatch to FuelBloc
class MealCaptureBloc extends Bloc<MealCaptureEvent, MealCaptureState> {
  final MealRepository _mealRepository;

  MealCaptureBloc({MealRepository? mealRepository})
      : _mealRepository = mealRepository ?? MealRepositoryImpl(),
        super(MealCaptureState.initial()) {
    on<MealCaptureInitialize>(_onInitialize);
    on<MealCaptureOpenCamera>(_onOpenCamera);
    on<MealCaptureTakePhoto>(_onTakePhoto);
    on<MealCaptureSelectFromGallery>(_onSelectFromGallery);
    on<MealCaptureAnalyze>(_onAnalyze);
    on<MealCaptureConfirm>(_onConfirm);
    on<MealCaptureCancel>(_onCancel);
    on<MealCaptureReset>(_onReset);
    on<MealCaptureRetry>(_onRetry);
  }

  /// Initialize - check permissions
  Future<void> _onInitialize(
    MealCaptureInitialize event,
    Emitter<MealCaptureState> emit,
  ) async {
    emit(state.copyWith(status: MealCaptureStatus.loading));
    
    // Check camera permission
    final cameraStatus = await Permission.camera.status;
    final photosStatus = await Permission.photos.status;
    
    bool hasCameraPermission = cameraStatus.isGranted;
    bool hasPhotosPermission = photosStatus.isGranted || photosStatus.isLimited;
    
    // If not granted, request permissions
    if (!hasCameraPermission) {
      final result = await Permission.camera.request();
      hasCameraPermission = result.isGranted;
    }
    
    if (!hasPhotosPermission) {
      final result = await Permission.photos.request();
      hasPhotosPermission = result.isGranted || result.isLimited;
    }
    
    emit(state.copyWith(
      hasCameraPermission: hasCameraPermission,
      hasPhotosPermission: hasPhotosPermission,
      status: MealCaptureStatus.initial,
      permissionDenied: !hasCameraPermission && !hasPhotosPermission,
    ));
  }

  /// Open camera overlay
  void _onOpenCamera(
    MealCaptureOpenCamera event,
    Emitter<MealCaptureState> emit,
  ) {
    emit(state.copyWith(
      isOverlayVisible: true,
      status: MealCaptureStatus.cameraReady,
      clearImage: true,
      clearAnalysis: true,
      clearError: true,
    ));
  }

  /// Handle photo capture
  void _onTakePhoto(
    MealCaptureTakePhoto event,
    Emitter<MealCaptureState> emit,
  ) {
    emit(state.copyWith(
      capturedImage: event.imageFile,
      status: MealCaptureStatus.captured,
    ));

    // Auto-trigger analysis
    add(const MealCaptureAnalyze());
  }

  /// Handle gallery selection
  void _onSelectFromGallery(
    MealCaptureSelectFromGallery event,
    Emitter<MealCaptureState> emit,
  ) {
    emit(state.copyWith(
      capturedImage: event.imageFile,
      status: MealCaptureStatus.captured,
      isOverlayVisible: true,
    ));

    // Auto-trigger analysis
    add(const MealCaptureAnalyze());
  }

  /// Analyze the captured image using Gemini AI (POST /meals/snap)
  Future<void> _onAnalyze(
    MealCaptureAnalyze event,
    Emitter<MealCaptureState> emit,
  ) async {
    if (state.capturedImage == null) {
      emit(state.copyWith(
        status: MealCaptureStatus.error,
        errorMessage: 'No image to analyze',
      ));
      return;
    }

    emit(state.copyWith(status: MealCaptureStatus.analyzing));

    try {
      final result = await _mealRepository.analyzeImage(state.capturedImage!);
      emit(state.copyWith(
        analysisResult: result,
        status: MealCaptureStatus.analyzed,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MealCaptureStatus.error,
        errorMessage: 'Failed to analyze image: $e',
      ));
    }
  }

  /// Confirm meal and prepare for FuelBloc integration
  void _onConfirm(
    MealCaptureConfirm event,
    Emitter<MealCaptureState> emit,
  ) {
    if (!state.canConfirm) {
      emit(state.copyWith(
        status: MealCaptureStatus.error,
        errorMessage: 'Cannot confirm meal without analysis',
      ));
      return;
    }

    emit(state.copyWith(
      status: MealCaptureStatus.confirmed,
      isOverlayVisible: false,
    ));

    // Note: The actual FuelBloc.add(FuelAddMeal(...)) will be called
    // from the UI layer using a BlocListener
  }

  /// Cancel the capture process
  void _onCancel(
    MealCaptureCancel event,
    Emitter<MealCaptureState> emit,
  ) {
    emit(state.copyWith(
      status: MealCaptureStatus.initial,
      isOverlayVisible: false,
      clearImage: true,
      clearAnalysis: true,
      clearError: true,
    ));
  }

  /// Reset for new capture
  void _onReset(
    MealCaptureReset event,
    Emitter<MealCaptureState> emit,
  ) {
    emit(MealCaptureState.initial());
  }

  /// Retry analysis after error
  void _onRetry(
    MealCaptureRetry event,
    Emitter<MealCaptureState> emit,
  ) {
    if (state.capturedImage != null) {
      add(const MealCaptureAnalyze());
    } else {
      emit(state.copyWith(
        status: MealCaptureStatus.cameraReady,
        clearError: true,
      ));
    }
  }
}
