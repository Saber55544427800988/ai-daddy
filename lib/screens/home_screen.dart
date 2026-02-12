import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/token_provider.dart';
import '../providers/mission_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'reminders_screen.dart';
import 'missions_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final GlobalKey<RemindersScreenState> _remindersKey = GlobalKey();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ChatScreen(userId: widget.userId),
      RemindersScreen(key: _remindersKey, userId: widget.userId),
      MissionsScreen(userId: widget.userId),
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
          onTap: (index) {
            setState(() => _currentIndex = index);
            // Refresh reminders when switching to Reminders tab
            if (index == 1) {
              _remindersKey.currentState?.refreshReminders();
            }
          },
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
              icon: const Icon(Icons.notifications_active_rounded),
              label: AppLocalizations.of(context).t('reminders'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.task_alt_rounded),
              label: AppLocalizations.of(context).t('dadTasks'),
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
