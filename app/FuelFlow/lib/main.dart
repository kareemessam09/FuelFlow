import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/theme/theme.dart';
import 'data/datasources/local/activity_adapter.dart';
import 'data/datasources/local/fuel_state_adapter.dart';
import 'data/datasources/local/meal_adapter.dart';
import 'data/datasources/local/user_adapter.dart';
import 'data/repositories/auth_repository.dart';
import 'presentation/blocs/auth/auth.dart';
import 'presentation/blocs/fuel/fuel.dart';
import 'presentation/blocs/meal/meal.dart';
import 'router/router.dart';
import 'services/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data for scheduled notifications
  tz.initializeTimeZones();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive for local persistence
  await Hive.initFlutter();

  // Register all TypeAdapters
  Hive.registerAdapter(ActivityModeAdapter());
  Hive.registerAdapter(ActivityLogAdapterAdapter()); // Generated adapter
  Hive.registerAdapter(AbsorptionProfileAdapter());
  Hive.registerAdapter(MealLogAdapterAdapter()); // Generated adapter
  Hive.registerAdapter(FuelStateAdapterAdapter()); // Generated adapter
  Hive.registerAdapter(UserAdapterAdapter()); // Generated adapter
  Hive.registerAdapter(SensitivityLevelAdapter());
  Hive.registerAdapter(TargetGoalAdapter());

  // Open required boxes
  await Hive.openBox('fuelState');
  await Hive.openBox('user');
  await Hive.openBox('meals');
  await Hive.openBox('activities');

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

  // Initialize AuthService (token persistence)
  await AuthService().init();

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
        // AuthBloc - Handles registration, login, and session persistence
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: AuthRepositoryImpl(),
          )..add(const AuthCheckStatus()),
        ),
        // FuelBloc - Core energy state management
        BlocProvider<FuelBloc>(
          create: (context) => FuelBloc()..add(const FuelInitialize()),
        ),
        // MealCaptureBloc - Snap & Fuel feature
        BlocProvider<MealCaptureBloc>(
          create: (context) =>
              MealCaptureBloc()..add(const MealCaptureInitialize()),
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
    
    // Set up notification tap handler for navigation
    NotificationService().onNotificationTap = _handleNotificationTap;
  }
  
  void _handleNotificationTap(NotificationAction action) {
    // Use the router to navigate based on the notification action
    switch (action) {
      case NotificationAction.openMealCapture:
        AppRouter.router.go('/meal-capture');
        break;
      case NotificationAction.openDashboard:
        AppRouter.router.go('/');
        break;
      case NotificationAction.none:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService().onNotificationTap = null;
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
