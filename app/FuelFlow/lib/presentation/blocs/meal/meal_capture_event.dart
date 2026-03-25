import 'package:equatable/equatable.dart';
import 'dart:io';

/// Base class for all MealCapture events
abstract class MealCaptureEvent extends Equatable {
  const MealCaptureEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize the meal capture (e.g., request camera permissions)
class MealCaptureInitialize extends MealCaptureEvent {
  const MealCaptureInitialize();
}

/// Open the camera for capture
class MealCaptureOpenCamera extends MealCaptureEvent {
  const MealCaptureOpenCamera();
}

/// Capture an image from camera
class MealCaptureTakePhoto extends MealCaptureEvent {
  final File imageFile;

  const MealCaptureTakePhoto(this.imageFile);

  @override
  List<Object?> get props => [imageFile];
}

/// Select an image from gallery
class MealCaptureSelectFromGallery extends MealCaptureEvent {
  final File imageFile;

  const MealCaptureSelectFromGallery(this.imageFile);

  @override
  List<Object?> get props => [imageFile];
}

/// Upload image for AI analysis
class MealCaptureAnalyze extends MealCaptureEvent {
  const MealCaptureAnalyze();
}

/// Confirm the meal and add it to fuel
class MealCaptureConfirm extends MealCaptureEvent {
  const MealCaptureConfirm();
}

/// Cancel/dismiss the meal capture
class MealCaptureCancel extends MealCaptureEvent {
  const MealCaptureCancel();
}

/// Reset state for new capture
class MealCaptureReset extends MealCaptureEvent {
  const MealCaptureReset();
}

/// Retry analysis after error
class MealCaptureRetry extends MealCaptureEvent {
  const MealCaptureRetry();
}
