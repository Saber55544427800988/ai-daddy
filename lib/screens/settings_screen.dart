import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../providers/chat_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../screens/analytics_dashboard_screen.dart';
import '../screens/memory_vault_screen.dart';
import '../screens/goal_tracking_screen.dart';
import '../screens/habit_screen.dart';
import '../screens/dad_report_screen.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final int userId;
  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _user;
  String _personality = 'caring';
  double _checkInHours = 6;
  bool _notificationsEnabled = true;
  bool _autoReadEnabled = true;
  bool _privacyMode = false;
  String _voiceStyle = 'warm';

  // Custom personality sliders
  double _strictness = 0.5;
  double _playfulness = 0.5;
  double _mentoring = 0.5;
  bool _selfLearningEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = await DatabaseHelper.instance.getUser(widget.userId);
    final prefs = await SharedPreferences.getInstance();
    if (user != null) {
      setState(() {
        _user = user;
        _personality = user.dadPersonality;
        _checkInHours = prefs.getDouble('check_in_hours') ?? 6;
        _notificationsEnabled =
            prefs.getBool('notifications_enabled') ?? true;
        _autoReadEnabled = prefs.getBool('auto_read_enabled') ?? true;
        _selfLearningEnabled =
            prefs.getBool('self_learning_enabled') ?? true;
        _privacyMode = prefs.getBool('privacy_mode') ?? false;
        _voiceStyle = prefs.getString('voice_style') ?? 'warm';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: _user == null
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.glowCyan))
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    title: Text(AppLocalizations.of(context).t('settings')),
                    automaticallyImplyLeading: false,
                    pinned: true,
                    backgroundColor: AppTheme.navyMid,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                  // Profile card
                  _buildProfileCard(),
                  const SizedBox(height: 20),

                  // Language
                  _buildSectionTitle(AppLocalizations.of(context).t('language')),
                  _buildLanguagePicker(),
                  const SizedBox(height: 20),

                  // Personality
                  _buildSectionTitle(AppLocalizations.of(context).t('personality')),
                  _buildPersonalitySelector(),
                  const SizedBox(height: 20),

                  // Custom sliders
                  _buildSectionTitle(AppLocalizations.of(context).t('customPersonality')),
                  _buildSlider(AppLocalizations.of(context).t('strictGentle'), _strictness, (v) {
                    setState(() => _strictness = v);
                  }),
                  _buildSlider(AppLocalizations.of(context).t('playfulSerious'), _playfulness, (v) {
                    setState(() => _playfulness = v);
                  }),
                  _buildSlider(AppLocalizations.of(context).t('mentorFriend'), _mentoring, (v) {
                    setState(() => _mentoring = v);
                  }),
                  const SizedBox(height: 20),

                  // Notifications
                  _buildSectionTitle(AppLocalizations.of(context).t('notificationsVoice')),
                  _buildToggle(
                    AppLocalizations.of(context).t('dailyReminders'),
                    AppLocalizations.of(context).t('dailyRemindersDesc'),
                    _notificationsEnabled,
                    (v) async {
                      setState(() => _notificationsEnabled = v);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('notifications_enabled', v);
                      if (!kIsWeb) {
                        if (v) {
                          await NotificationService.instance
                              .scheduleDailyReminders(
                            _user!.nickname,
                            ReminderModel.defaultReminderTexts(_user!.nickname),
                          );
                        } else {
                          await NotificationService.instance.cancelAll();
                        }
                      }
                    },
                  ),
                  _buildToggle(
                    AppLocalizations.of(context).t('autoReadVoice'),
                    AppLocalizations.of(context).t('autoReadVoiceDesc'),
                    _autoReadEnabled,
                    (v) async {
                      setState(() => _autoReadEnabled = v);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('auto_read_enabled', v);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Check-in frequency
                  _buildSectionTitle(AppLocalizations.of(context).t('checkInFrequency')),
                  _buildCheckInSlider(),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: Text(AppLocalizations.of(context).t('saveSettings')),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Feature shortcuts
                  _buildSectionTitle(AppLocalizations.of(context).t('advancedFeatures')),
                  _buildNavTile(
                    icon: Icons.analytics_rounded,
                    title: AppLocalizations.of(context).t('analyticsDashboard'),
                    subtitle: AppLocalizations.of(context).t('analyticsDesc'),
                    color: AppTheme.glowCyan,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen())),
                  ),
                  _buildNavTile(
                    icon: Icons.psychology_rounded,
                    title: AppLocalizations.of(context).t('memoryVault'),
                    subtitle: AppLocalizations.of(context).t('memoryVaultDesc'),
                    color: AppTheme.accentBlue,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MemoryVaultScreen())),
                  ),
                  _buildNavTile(
                    icon: Icons.flag_rounded,
                    title: AppLocalizations.of(context).t('goalTracking'),
                    subtitle: AppLocalizations.of(context).t('goalTrackingDesc'),
                    color: Colors.amber,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const GoalTrackingScreen())),
                  ),
                  _buildNavTile(
                    icon: Icons.repeat_rounded,
                    title: AppLocalizations.of(context).t('habitBuilder'),
                    subtitle: AppLocalizations.of(context).t('habitBuilderDesc'),
                    color: Colors.greenAccent,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HabitScreen())),
                  ),
                  _buildNavTile(
                    icon: Icons.assessment_rounded,
                    title: AppLocalizations.of(context).t('weeklyReports'),
                    subtitle: AppLocalizations.of(context).t('weeklyReportsDesc'),
                    color: Colors.pinkAccent,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const DadReportScreen())),
                  ),
                  const SizedBox(height: 20),

                  // Voice Personalization
                  _buildSectionTitle(AppLocalizations.of(context).t('voicePersonalization')),
                  _buildVoiceSelector(),
                  const SizedBox(height: 20),

                  // Premium teaser
                  _buildPremiumTeaser(),
                  const SizedBox(height: 20),

                  // Data & Privacy
                  _buildSectionTitle(AppLocalizations.of(context).t('dataPrivacy')),
                  _buildToggle(
                    AppLocalizations.of(context).t('privacyMode'),
                    AppLocalizations.of(context).t('privacyModeDesc'),
                    _privacyMode,
                    (v) async {
                      final chatProvider = context.read<ChatProvider>();
                      setState(() => _privacyMode = v);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('privacy_mode', v);
                      chatProvider.setPrivacyMode(v);
                    },
                  ),
                  _buildToggle(
                    AppLocalizations.of(context).t('selfLearning'),
                    AppLocalizations.of(context).t('selfLearningDesc'),
                    _selfLearningEnabled,
                    (v) async {
                      setState(() => _selfLearningEnabled = v);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('self_learning_enabled', v);
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.psychology_alt_rounded,
                    title: AppLocalizations.of(context).t('wipeMemory'),
                    subtitle: AppLocalizations.of(context).t('wipeMemoryDesc'),
                    color: Colors.deepOrangeAccent,
                    onTap: () => _confirmWipeMemories(context),
                  ),
                  _buildActionTile(
                    icon: Icons.delete_sweep_rounded,
                    title: AppLocalizations.of(context).t('clearChat'),
                    subtitle: AppLocalizations.of(context).t('clearChatDesc'),
                    color: AppTheme.dangerRed,
                    onTap: () => _confirmClearChat(context),
                  ),
                  _buildActionTile(
                    icon: Icons.restart_alt_rounded,
                    title: AppLocalizations.of(context).t('resetProfile'),
                    subtitle: AppLocalizations.of(context).t('resetProfileDesc'),
                    color: AppTheme.warmOrange,
                    onTap: () => _confirmResetProfile(context),
                  ),
                  const SizedBox(height: 20),

                  // About
                  _buildSectionTitle(AppLocalizations.of(context).t('about')),
                  _buildInfoTile(
                    icon: Icons.info_outline_rounded,
                    title: AppLocalizations.of(context).t('appVersion'),
                    value: '1.0.0',
                  ),
                  _buildInfoTile(
                    icon: Icons.smart_toy_rounded,
                    title: AppLocalizations.of(context).t('aiEngine'),
                    value: 'LongCat AI',
                  ),
                  _buildInfoTile(
                    icon: Icons.person_rounded,
                    title: AppLocalizations.of(context).t('imYourDaddy'),
                    value: AppLocalizations.of(context).t('alwaysHere'),
                  ),
                  const SizedBox(height: 20),

                  // Powered by
                  Center(
                    child: Column(
                      children: [
                        Text(
                          AppLocalizations.of(context).t('poweredBy'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context).t('madeWithLove'),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
      );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glowCyan.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.glowGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.glowCyan.withOpacity(0.25),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _user!.nickname.isNotEmpty
                    ? _user!.nickname[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user!.nickname,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${AppLocalizations.of(context).t('personality')}: ${AppLocalizations.of(context).t(_personality)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.white,
        ),
      ),
    );
  }

  Widget _buildLanguagePicker() {
    final localeProvider = context.watch<LocaleProvider>();
    final currentLang = localeProvider.locale.languageCode;
    final flag = AppLocalizations.languageFlags[currentLang] ?? '🌐';
    final name = AppLocalizations.languageNames[currentLang] ?? 'English';

    return GestureDetector(
      onTap: () => _showLanguageSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.navyCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.glowCyan.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.white)),
                  Text(AppLocalizations.of(context).t('languageDesc'),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.glowCyan, size: 22),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    final currentLang = localeProvider.locale.languageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navyMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).t('language'),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: AppLocalizations.supportedLocales.length,
                itemBuilder: (ctx, i) {
                  final locale = AppLocalizations.supportedLocales[i];
                  final code = locale.languageCode;
                  final flag = AppLocalizations.languageFlags[code] ?? '🌐';
                  final name = AppLocalizations.languageNames[code] ?? code;
                  final isSelected = code == currentLang;

                  return ListTile(
                    leading: Text(flag, style: const TextStyle(fontSize: 28)),
                    title: Text(name,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.glowCyan
                              : AppTheme.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        )),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppTheme.glowCyan)
                        : null,
                    onTap: () {
                      localeProvider.setLocale(code);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalitySelector() {
    final personalities = ['caring', 'strict', 'playful', 'motivational'];
    final icons = [
      Icons.favorite, Icons.gavel, Icons.emoji_emotions, Icons.rocket_launch
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(personalities.length, (i) {
        final isSelected = _personality == personalities[i];
        return GestureDetector(
          onTap: () => setState(() => _personality = personalities[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.glowCyan.withOpacity(0.12)
                  : AppTheme.navyCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.glowCyan : AppTheme.navySurface,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icons[i],
                    size: 18,
                    color:
                        isSelected ? AppTheme.glowCyan : AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context).t(personalities[i]),
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color:
                        isSelected ? AppTheme.glowCyan : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            )),
        Slider(
          value: value,
          min: 0,
          max: 1,
          divisions: 10,
          activeColor: AppTheme.glowCyan,
          inactiveColor: AppTheme.navySurface,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.white)),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    )),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppTheme.glowCyan,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context).t('every'), style: const TextStyle(fontSize: 14)),
              Text(
                '${_checkInHours.round()} ${AppLocalizations.of(context).t('hours')}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.glowCyan,
                ),
              ),
            ],
          ),
          Slider(
            value: _checkInHours,
            min: 1,
            max: 24,
            divisions: 23,
            activeColor: AppTheme.glowCyan,
            inactiveColor: AppTheme.navySurface,
            label: '${_checkInHours.round()}h',
            onChanged: (v) => setState(() => _checkInHours = v),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final updatedUser = _user!.copyWith(dadPersonality: _personality);
    await DatabaseHelper.instance.updateUser(updatedUser);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('check_in_hours', _checkInHours);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('settingsSaved')),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  Widget _buildPremiumTeaser() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2A4A), Color(0xFF0F1E38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.tokenGold.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.tokenGold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: AppTheme.tokenGold, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).t('premiumPlan'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.tokenGold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.warmOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppLocalizations.of(context).t('comingSoon'),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warmOrange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            AppLocalizations.of(context).t('premiumDesc'),
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: color,
                          )),
                      Text(subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          )),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: color.withOpacity(0.5), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.glowCyan, size: 20),
          const SizedBox(width: 14),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.white)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              )),
        ],
      ),
    );
  }

  Widget _buildVoiceSelector() {
    final l = AppLocalizations.of(context);
    final voices = {
      'warm': l.t('warmCalm'),
      'energetic': l.t('energetic'),
      'deep': l.t('deepSteady'),
      'gentle': l.t('gentleSoft'),
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: voices.entries.map((e) {
        final isSelected = _voiceStyle == e.key;
        return GestureDetector(
          onTap: () async {
            setState(() => _voiceStyle = e.key);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('voice_style', e.key);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.glowCyan.withOpacity(0.12)
                  : AppTheme.navyCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.glowCyan : AppTheme.navySurface,
              ),
            ),
            child: Text(e.value,
                style: TextStyle(
                  color: isSelected ? AppTheme.glowCyan : Colors.white70,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                )),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.white,
                          )),
                      Text(subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          )),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: color.withOpacity(0.5), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmWipeMemories(BuildContext context) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.t('wipeMemoryTitle'),
            style: const TextStyle(color: AppTheme.white)),
        content: Text(
          l.t('wipeMemoryMsg'),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteAllMemories(widget.userId);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l.t('wipeMemoryDone')),
                    backgroundColor: Colors.deepOrangeAccent,
                  ),
                );
              }
            },
            child: Text(l.t('wipe'),
                style: const TextStyle(color: Colors.deepOrangeAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmClearChat(BuildContext context) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.t('clearChatTitle'),
            style: const TextStyle(color: AppTheme.white)),
        content: Text(
          l.t('clearChatMsg'),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteAllMessages(widget.userId);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l.t('clearChatDone')),
                    backgroundColor: AppTheme.dangerRed,
                  ),
                );
              }
            },
            child: Text(l.t('clear'),
                style: const TextStyle(color: AppTheme.dangerRed)),
          ),
        ],
      ),
    );
  }

  void _confirmResetProfile(BuildContext context) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.t('resetProfileTitle'),
            style: const TextStyle(color: AppTheme.white)),
        content: Text(
          l.t('resetProfileMsg'),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('onboarding_complete', false);
              await prefs.remove('user_id');
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l.t('resetProfileDone')),
                    backgroundColor: AppTheme.warmOrange,
                  ),
                );
              }
            },
            child: Text(l.t('reset'),
                style: const TextStyle(color: AppTheme.warmOrange)),
          ),
        ],
      ),
    );
  }
}
