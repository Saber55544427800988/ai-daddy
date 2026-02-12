import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/dad_report_model.dart';
import '../providers/chat_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Dad Report Screen — shows weekly dad reports with
/// mood trends, engagement, growth, highlights.
class DadReportScreen extends StatefulWidget {
  const DadReportScreen({super.key});

  @override
  State<DadReportScreen> createState() => _DadReportScreenState();
}

class _DadReportScreenState extends State<DadReportScreen> {
  final _db = DatabaseHelper.instance;
  List<DadReportModel> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final userId = context.read<ChatProvider>().currentUser?.id ?? 1;
    _reports = await _db.getDadReports(userId, limit: 20);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(
        title: Text('${AppLocalizations.of(context).t('weeklyReports')} 📊'),
        backgroundColor: AppTheme.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.glowCyan))
          : _reports.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length,
                  itemBuilder: (ctx, i) => _buildReportCard(_reports[i]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📊', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).t('noReportsYet'),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 18)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).t('reportsGeneratedSunday'),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildReportCard(DadReportModel report) {
    List<String> highlights = [];
    try {
      highlights = (jsonDecode(report.highlights) as List).cast<String>();
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glowCyan.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(report.growthEmoji,
                  style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).t('weeklyDadReport'),
                        style: const TextStyle(
                            color: AppTheme.glowCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text('${report.weekStart} – ${report.weekEnd}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _growthColor(report.growthScore).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                    '${report.growthScore.toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: _growthColor(report.growthScore),
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _miniStat('💬', '${report.totalMessages}', AppLocalizations.of(context).t('messages')),
              _miniStat('🎯', '${report.missionsCompleted}', AppLocalizations.of(context).t('dadTasks')),
              _miniStat(report.moodTrendEmoji,
                  report.avgMood.toStringAsFixed(1), AppLocalizations.of(context).t('avgMood')),
              _miniStat('📈', report.moodTrend, AppLocalizations.of(context).t('trend')),
            ],
          ),
          const SizedBox(height: 16),

          // Daddy message
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.glowCyan.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.glowCyan.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).t('daddySaysColon'),
                    style: const TextStyle(
                        color: AppTheme.glowCyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(height: 6),
                Text(report.daddyMessage,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, height: 1.4)),
              ],
            ),
          ),

          // Highlights
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(AppLocalizations.of(context).t('highlights'),
                style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 6),
            ...highlights.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Text('•', style: TextStyle(color: AppTheme.glowCyan)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(h,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 10)),
        ],
      ),
    );
  }

  Color _growthColor(double score) {
    if (score >= 80) return Colors.greenAccent;
    if (score >= 60) return Colors.amber;
    if (score >= 40) return Colors.orange;
    return Colors.redAccent;
  }
}
