import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/theme.dart';
import 'presentation/blocs/fuel/fuel.dart';
import 'presentation/blocs/meal/meal.dart';
import 'router/router.dart';
import 'services/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for immersive dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0D0D12),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize notification service
  await NotificationService().initialize();
  await NotificationService().requestPermissions();

  runApp(const FuelFlowApp());
}

/// FuelFlow App - Main application widget
class FuelFlowApp extends StatelessWidget {
  const FuelFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // FuelBloc - Core energy state management
        BlocProvider<FuelBloc>(
          create: (context) => FuelBloc()..add(const FuelInitialize()),
        ),
        // MealCaptureBloc - Snap & Fuel feature
        BlocProvider<MealCaptureBloc>(
          create: (context) => MealCaptureBloc()..add(const MealCaptureInitialize()),
        ),
      ],
      child: _FuelFlowAppContent(),
    );
  }
}

class _FuelFlowAppContent extends StatefulWidget {
  @override
  State<_FuelFlowAppContent> createState() => _FuelFlowAppContentState();
}

class _FuelFlowAppContentState extends State<_FuelFlowAppContent>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final fuelBloc = context.read<FuelBloc>();

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Pause decay when app is backgrounded
        fuelBloc.add(const FuelPauseDecay());
        break;
      case AppLifecycleState.resumed:
        // Resume decay when app comes to foreground
        fuelBloc.add(const FuelResumeDecay());
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FuelBloc, FuelBlocState>(
      listenWhen: (previous, current) =>
          current.shouldTriggerCriticalNotification,
      listener: (context, state) {
        // Trigger system notification when reaching critical threshold
        NotificationService().showCriticalEnergyAlert(
          currentMode: state.currentMode.displayName,
          minutesToCrash: state.minutesToCrash,
        );
      },
      child: MaterialApp.router(
        title: 'FuelFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
