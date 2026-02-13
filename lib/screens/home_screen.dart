import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/token_provider.dart';
import '../providers/mission_provider.dart';
import '../services/notification_service.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<ChatProvider>().init(widget.userId);
      } catch (e) {
        debugPrint('ChatProvider init error: $e');
      }
      try {
        await context.read<TokenProvider>().init(widget.userId);
      } catch (e) {
        debugPrint('TokenProvider init error: $e');
      }
      try {
        await context.read<MissionProvider>().init(widget.userId);
      } catch (e) {
        debugPrint('MissionProvider init error: $e');
      }

      // Test notification — fires 5 seconds after app opens to verify system works
      Future.delayed(const Duration(seconds: 5), () {
        NotificationService.instance.showNotification(
          id: 9999,
          title: 'AI Daddy',
          body: 'Notifications are working! You will receive reminders here.',
        );
      });
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
