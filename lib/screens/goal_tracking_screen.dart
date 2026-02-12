import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/goal_model.dart';
import '../providers/chat_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Long-Term Goal Tracking Screen — add goals, milestones, track progress.
class GoalTrackingScreen extends StatefulWidget {
  const GoalTrackingScreen({super.key});

  @override
  State<GoalTrackingScreen> createState() => _GoalTrackingScreenState();
}

class _GoalTrackingScreenState extends State<GoalTrackingScreen> {
  final _db = DatabaseHelper.instance;
  List<GoalModel> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final userId = context.read<ChatProvider>().currentUser?.id ?? 1;
    _goals = await _db.getGoals(userId);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(
        title: Text('${AppLocalizations.of(context).t('goalTracking')} 🎯'),
        backgroundColor: AppTheme.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.glowCyan,
        onPressed: _showAddGoalDialog,
        child: const Icon(Icons.add, color: AppTheme.navyDark),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.glowCyan))
          : _goals.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadGoals,
                  color: AppTheme.glowCyan,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _goals.length,
                    itemBuilder: (ctx, i) => _buildGoalCard(_goals[i]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).t('noGoalsYet'),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 18)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).t('tapToAddGoal'),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal) {
    final milestones = _parseMilestones(goal.milestones);
    final completedCount =
        milestones.where((m) => m['done'] == true).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: goal.status == 'completed'
              ? Colors.greenAccent.withOpacity(0.3)
              : AppTheme.glowCyan.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(goal.categoryEmoji,
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    if (goal.description.isNotEmpty)
                      Text(goal.description,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12)),
                  ],
                ),
              ),
              _buildStatusChip(goal.status),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          Row(
            children: [
              Text('${(goal.progress * 100).toInt()}%',
                  style: const TextStyle(
                      color: AppTheme.glowCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                            goal.status == 'completed'
                                ? Colors.greenAccent
                                : AppTheme.glowCyan),
                  ),
                ),
              ),
            ],
          ),
          // Milestones
          if (milestones.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('${AppLocalizations.of(context).t('milestonesLabel')} ($completedCount/${milestones.length})',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...milestones.asMap().entries.map((entry) {
              final m = entry.value;
              final idx = entry.key;
              return GestureDetector(
                onTap: () => _toggleMilestone(goal, idx),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        m['done'] == true
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: m['done'] == true
                            ? Colors.greenAccent
                            : Colors.white38,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(m['title'] ?? '',
                            style: TextStyle(
                              color: m['done'] == true
                                  ? Colors.white54
                                  : Colors.white,
                              fontSize: 13,
                              decoration: m['done'] == true
                                  ? TextDecoration.lineThrough
                                  : null,
                            )),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          // Target date
          if (goal.targetDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('📅 ${AppLocalizations.of(context).t('targetDate')} ${goal.targetDate}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final colors = {
      'active': AppTheme.glowCyan,
      'completed': Colors.greenAccent,
      'paused': Colors.amber,
      'abandoned': Colors.redAccent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (colors[status] ?? Colors.grey).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: colors[status] ?? Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }

  List<Map<String, dynamic>> _parseMilestones(String json) {
    try {
      final list = jsonDecode(json) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _toggleMilestone(GoalModel goal, int idx) async {
    final milestones = _parseMilestones(goal.milestones);
    if (idx >= milestones.length) return;
    milestones[idx]['done'] = !(milestones[idx]['done'] ?? false);

    // Recalculate progress
    final done = milestones.where((m) => m['done'] == true).length;
    final progress = milestones.isEmpty ? 0.0 : done / milestones.length;
    final status = progress >= 1.0 ? 'completed' : goal.status;

    final updated = goal.copyWith(
      milestones: jsonEncode(milestones),
      progress: progress,
      status: status,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _db.updateGoal(updated);
    _loadGoals();
  }

  void _showAddGoalDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final milestoneCtrl = TextEditingController();
    String category = 'personal';
    final milestones = <String>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.navySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text('New Goal 🎯',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                _inputField(titleCtrl, AppLocalizations.of(context).t('goalTitle'), Icons.flag),
                const SizedBox(height: 12),
                _inputField(descCtrl, AppLocalizations.of(context).t('descriptionOptional'), Icons.notes),
                const SizedBox(height: 12),
                // Category selector
                Wrap(
                  spacing: 8,
                  children: ['personal', 'fitness', 'business', 'education', 'creative']
                      .map((c) => ChoiceChip(
                            label: Text(AppLocalizations.of(context).t('cat${c[0].toUpperCase()}${c.substring(1)}')),
                            selected: category == c,
                            selectedColor: AppTheme.glowCyan.withOpacity(0.3),
                            labelStyle: TextStyle(
                                color: category == c
                                    ? AppTheme.glowCyan
                                    : Colors.white70),
                            backgroundColor: AppTheme.navyCard,
                            onSelected: (sel) {
                              if (sel) {
                                setModalState(() => category = c);
                              }
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                // Milestones
                Row(
                  children: [
                    Expanded(
                        child: _inputField(
                            milestoneCtrl, AppLocalizations.of(context).t('addMilestone'), Icons.check_circle_outline)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle,
                          color: AppTheme.glowCyan),
                      onPressed: () {
                        if (milestoneCtrl.text.trim().isNotEmpty) {
                          setModalState(() {
                            milestones.add(milestoneCtrl.text.trim());
                            milestoneCtrl.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (milestones.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...milestones.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.radio_button_unchecked,
                                color: Colors.white38, size: 16),
                            const SizedBox(width: 8),
                            Text(m,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.glowCyan,
                      foregroundColor: AppTheme.navyDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _addGoal(
                      titleCtrl.text.trim(),
                      descCtrl.text.trim(),
                      category,
                      milestones,
                      ctx,
                    ),
                    child: Text(AppLocalizations.of(context).t('createGoal'),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
      TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: AppTheme.glowCyan, size: 20),
        filled: true,
        fillColor: AppTheme.navyCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Future<void> _addGoal(String title, String desc, String category,
      List<String> milestones, BuildContext ctx) async {
    if (title.isEmpty) return;
    final userId = context.read<ChatProvider>().currentUser?.id ?? 1;
    final milestonesJson = jsonEncode(
        milestones.map((m) => {'title': m, 'done': false}).toList());

    await _db.insertGoal(GoalModel(
      userId: userId,
      title: title,
      description: desc,
      category: category,
      milestones: milestonesJson,
      createdAt: DateTime.now().toIso8601String(),
    ));

    if (ctx.mounted) Navigator.pop(ctx);
    _loadGoals();
  }
}
