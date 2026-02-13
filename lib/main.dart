import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'providers/chat_provider.dart';
import 'providers/token_provider.dart';
import 'providers/mission_provider.dart';
import 'providers/locale_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/language_picker_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/in_app_notification.dart';

// Web database support — conditional import
import 'database/web_db_setup_stub.dart'
    if (dart.library.js_interop) 'database/web_db_setup.dart';

/// WorkManager background callback — runs even when app is killed.
/// This is Google's approved way to do background work (Play Store safe).
@pragma('vm:entry-point')
void _workmanagerCallback() {
  Workmanager().executeTask((task, inputData) async {
    // Re-initialize notifications in background isolate
    try {
      await NotificationService.instance.init();
    } catch (_) {}
    return true; // Task completed successfully
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize web database factory (only runs real code on web)
  try {
    setupWebDatabase();
  } catch (e) {
    debugPrint('Web database factory init error: $e');
  }

  // Initialize AndroidAlarmManager for background notification scheduling
  try {
    await AndroidAlarmManager.initialize();
  } catch (_) {}

  // Initialize notifications (no-op on web via conditional import)
  try {
    await NotificationService.instance.init();
  } catch (_) {}

  // Initialize WorkManager for background task scheduling (Play Store safe)
  try {
    await Workmanager().initialize(_workmanagerCallback, isInDebugMode: false);
    // Register periodic task — re-schedules daily reminders every 15 min
    await Workmanager().registerPeriodicTask(
      'ai_daddy_keepalive',
      'keepAliveTask',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.not_required),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  } catch (_) {}

  // Global error handler — prevents white screen on uncaught errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  // Catch uncaught async errors globally
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error');
    return true; // Handled — don't crash
  };

  runApp(const AIDaddyApp());
}

class AIDaddyApp extends StatelessWidget {
  const AIDaddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => TokenProvider()),
        ChangeNotifierProvider(create: (_) => MissionProvider()),
        ChangeNotifierProvider(create: (_) {
          final lp = LocaleProvider();
          lp.init();
          return lp;
        }),
      ],
      child: Consumer<LocaleProvider>(
        builder: (_, localeProvider, __) {
          return MaterialApp(
            navigatorKey: InAppNotification.navigatorKey,
            title: 'AI Daddy',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const AppEntryPoint(),
          );
        },
      ),
    );
  }
}

/// Shows splash screen, then decides onboarding or home
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool _splashDone = false;
  bool _languageChosen = false;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    // Check if user has already chosen a language before
    _languageChosen = _prefs!.containsKey('app_language');
    if (mounted) setState(() {});
  }

  void _onSplashFinished() {
    if (mounted) setState(() => _splashDone = true);
  }

  void _onLanguageConfirmed() {
    if (mounted) setState(() => _languageChosen = true);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Splash screen first
    if (!_splashDone) {
      return SplashScreen(onFinished: _onSplashFinished);
    }

    if (_prefs == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Language picker on first launch (no saved language yet)
    if (!_languageChosen) {
      return LanguagePickerScreen(onLanguageConfirmed: _onLanguageConfirmed);
    }

    // 3. Onboarding or Home
    final onboardingComplete =
        _prefs!.getBool('onboarding_complete') ?? false;
    final userId = _prefs!.getInt('user_id') ?? 0;

    if (onboardingComplete && userId > 0) {
      return HomeScreen(userId: userId);
    }

    return const OnboardingScreen();
  }
}
