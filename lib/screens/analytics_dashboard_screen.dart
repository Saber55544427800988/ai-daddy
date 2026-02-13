import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/dad_report_model.dart';
import '../providers/chat_provider.dart';
import '../services/emotional_intelligence_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Deep Analytics Dashboard — mood graphs, engagement stats,
/// relationship depth, growth tracking, token usage.
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final _db = DatabaseHelper.instance;
  bool _loading = true;

  // Data
  Map<String, int> _messagesPerDay = {};
  Map<String, double> _moodPerDay = {};
  double _avgMood = 3.0;
  String _moodTrend = 'stable';
  int _totalMessages = 0;
  int _totalInteractions = 0;
  int _completedMissions = 0;
  Map<String, double> _engagementByTone = {};
  Map<String, int> _intentFrequency = {};
  Map<String, dynamic> _relationshipStage = {};
  double _relationshipProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final chat = context.read<ChatProvider>();
      final user = chat.currentUser;
      if (user == null || user.id == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final userId = user.id!;

      final results = await Future.wait([
        _db.getMessagesPerDay(userId, days: 7),
        _db.getMoodPerDay(userId, days: 7),
        EmotionalIntelligenceService.getAverageMood(userId),
        EmotionalIntelligenceService.getMoodTrend(userId),
        _db.getMessageCount(userId, days: 30),
        _db.getTotalInteractions(userId),
        _db.getCompletedMissionCount(userId),
        _db.getEngagementByTone(userId),
        _db.getIntentFrequency(userId),
      ]);

      if (!mounted) return;

      setState(() {
        _messagesPerDay = (results[0] as Map<String, int>?) ?? {};
        _moodPerDay = (results[1] as Map<String, double>?) ?? {};
        _avgMood = (results[2] as double?) ?? 3.0;
        _moodTrend = (results[3] as String?) ?? 'stable';
        _totalMessages = (results[4] as int?) ?? 0;
        _totalInteractions = (results[5] as int?) ?? 0;
        _completedMissions = (results[6] as int?) ?? 0;
        _engagementByTone = (results[7] as Map<String, double>?) ?? {};
        _intentFrequency = (results[8] as Map<String, int>?) ?? {};
        _relationshipStage = RelationshipStage.getStage(_totalInteractions);
        _relationshipProgress = RelationshipStage.getProgress(_totalInteractions);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).t('analyticsDashboard')),
        backgroundColor: AppTheme.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.glowCyan))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.glowCyan,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOverviewCards(),
                  const SizedBox(height: 16),
                  _buildRelationshipDepthCard(),
                  const SizedBox(height: 16),
                  _buildMoodChartCard(),
                  const SizedBox(height: 16),
                  _buildActivityChartCard(),
                  const SizedBox(height: 16),
                  _buildEngagementByToneCard(),
                  const SizedBox(height: 16),
                  _buildTopIntentsCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    final l = AppLocalizations.of(context);
    final trendEmoji = _moodTrend == 'improving'
        ? '📈'
        : _moodTrend == 'declining'
            ? '📉'
            : '➡️';

    return Row(
      children: [
        Expanded(
            child: _statCard(
                '💬', '$_totalMessages', l.t('messages30Days'), AppTheme.glowCyan)),
        const SizedBox(width: 12),
        Expanded(
            child: _statCard('🎯', '$_completedMissions', l.t('missionsDone'),
                AppTheme.accentBlue)),
        const SizedBox(width: 12),
        Expanded(
            child: _statCard(trendEmoji, _avgMood.toStringAsFixed(1),
                l.t('avgMood7Days'), Colors.amber)),
      ],
    );
  }

  Widget _statCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildRelationshipDepthCard() {
    final stage = _relationshipStage;
    final nextStage = RelationshipStage.getNextStage(_totalInteractions);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.glowCyan.withOpacity(0.15),
            AppTheme.accentBlue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glowCyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${stage['emoji']}',
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).t('relationshipDepth'),
                        style: const TextStyle(
                            color: AppTheme.glowCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text('${stage['title']}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.glowCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${AppLocalizations.of(context).t('level')} ${stage['level']}',
                    style: const TextStyle(
                        color: AppTheme.glowCyan,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _relationshipProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.glowCyan),
            ),
          ),
          if (nextStage != null) ...[
            const SizedBox(height: 8),
            Text(
                '${AppLocalizations.of(context).t('nextStageInfo')} ${nextStage['emoji']} ${nextStage['title']} — ${nextStage['minInteractions']} ${AppLocalizations.of(context).t('totalInteractions')}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12)),
          ],
          const SizedBox(height: 4),
          Text('$_totalInteractions ${AppLocalizations.of(context).t('totalInteractions')}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildMoodChartCard() {
    return _chartCard(
      title: AppLocalizations.of(context).t('moodTrend7Days'),
      child: _moodPerDay.isEmpty
          ? _emptyState(AppLocalizations.of(context).t('noMoodData'))
          : SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _moodPerDay.entries
                    .map((e) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(e.value.toStringAsFixed(1),
                                    style: TextStyle(
                                        color: _moodColor(e.value),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Container(
                                  height: (e.value / 5.0) * 80,
                                  decoration: BoxDecoration(
                                    color: _moodColor(e.value),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    e.key.length >= 10
                                        ? e.key.substring(8, 10)
                                        : e.key,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 10)),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildActivityChartCard() {
    final rawMax = _messagesPerDay.values.isEmpty
        ? 1
        : _messagesPerDay.values.reduce((a, b) => a > b ? a : b);
    final maxMsgs = rawMax < 1 ? 1 : rawMax;

    return _chartCard(
      title: AppLocalizations.of(context).t('chatActivity7Days'),
      child: _messagesPerDay.isEmpty
          ? _emptyState(AppLocalizations.of(context).t('noActivityData'))
          : SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _messagesPerDay.entries
                    .map((e) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('${e.value}',
                                    style: const TextStyle(
                                        color: AppTheme.accentBlue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Container(
                                  height: (e.value / maxMsgs) * 80,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentBlue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    e.key.length >= 10
                                        ? e.key.substring(8, 10)
                                        : e.key,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 10)),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildEngagementByToneCard() {
    return _chartCard(
      title: AppLocalizations.of(context).t('engagementByTone'),
      child: _engagementByTone.isEmpty
          ? _emptyState(AppLocalizations.of(context).t('chatMoreToSeeData'))
          : Column(
              children: _engagementByTone.entries.map((e) {
                final percent = (e.value * 100).clamp(0, 100);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 90,
                          child: Text(e.key,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: e.value.clamp(0, 1),
                            minHeight: 12,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                _toneColor(e.key)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${percent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildTopIntentsCard() {
    final sortedIntents = _intentFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sortedIntents.take(6).toList();

    return _chartCard(
      title: AppLocalizations.of(context).t('whatYouTalkAbout'),
      child: top.isEmpty
          ? _emptyState(AppLocalizations.of(context).t('chatMoreToSeeData'))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: top.map((e) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.glowCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.glowCyan.withOpacity(0.3)),
                  ),
                  child: Text('${e.key} (${e.value})',
                      style: const TextStyle(
                          color: AppTheme.glowCyan, fontSize: 12)),
                );
              }).toList(),
            ),
    );
  }

  Widget _chartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _emptyState(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(text,
            style: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 13)),
      ),
    );
  }

  Color _moodColor(double score) {
    if (score >= 4.0) return Colors.greenAccent;
    if (score >= 3.0) return Colors.amber;
    if (score >= 2.0) return Colors.orange;
    return Colors.redAccent;
  }

  Color _toneColor(String tone) {
    switch (tone) {
      case 'caring':
        return Colors.pinkAccent;
      case 'strict':
        return Colors.orangeAccent;
      case 'playful':
        return Colors.yellowAccent;
      case 'motivational':
        return Colors.greenAccent;
      default:
        return AppTheme.glowCyan;
    }
  }
}
