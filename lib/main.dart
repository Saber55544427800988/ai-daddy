import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

// Web database support
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize web database factory
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Notifications only on mobile
  if (!kIsWeb) {
    await NotificationService.instance.init();
  }

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
