import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/habit_model.dart';
import '../providers/chat_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Habit Formation Engine Screen — create, track, and build habits.
class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  final _db = DatabaseHelper.instance;
  List<HabitModel> _habits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final userId = context.read<ChatProvider>().currentUser?.id ?? 1;
    _habits = await _db.getHabits(userId);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(
        title: Text('${AppLocalizations.of(context).t('habitBuilder')} 🔄'),
        backgroundColor: AppTheme.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.glowCyan,
        onPressed: _showAddHabitDialog,
        child: const Icon(Icons.add, color: AppTheme.navyDark),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.glowCyan))
          : _habits.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHabits,
                  color: AppTheme.glowCyan,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _habits.length,
                    itemBuilder: (ctx, i) => _buildHabitCard(_habits[i]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔄', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).t('noHabitsYet'),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 18)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).t('tapToAddHabit'),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHabitCard(HabitModel habit) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final completedToday = habit.lastCompleted.startsWith(today);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completedToday
              ? Colors.greenAccent.withOpacity(0.3)
              : AppTheme.glowCyan.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(habit.strengthEmoji,
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text('${habit.category} • ${habit.strength}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12)),
                  ],
                ),
              ),
              if (!completedToday)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline,
                      color: AppTheme.glowCyan, size: 28),
                  onPressed: () => _completeHabit(habit),
                )
              else
                const Icon(Icons.check_circle,
                    color: Colors.greenAccent, size: 28),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _habitStat('🔥', '${habit.currentStreak}', AppLocalizations.of(context).t('streak')),
              _habitStat('⭐', '${habit.bestStreak}', AppLocalizations.of(context).t('best')),
              _habitStat(
                  '📊',
                  '${(habit.completionRate * 100).toInt()}%',
                  AppLocalizations.of(context).t('rate')),
              _habitStat('📅', '${habit.completedDays}', AppLocalizations.of(context).t('done')),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: habit.completionRate.clamp(0, 1),
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                  _strengthColor(habit.strength)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _habitStat(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text('$emoji $value',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 10)),
        ],
      ),
    );
  }

  Future<void> _completeHabit(HabitModel habit) async {
    await _db.completeHabitToday(habit.id!);
    _loadHabits();
  }

  Color _strengthColor(String strength) {
    switch (strength) {
      case 'strong':
        return Colors.greenAccent;
      case 'building':
        return Colors.amber;
      case 'weak':
        return Colors.orange;
      case 'at-risk':
        return Colors.redAccent;
      default:
        return AppTheme.glowCyan;
    }
  }

  void _showAddHabitDialog() {
    final nameCtrl = TextEditingController();
    String category = 'custom';

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('New Habit 🔄',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).t('habitName'),
                  hintStyle:
                      TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: const Icon(Icons.repeat,
                      color: AppTheme.glowCyan, size: 20),
                  filled: true,
                  fillColor: AppTheme.navyCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['health', 'study', 'exercise', 'social', 'custom']
                    .map((c) => ChoiceChip(
                          label: Text(AppLocalizations.of(context).t('cat${c[0].toUpperCase()}${c.substring(1)}')),
                          selected: category == c,
                          selectedColor:
                              AppTheme.glowCyan.withOpacity(0.3),
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
                  onPressed: () => _addHabit(nameCtrl.text, category, ctx),
                  child: Text(AppLocalizations.of(context).t('createHabit'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addHabit(
      String name, String category, BuildContext ctx) async {
    if (name.trim().isEmpty) return;
    final userId = context.read<ChatProvider>().currentUser?.id ?? 1;
    await _db.insertHabit(HabitModel(
      userId: userId,
      name: name.trim(),
      category: category,
      createdAt: DateTime.now().toIso8601String(),
    ));
    if (ctx.mounted) Navigator.pop(ctx);
    _loadHabits();
  }
}
