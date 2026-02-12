import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Spark Screen — Daily inspiration, dad quotes, mood check-in,
/// motivational cards and interactive engagement features.
class SparkScreen extends StatefulWidget {
  final int userId;
  const SparkScreen({super.key, required this.userId});

  @override
  State<SparkScreen> createState() => _SparkScreenState();
}

class _SparkScreenState extends State<SparkScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _selectedMood = -1;
  int _currentQuoteIndex = 0;

  List<String> _getDadQuotes(AppLocalizations l) => [
    l.t('dadQuote1'), l.t('dadQuote2'), l.t('dadQuote3'), l.t('dadQuote4'),
    l.t('dadQuote5'), l.t('dadQuote6'), l.t('dadQuote7'), l.t('dadQuote8'),
    l.t('dadQuote9'), l.t('dadQuote10'),
  ];

  List<Map<String, dynamic>> _getDailySparks(AppLocalizations l) => [
    {'title': l.t('sparkHydration'), 'subtitle': l.t('sparkHydrationDesc'), 'icon': Icons.water_drop_rounded, 'color': const Color(0xFF42A5F5)},
    {'title': l.t('sparkBreathe'), 'subtitle': l.t('sparkBreatheDesc'), 'icon': Icons.air_rounded, 'color': const Color(0xFF66BB6A)},
    {'title': l.t('sparkGratitude'), 'subtitle': l.t('sparkGratitudeDesc'), 'icon': Icons.favorite_rounded, 'color': const Color(0xFFEF5350)},
    {'title': l.t('sparkMove'), 'subtitle': l.t('sparkMoveDesc'), 'icon': Icons.directions_walk_rounded, 'color': const Color(0xFFFFCA28)},
    {'title': l.t('sparkSmile'), 'subtitle': l.t('sparkSmileDesc'), 'icon': Icons.emoji_emotions_rounded, 'color': const Color(0xFFAB47BC)},
  ];

  List<String> _getMoodLabels(AppLocalizations l) => [
    '😢 ${l.t('moodSad')}', '😐 ${l.t('moodMeh')}', '🙂 ${l.t('moodOkay')}',
    '😊 ${l.t('moodGood')}', '🤩 ${l.t('moodGreat')}',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(AppLocalizations.of(context).t('sparkTitle')),
              automaticallyImplyLeading: false,
              pinned: true,
              backgroundColor: AppTheme.navyMid,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildDaddyQuoteCard(),
                  const SizedBox(height: 20),
                  _buildMoodCheckIn(),
                  const SizedBox(height: 20),
                  _buildDailySparks(),
                  const SizedBox(height: 20),
                  _buildStreakCard(),
                  const SizedBox(height: 20),
                  _buildAffirmationGenerator(),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Animated quote card with "I'm your Daddy" branding
  Widget _buildDaddyQuoteCard() {
    final l = AppLocalizations.of(context);
    final quotes = _getDadQuotes(l);
    return AnimatedBuilder(
      listenable: _pulseController,
      builder: (context, child) {
        final glowOpacity = 0.15 + (_pulseController.value * 0.15);
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D3B66), Color(0xFF112850)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.glowCyan.withOpacity(glowOpacity),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: AppTheme.glowCyan.withOpacity(0.2),
            ),
          ),
          child: child,
        );
      },
      child: Column(
        children: [
          // "I'm your Daddy" header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.glowGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.glowCyan.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.t('imYourDaddy').replaceAll(' ❤️', ''),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.glowCyan,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    l.t('dailyWisdom'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Quote
          Text(
            quotes[_currentQuoteIndex % quotes.length],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.white,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          // Next quote button
          TextButton.icon(
            onPressed: () {
              setState(() {
                _currentQuoteIndex =
                    (_currentQuoteIndex + 1) % quotes.length;
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l.t('nextQuote')),
          ),
        ],
      ),
    );
  }

  /// Mood check-in selector
  Widget _buildMoodCheckIn() {
    final l = AppLocalizations.of(context);
    final moodLabels = _getMoodLabels(l);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glowCyan.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mood_rounded, color: AppTheme.glowCyan, size: 22),
              const SizedBox(width: 8),
              Text(
                l.t('howFeeling'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.t('daddyWantsToKnow'),
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final isSelected = _selectedMood == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.glowCyan.withOpacity(0.15)
                        : AppTheme.navySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.glowCyan
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.glowCyan.withOpacity(0.15),
                              blurRadius: 10,
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Text(
                        moodLabels[i].split(' ')[0],
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        moodLabels[i].split(' ')[1],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.glowCyan
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          if (_selectedMood >= 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.glowCyan.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glowCyan.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppTheme.glowCyan, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getMoodResponse(_selectedMood),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getMoodResponse(int index) {
    final l = AppLocalizations.of(context);
    final responses = [
      l.t('moodResponseSad'),
      l.t('moodResponseMeh'),
      l.t('moodResponseOkay'),
      l.t('moodResponseGood'),
      l.t('moodResponseGreat'),
    ];
    return responses[index];
  }

  /// Daily micro-actions
  Widget _buildDailySparks() {
    final l = AppLocalizations.of(context);
    final sparks = _getDailySparks(l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppTheme.tokenGold, size: 22),
            const SizedBox(width: 8),
            Text(
              l.t('dailySparks'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l.t('smallActionsBigImpact'),
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        ...List.generate(sparks.length, (i) {
          final spark = sparks[i];
          return _SparkActionTile(
            title: spark['title'] as String,
            subtitle: spark['subtitle'] as String,
            icon: spark['icon'] as IconData,
            color: spark['color'] as Color,
          );
        }),
      ],
    );
  }

  /// Streak motivation card
  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A5C), Color(0xFF0D2A45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.warmOrange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.warmOrange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: AppTheme.warmOrange, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).t('keepStreakAlive'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).t('streakDescription'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tap-to-reveal affirmation
  Widget _buildAffirmationGenerator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glowCyan.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded,
                  color: AppTheme.tokenGold, size: 22),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).t('daddyDailyAffirmation'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showAffirmationDialog(context);
              },
              icon: const Icon(Icons.auto_awesome),
              label: Text(AppLocalizations.of(context).t('revealAffirmation')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.glowCyan.withOpacity(0.15),
                foregroundColor: AppTheme.glowCyan,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: AppTheme.glowCyan.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAffirmationDialog(BuildContext context) {
    final l = AppLocalizations.of(context);
    final affirmations = [
      l.t('affirmation1'), l.t('affirmation2'), l.t('affirmation3'),
      l.t('affirmation4'), l.t('affirmation5'), l.t('affirmation6'),
      l.t('affirmation7'), l.t('affirmation8'),
    ];

    final affirmation =
        affirmations[DateTime.now().day % affirmations.length];

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppTheme.glowGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.glowCyan.withOpacity(0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                l.t('daddySays'),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.glowCyan,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                affirmation,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.t('thanksDaddy')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated builder helper (named to avoid conflict with AnimatedBuilder)
class AnimatedBuilder extends AnimatedWidget {
  final Widget? child;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}

/// Individual spark action tile with completion toggle
class _SparkActionTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SparkActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  State<_SparkActionTile> createState() => _SparkActionTileState();
}

class _SparkActionTileState extends State<_SparkActionTile> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _done
            ? AppTheme.successGreen.withOpacity(0.08)
            : AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: _done
            ? Border.all(color: AppTheme.successGreen.withOpacity(0.3))
            : Border.all(color: AppTheme.glowCyan.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: widget.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _done ? AppTheme.successGreen : AppTheme.white,
                    decoration: _done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _done = !_done),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _done
                    ? AppTheme.successGreen
                    : AppTheme.navySurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _done
                      ? AppTheme.successGreen
                      : AppTheme.textSecondary.withOpacity(0.3),
                ),
              ),
              child: _done
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
