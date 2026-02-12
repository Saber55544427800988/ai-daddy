import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/dad_memory_model.dart';
import '../providers/chat_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Dad Memory Vault Screen — shows all memories AI Daddy has learned.
/// View, delete, manage memories by category.
class MemoryVaultScreen extends StatefulWidget {
  const MemoryVaultScreen({super.key});

  @override
  State<MemoryVaultScreen> createState() => _MemoryVaultScreenState();
}

class _MemoryVaultScreenState extends State<MemoryVaultScreen> {
  final _db = DatabaseHelper.instance;
  List<DadMemoryModel> _memories = [];
  bool _loading = true;
  String _filter = 'all';

  final _categories = [
    'all', 'goal', 'fear', 'hobby', 'date', 'achievement', 'failure', 'preference'
  ];

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final userId = context.read<ChatProvider>().currentUser?.id ?? 1;
    if (_filter == 'all') {
      _memories = await _db.getDadMemories(userId);
    } else {
      _memories = await _db.getDadMemoriesByCategory(userId, _filter);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(
        title: Text('${AppLocalizations.of(context).t('memoryVault')} 🧠'),
        backgroundColor: AppTheme.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final isSelected = _filter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat == 'all'
                        ? AppLocalizations.of(context).t('all')
                        : '${_categoryEmoji(cat)} ${cat[0].toUpperCase()}${cat.substring(1)}'),
                    selected: isSelected,
                    selectedColor: AppTheme.glowCyan.withOpacity(0.25),
                    backgroundColor: AppTheme.navyCard,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.glowCyan : Colors.white60,
                      fontSize: 12,
                    ),
                    onSelected: (sel) {
                      setState(() {
                        _filter = cat;
                        _loading = true;
                      });
                      _loadMemories();
                    },
                  ),
                );
              },
            ),
          ),
          // Memory list
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.glowCyan))
                : _memories.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadMemories,
                        color: AppTheme.glowCyan,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _memories.length,
                          itemBuilder: (ctx, i) =>
                              _buildMemoryCard(_memories[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧠', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).t('noMemoriesYet'),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 18)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
                AppLocalizations.of(context).t('noMemoriesDesc'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(DadMemoryModel memory) {
    return Dismissible(
      key: Key('memory_${memory.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.redAccent),
      ),
      onDismissed: (_) async {
        await _db.deleteDadMemory(memory.id!);
        _loadMemories();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.glowCyan.withOpacity(0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(memory.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(memory.content,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _tagChip(memory.category),
                      const Spacer(),
                      if (memory.mentionCount > 0)
                        Text('${AppLocalizations.of(context).t('mentionedCount')} ${memory.mentionCount}x',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 10)),
                    ],
                  ),
                  if (memory.context.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(memory.context,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 11,
                            fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.glowCyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(category.toUpperCase(),
          style: const TextStyle(
              color: AppTheme.glowCyan,
              fontSize: 9,
              fontWeight: FontWeight.bold)),
    );
  }

  String _categoryEmoji(String cat) {
    const map = {
      'goal': '🎯',
      'fear': '😰',
      'hobby': '🎨',
      'date': '📅',
      'achievement': '🏆',
      'failure': '📉',
      'preference': '💡',
    };
    return map[cat] ?? '📝';
  }
}
