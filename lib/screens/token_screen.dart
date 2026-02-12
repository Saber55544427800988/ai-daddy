import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/token_provider.dart';
import '../models/ai_token_model.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class TokenScreen extends StatelessWidget {
  final int userId;
  const TokenScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: Consumer<TokenProvider>(
          builder: (_, tp, __) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: Text(l.t('aiTokens')),
                  automaticallyImplyLeading: false,
                  pinned: true,
                  backgroundColor: AppTheme.navyMid,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildTokenGauge(context, tp),
                      const SizedBox(height: 20),
                      _buildPlanCards(context),
                      const SizedBox(height: 20),
                      _buildSpendingModeCard(context, tp),
                      const SizedBox(height: 20),
                      _buildTokenCostsCard(context),
                      const SizedBox(height: 40),
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

  Widget _buildTokenGauge(BuildContext context, TokenProvider tp) {
    final l = AppLocalizations.of(context);
    final percent = tp.percentRemaining;
    final color = tp.isLow ? AppTheme.dangerRed : AppTheme.glowCyan;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular progress
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 12,
                    backgroundColor: color.withOpacity(0.15),
                    color: color,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 28, color: color),
                    Text(
                      '${tp.remaining}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '${l.t('ofTotal')} ${tp.total}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Refill countdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.glowCyan.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glowCyan.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 18, color: AppTheme.glowCyan),
                const SizedBox(width: 8),
                Text(
                  '${l.t('refillIn')} ${tp.refillCountdown}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.glowCyan,
                  ),
                ),
              ],
            ),
          ),

          if (tp.isLow) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.dangerRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.dangerRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.t('lowTokensWarning'),
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.dangerRed),
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

  Widget _buildPlanCards(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.t('yourPlan'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
        const SizedBox(height: 12),
        // Free plan (active)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.navyCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.glowCyan.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.glowCyan.withOpacity(0.08),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.glowGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.glowCyan.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l.t('freePlan'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _ActiveBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.t('freePlanDesc'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Premium plan (coming soon)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A2A4A), Color(0xFF0F1E38)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.tokenGold.withOpacity(0.25),
            ),
          ),
          child: Row(
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
                    Row(
                      children: [
                        Text(
                          l.t('premiumPlanName'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.tokenGold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.warmOrange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.warmOrange.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            l.t('comingSoon'),
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
                    const SizedBox(height: 4),
                    Text(
                      l.t('premiumPlanDesc'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _premiumFeature(l.t('premiumFeature1')),
                        _premiumFeature(l.t('premiumFeature2')),
                        _premiumFeature(l.t('premiumFeature3')),
                        _premiumFeature(l.t('premiumFeature4')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _premiumFeature(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.tokenGold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.tokenGold,
        ),
      ),
    );
  }

  Widget _buildSpendingModeCard(BuildContext context, TokenProvider tp) {
    final l = AppLocalizations.of(context);
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
          Text(
            l.t('spendingMode'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.t('spendingModeDesc'),
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _modeButton(
                  context,
                  tp,
                  SpendingMode.slow,
                  l.t('slowModeLabel'),
                  l.t('slowModeDesc'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _modeButton(
                  context,
                  tp,
                  SpendingMode.fast,
                  l.t('fastModeLabel'),
                  l.t('fastModeDesc'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeButton(
    BuildContext context,
    TokenProvider tp,
    SpendingMode mode,
    String title,
    String desc,
  ) {
    final isSelected = tp.spendingMode == mode;
    return GestureDetector(
      onTap: () => tp.setSpendingMode(userId, mode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.glowCyan.withOpacity(0.12)
              : AppTheme.navySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.glowCyan : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? AppTheme.glowCyan : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenCostsCard(BuildContext context) {
    final l = AppLocalizations.of(context);
    final costs = [
      {'action': l.t('costShortChat'), 'cost': '10–20', 'icon': Icons.chat},
      {'action': l.t('costLongChat'), 'cost': '50–100', 'icon': Icons.message},
      {'action': l.t('costHiddenReminder'), 'cost': '30', 'icon': Icons.notifications},
      {'action': l.t('costSmartReminder'), 'cost': '50', 'icon': Icons.alarm},
      {'action': l.t('costCheckIn'), 'cost': '20', 'icon': Icons.waving_hand},
      {'action': l.t('costMissionReward'), 'cost': '+50', 'icon': Icons.star},
    ];

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
          Text(
            l.t('tokenCosts'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 12),
          ...costs.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(c['icon'] as IconData,
                        size: 20, color: AppTheme.glowCyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c['action'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (c['cost'] as String).startsWith('+')
                            ? AppTheme.successGreen.withOpacity(0.1)
                            : AppTheme.warmOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${c['cost']} ⚡',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: (c['cost'] as String).startsWith('+')
                              ? AppTheme.successGreen
                              : AppTheme.warmOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.successGreen.withOpacity(0.3)),
      ),
      child: Text(
        AppLocalizations.of(context).t('active'),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.successGreen,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
