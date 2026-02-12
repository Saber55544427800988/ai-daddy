import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/token_provider.dart';
import '../providers/mission_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'spark_screen.dart';
import 'missions_screen.dart';
import 'settings_screen.dart';
import 'token_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ChatScreen(userId: widget.userId),
      SparkScreen(userId: widget.userId),
      MissionsScreen(userId: widget.userId),
      TokenScreen(userId: widget.userId),
      SettingsScreen(userId: widget.userId),
    ];

    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().init(widget.userId);
      context.read<TokenProvider>().init(widget.userId);
      context.read<MissionProvider>().init(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.navyMid,
          boxShadow: [
            BoxShadow(
              color: AppTheme.glowCyan.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.navyMid,
          selectedItemColor: AppTheme.glowCyan,
          unselectedItemColor: AppTheme.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_rounded),
              label: AppLocalizations.of(context).t('chat'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.auto_awesome_rounded),
              label: AppLocalizations.of(context).t('spark'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.flag_rounded),
              label: AppLocalizations.of(context).t('missions'),
            ),
            BottomNavigationBarItem(
              icon: Consumer<TokenProvider>(
                builder: (_, tp, __) {
                  return Stack(
                    children: [
                      const Icon(Icons.bolt_rounded),
                      if (tp.isLow)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.dangerRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              label: AppLocalizations.of(context).t('tokens'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_rounded),
              label: AppLocalizations.of(context).t('settings'),
            ),
          ],
        ),
      ),
    );
  }
}
