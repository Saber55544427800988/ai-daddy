import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mission_provider.dart';
import '../models/mission_model.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class MissionsScreen extends StatelessWidget {
  final int userId;
  const MissionsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: Consumer<MissionProvider>(
          builder: (_, mp, __) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: Text(l.t('dadTasks')),
                  automaticallyImplyLeading: false,
                  pinned: true,
                  backgroundColor: AppTheme.navyMid,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildLevelCard(context, mp),
                      const SizedBox(height: 20),
                      if (mp.earnedBadges.isNotEmpty) ...[
                        Text(
                          l.t('badges'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: mp.earnedBadges.map((badge) {
                            return Chip(
                              label: Text(badge),
                              backgroundColor:
                                  AppTheme.tokenGold.withOpacity(0.15),
                              labelStyle:
                                  const TextStyle(color: AppTheme.tokenGold),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Text(
                        l.t('dailyDadTasks'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...mp.missions.map((mission) {
                        final status = mp.getMissionStatus(mission.id ?? 0);
                        return _buildMissionCard(context, mp, mission, status);
                      }),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, MissionProvider mp) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3B66), Color(0xFF0A1628)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.glowCyan.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.glowCyan.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l.t('level')} ${mp.level}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    mp.levelTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${mp.totalXP}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // XP Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${mp.totalXP % mp.xpToNextLevel} / ${mp.xpToNextLevel} XP',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    '${l.t('nextLevel')}: ${mp.level + 1}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: mp.levelProgress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  color: AppTheme.tokenGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(
    BuildContext context,
    MissionProvider mp,
    MissionModel mission,
    MissionStatus status,
  ) {
    final isCompleted = status == MissionStatus.completed;
    final categoryIcons = {
      'water': Icons.water_drop,
      'study': Icons.menu_book,
      'exercise': Icons.fitness_center,
      'custom': Icons.star,
    };
    final categoryColors = {
      'water': const Color(0xFF42A5F5),
      'study': const Color(0xFFAB47BC),
      'exercise': AppTheme.successGreen,
      'custom': AppTheme.warmOrange,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppTheme.successGreen.withOpacity(0.08)
            : AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: isCompleted
            ? Border.all(color: AppTheme.successGreen.withOpacity(0.3))
            : Border.all(color: AppTheme.glowCyan.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (categoryColors[mission.category] ?? Colors.grey)
                  .withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              categoryIcons[mission.category] ?? Icons.star,
              color: categoryColors[mission.category] ?? Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? AppTheme.successGreen : AppTheme.white,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mission.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '+${mission.xpReward} XP',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.glowCyan),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${mission.tokenReward} ⚡',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.warmOrange),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isCompleted)
            ElevatedButton(
              onPressed: () {
                mp.completeMission(userId, mission.id ?? 0);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${AppLocalizations.of(context).t('missionComplete')} +${mission.xpReward} XP'),
                    backgroundColor: AppTheme.successGreen,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              child: Text(AppLocalizations.of(context).t('done'), style: const TextStyle(fontSize: 13)),
            )
          else
            const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 28),
        ],
      ),
    );
  }
}
