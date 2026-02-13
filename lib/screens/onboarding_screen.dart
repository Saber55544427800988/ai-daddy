import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../models/user_profile_model.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _nicknameController = TextEditingController();
  final _pageController = PageController();
  String _selectedPersonality = 'Caring';
  int _currentPage = 0;
  bool _isCreating = false;

  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  List<Map<String, dynamic>> _getPersonalities(AppLocalizations l) => [
    {
      'name': 'Caring',
      'nameLocal': l.t('caring'),
      'icon': Icons.favorite_rounded,
      'emoji': '💕',
      'color': const Color(0xFFFF6B9D),
      'gradient': const [Color(0xFFFF6B9D), Color(0xFFFF4081)],
      'desc': l.t('caringDesc'),
      'sample': l.t('caringSample'),
    },
    {
      'name': 'Strict',
      'nameLocal': l.t('strict'),
      'icon': Icons.shield_rounded,
      'emoji': '🛡️',
      'color': const Color(0xFF78909C),
      'gradient': const [Color(0xFF78909C), Color(0xFF546E7A)],
      'desc': l.t('strictDesc'),
      'sample': l.t('strictSample'),
    },
    {
      'name': 'Playful',
      'nameLocal': l.t('playful'),
      'icon': Icons.emoji_emotions_rounded,
      'emoji': '🎮',
      'color': const Color(0xFFFFAB40),
      'gradient': const [Color(0xFFFFAB40), Color(0xFFFF9100)],
      'desc': l.t('playfulDesc'),
      'sample': l.t('playfulSample'),
    },
    {
      'name': 'Motivational',
      'nameLocal': l.t('motivational'),
      'icon': Icons.rocket_launch_rounded,
      'emoji': '🏆',
      'color': const Color(0xFFAB47BC),
      'gradient': const [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
      'desc': l.t('motivationalDesc'),
      'sample': l.t('motivationalSample'),
    },
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050E1C), Color(0xFF0A1628), Color(0xFF112240)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top dots indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final isActive = _currentPage == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isActive
                            ? AppTheme.glowCyan
                            : AppTheme.navySurface,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppTheme.glowCyan.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                    );
                  }),
                ),
              ),

              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildWelcomePage(),
                    _buildNicknamePage(),
                    _buildPersonalityPage(),
                  ],
                ),
              ),

              // Bottom navigation
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  // ── PAGE 1: Welcome ──────────────────────────────────────────────────────

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Floating animated avatar
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _floatAnim.value),
              child: child,
            ),
            child: Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 36),

          // Title with gradient
          ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.glowGradient.createShader(bounds),
            child: Text(
              AppLocalizations.of(context).t('meetYourAIDaddy'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            AppLocalizations.of(context).t('onboardingSubtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary.withOpacity(0.9),
              height: 1.6,
            ),
          ),

          const SizedBox(height: 36),

          // Feature cards
          _featureCard(
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFF00BFFF),
            title: AppLocalizations.of(context).t('talkAnytime'),
            desc: AppLocalizations.of(context).t('talkAnytimeDesc'),
          ),
          _featureCard(
            icon: Icons.record_voice_over_rounded,
            color: const Color(0xFFFF6B9D),
            title: AppLocalizations.of(context).t('voiceMessages'),
            desc: AppLocalizations.of(context).t('voiceMessagesDesc'),
          ),
          _featureCard(
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFFFFAB40),
            title: AppLocalizations.of(context).t('smartReminders'),
            desc: AppLocalizations.of(context).t('smartRemindersDesc'),
          ),
          _featureCard(
            icon: Icons.psychology_rounded,
            color: const Color(0xFFAB47BC),
            title: AppLocalizations.of(context).t('learnsAboutYou'),
            desc: AppLocalizations.of(context).t('learnsAboutYouDesc'),
          ),
          _featureCard(
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFF00E676),
            title: AppLocalizations.of(context).t('missionsXP'),
            desc: AppLocalizations.of(context).t('missionsXPDesc'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.navyCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PAGE 2: Nickname ─────────────────────────────────────────────────────

  Widget _buildNicknamePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Emoji face
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _floatAnim.value * 0.6),
              child: child,
            ),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.glowCyan.withOpacity(0.1),
                border: Border.all(
                  color: AppTheme.glowCyan.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text('👋', style: TextStyle(fontSize: 48)),
              ),
            ),
          ),

          const SizedBox(height: 32),

          Text(
            AppLocalizations.of(context).t('whatShouldICallYou'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.white,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            AppLocalizations.of(context).t('pickNickname'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary.withOpacity(0.8),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 36),

          // Nickname input
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.glowCyan.withOpacity(0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: TextField(
              controller: _nicknameController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppTheme.white,
                letterSpacing: 0.5,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).t('yourNickname'),
                hintStyle: TextStyle(
                  fontSize: 20,
                  color: AppTheme.textSecondary.withOpacity(0.4),
                ),
                filled: true,
                fillColor: AppTheme.navyCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: AppTheme.glowCyan,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(height: 20),

          // Quick suggestions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _suggestionChip(AppLocalizations.of(context).t('suggChamp')),
              _suggestionChip(AppLocalizations.of(context).t('suggStar')),
              _suggestionChip(AppLocalizations.of(context).t('suggBuddy')),
              _suggestionChip(AppLocalizations.of(context).t('suggLegend')),
              _suggestionChip(AppLocalizations.of(context).t('suggHero')),
              _suggestionChip(AppLocalizations.of(context).t('suggBoss')),
            ],
          ),

          const SizedBox(height: 32),

          // Preview
          if (_nicknameController.text.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.navySurface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.glowCyan.withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  const Text('💬', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).t('nicknamePreview').replaceAll('{name}', _nicknameController.text.trim()),
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.glowCyanLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _suggestionChip(String text) {
    final isSelected = _nicknameController.text.trim() == text;
    return GestureDetector(
      onTap: () {
        _nicknameController.text = text;
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.glowCyan.withOpacity(0.2)
              : AppTheme.navyCard.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.glowCyan : AppTheme.navySurface,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? AppTheme.glowCyan : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ── PAGE 3: Personality ──────────────────────────────────────────────────

  Widget _buildPersonalityPage() {
    final l = AppLocalizations.of(context);
    final personalities = _getPersonalities(l);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          Text(
            AppLocalizations.of(context).t('chooseVibe'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.white,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            AppLocalizations.of(context).t('changeAnytime'),
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 24),

          // Personality grid (2x2)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: personalities.length,
            itemBuilder: (context, i) {
              final p = personalities[i];
              final isSelected = _selectedPersonality == p['name'];
              final gradientColors = p['gradient'] as List<Color>;

              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedPersonality = p['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (p['color'] as Color).withOpacity(0.12)
                        : AppTheme.navyCard.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? (p['color'] as Color)
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (p['color'] as Color).withOpacity(0.25),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with gradient circle
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: gradientColors),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (p['color'] as Color)
                                        .withOpacity(0.4),
                                    blurRadius: 12,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          p['icon'] as IconData,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p['nameLocal'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? (p['color'] as Color)
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p['desc'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary.withOpacity(0.7),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 8),
                        Icon(
                          Icons.check_circle_rounded,
                          color: p['color'] as Color,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Selected personality preview
          _buildPersonalityPreview(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPersonalityPreview() {
    final l = AppLocalizations.of(context);
    final personalities = _getPersonalities(l);
    final p = personalities.firstWhere(
      (p) => p['name'] == _selectedPersonality,
    );
    final nickname = _nicknameController.text.trim().isNotEmpty
        ? _nicknameController.text.trim()
        : 'Champ';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navySurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (p['color'] as Color).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(p['emoji'] as String, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                l.t('personalitySays').replaceAll('{name}', p['nameLocal'] as String),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p['color'] as Color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            (p['sample'] as String).replaceAll('champ', nickname),
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textPrimary,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation ─────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: () => _goToPage(_currentPage - 1),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.navyCard.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
              ),
            )
          else
            const SizedBox(width: 46),
          const Spacer(),
          GestureDetector(
            onTap: _isCreating ? null : _handleNext,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                gradient: _canProceed() ? AppTheme.glowGradient : null,
                color: _canProceed() ? null : AppTheme.navySurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _canProceed()
                    ? [
                        BoxShadow(
                          color: AppTheme.glowCyan.withOpacity(0.35),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: _isCreating
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == 2 ? AppLocalizations.of(context).t('letsGo') : AppLocalizations.of(context).t('next'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _canProceed()
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _currentPage == 2
                              ? Icons.rocket_launch_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                          color: _canProceed()
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    if (_currentPage == 1) return _nicknameController.text.trim().isNotEmpty;
    return true;
  }

  Future<void> _handleNext() async {
    if (_currentPage == 1 && _nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('giveNameError')),
          backgroundColor: AppTheme.navyCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_currentPage < 2) {
      _goToPage(_currentPage + 1);
      return;
    }

    // Final step — create user
    setState(() => _isCreating = true);

    try {
      final now = DateTime.now().toIso8601String();
      final nickname = _nicknameController.text.trim();

      final userId = await DatabaseHelper.instance.insertUser(
        UserModel(
          nickname: nickname,
          dadPersonality: _selectedPersonality.toLowerCase(),
          createdAt: now,
          lastOpened: now,
        ),
      );

      await DatabaseHelper.instance.insertUserProfile(
        UserProfileModel(nickname: nickname),
      );

      await DatabaseHelper.instance.initTokens(userId);

      await NotificationService.instance.scheduleDailyReminders(
        nickname,
        ReminderModel.defaultReminderTexts(nickname),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      await prefs.setInt('user_id', userId);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(userId: userId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).t('errorCreating')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}
