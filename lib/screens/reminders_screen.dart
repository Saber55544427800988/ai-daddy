import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/smart_reminder_model.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Reminders Screen — Shows all reminders (AI auto + manual).
/// Users can add, view, and delete reminders.
class RemindersScreen extends StatefulWidget {
  final int userId;
  const RemindersScreen({super.key, required this.userId});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SmartReminderModel> _smartReminders = [];
  List<ReminderModel> _manualReminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReminders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    final db = DatabaseHelper.instance;
    final smart = await db.getAllSmartReminders(widget.userId);
    final manual = await db.getAllReminders(widget.userId);
    if (mounted) {
      setState(() {
        _smartReminders = smart;
        _manualReminders = manual;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: Column(
          children: [
            // App bar
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded,
                        color: AppTheme.glowCyan, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      l.t('reminders'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                    ),
                    const Spacer(),
                    // Total count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.glowCyan.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_smartReminders.length + _manualReminders.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.glowCyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.navyCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.glowCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.glowCyan, width: 1.5),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppTheme.glowCyan,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, size: 16),
                        const SizedBox(width: 6),
                        Text(l.t('aiReminders')),
                        if (_smartReminders.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _countBadge(_smartReminders.length),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_notifications, size: 16),
                        const SizedBox(width: 6),
                        Text(l.t('myReminders')),
                        if (_manualReminders.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _countBadge(_manualReminders.length),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tab views
            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.glowCyan))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSmartRemindersList(),
                        _buildManualRemindersList(),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(context),
        backgroundColor: AppTheme.glowCyan,
        icon: const Icon(Icons.add_alarm_rounded, color: Colors.white),
        label: Text(
          l.t('addReminder'),
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _countBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.glowCyan.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.glowCyan),
      ),
    );
  }

  // ─── AI Smart Reminders Tab ─────────────────────

  Widget _buildSmartRemindersList() {
    final l = AppLocalizations.of(context);
    if (_smartReminders.isEmpty) {
      return _emptyState(
        icon: Icons.auto_awesome_rounded,
        title: l.t('noAiReminders'),
        subtitle: l.t('noAiRemindersDesc'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _smartReminders.length,
      itemBuilder: (_, i) {
        final r = _smartReminders[i];
        final time = DateTime.tryParse(r.scheduledTime);
        final isPast = time != null && time.isBefore(DateTime.now());
        final typeIcon = _eventTypeIcon(r.eventType);

        return Dismissible(
          key: Key('smart_${r.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.dangerRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_rounded,
                color: AppTheme.dangerRed, size: 24),
          ),
          onDismissed: (_) => _deleteSmartReminder(r.id!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.navyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPast
                    ? AppTheme.textSecondary.withOpacity(0.1)
                    : AppTheme.glowCyan.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                // Event type icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (isPast
                            ? AppTheme.textSecondary
                            : AppTheme.glowCyan)
                        .withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon,
                      color: isPast
                          ? AppTheme.textSecondary
                          : AppTheme.glowCyan,
                      size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.glowCyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome,
                                    size: 10, color: AppTheme.glowCyan),
                                const SizedBox(width: 3),
                                Text(
                                  l.t('aiSet'),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.glowCyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _eventTypeColor(r.eventType)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.eventType,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _eventTypeColor(r.eventType),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.text,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isPast
                              ? AppTheme.textSecondary
                              : AppTheme.white,
                          decoration:
                              isPast ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isPast
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                            size: 14,
                            color: isPast
                                ? AppTheme.successGreen
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(time),
                            style: TextStyle(
                              fontSize: 12,
                              color: isPast
                                  ? AppTheme.successGreen
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (r.sentFlag)
                  const Icon(Icons.check_circle,
                      color: AppTheme.successGreen, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Manual Reminders Tab ─────────────────────

  Widget _buildManualRemindersList() {
    final l = AppLocalizations.of(context);
    if (_manualReminders.isEmpty) {
      return _emptyState(
        icon: Icons.edit_notifications_rounded,
        title: l.t('noManualReminders'),
        subtitle: l.t('noManualRemindersDesc'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _manualReminders.length,
      itemBuilder: (_, i) {
        final r = _manualReminders[i];
        final time = DateTime.tryParse(r.scheduledTime);
        final isPast = time != null && time.isBefore(DateTime.now());

        return Dismissible(
          key: Key('manual_${r.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.dangerRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_rounded,
                color: AppTheme.dangerRed, size: 24),
          ),
          onDismissed: (_) => _deleteManualReminder(r.id!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.navyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPast
                    ? AppTheme.textSecondary.withOpacity(0.1)
                    : AppTheme.accentBlue.withOpacity(0.15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (isPast
                            ? AppTheme.textSecondary
                            : AppTheme.accentBlue)
                        .withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_rounded,
                      color: isPast
                          ? AppTheme.textSecondary
                          : AppTheme.accentBlue,
                      size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l.t('manualSet'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.text,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isPast
                              ? AppTheme.textSecondary
                              : AppTheme.white,
                          decoration:
                              isPast ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isPast
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                            size: 14,
                            color: isPast
                                ? AppTheme.successGreen
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(time),
                            style: TextStyle(
                              fontSize: 12,
                              color: isPast
                                  ? AppTheme.successGreen
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isPast)
                  const Icon(Icons.check_circle,
                      color: AppTheme.successGreen, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Add Reminder Dialog ─────────────────────

  void _showAddReminderDialog(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx2).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.navyCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Row(
                      children: [
                        const Icon(Icons.add_alarm_rounded,
                            color: AppTheme.glowCyan, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          l.t('addReminder'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Reminder text
                    TextField(
                      controller: textController,
                      style: const TextStyle(color: AppTheme.white),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: l.t('reminderTextHint'),
                        hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.6)),
                        filled: true,
                        fillColor: AppTheme.navySurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.edit_rounded,
                            color: AppTheme.glowCyan),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date picker
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: ctx2,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          builder: (_, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppTheme.glowCyan,
                                  surface: AppTheme.navyCard,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setModalState(() {
                            selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.navySurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: AppTheme.glowCyan, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: const TextStyle(
                                  fontSize: 15, color: AppTheme.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Time picker
                    GestureDetector(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: ctx2,
                          initialTime: selectedTime,
                          builder: (_, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppTheme.glowCyan,
                                  surface: AppTheme.navyCard,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (time != null) {
                          setModalState(() {
                            selectedTime = time;
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.navySurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                color: AppTheme.glowCyan, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              selectedTime.format(ctx2),
                              style: const TextStyle(
                                  fontSize: 15, color: AppTheme.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _saveManualReminder(textController.text, selectedDate),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(
                          l.t('setReminder'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.glowCyan,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveManualReminder(String text, DateTime time) async {
    if (text.trim().isEmpty) return;

    final reminder = ReminderModel(
      userId: widget.userId,
      text: text.trim(),
      scheduledTime: time.toIso8601String(),
      tone: 'caring',
    );

    final id = await DatabaseHelper.instance.insertReminder(reminder);

    // Schedule notification (mobile only)
    if (!kIsWeb) {
      await NotificationService.instance.scheduleNotification(
        id: 200 + id,
        title: 'AI Daddy 💙',
        body: text.trim(),
        scheduledTime: time,
      );
    }

    if (mounted) Navigator.pop(context);
    await _loadReminders();
  }

  Future<void> _deleteSmartReminder(int id) async {
    await DatabaseHelper.instance.deleteSmartReminder(id);
    await _loadReminders();
  }

  Future<void> _deleteManualReminder(int id) async {
    // Cancel the scheduled notification
    if (!kIsWeb) {
      await NotificationService.instance.cancel(200 + id);
    }
    await DatabaseHelper.instance.deleteReminder(id);
    await _loadReminders();
  }

  // ─── Helpers ─────────────────────

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.glowCyan.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.glowCyan.withOpacity(0.5), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? time) {
    if (time == null) return '—';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final reminderDay = DateTime(time.year, time.month, time.day);

    String dayStr;
    if (reminderDay == today) {
      dayStr = 'Today';
    } else if (reminderDay == tomorrow) {
      dayStr = 'Tomorrow';
    } else {
      dayStr = '${time.day}/${time.month}/${time.year}';
    }

    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$dayStr at $hour:$minute $period';
  }

  IconData _eventTypeIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'meeting':
        return Icons.groups_rounded;
      case 'homework':
      case 'study':
        return Icons.school_rounded;
      case 'call':
        return Icons.phone_rounded;
      case 'exam':
        return Icons.quiz_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  Color _eventTypeColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'meeting':
        return Colors.orangeAccent;
      case 'homework':
      case 'study':
        return Colors.lightBlueAccent;
      case 'call':
        return Colors.greenAccent;
      case 'exam':
        return Colors.redAccent;
      default:
        return AppTheme.glowCyan;
    }
  }
}
