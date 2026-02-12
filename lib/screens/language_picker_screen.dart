import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// First-launch language selection screen.
/// Auto-detects user's device language and pre-selects it.
/// User confirms before proceeding.
class LanguagePickerScreen extends StatefulWidget {
  final VoidCallback onLanguageConfirmed;
  const LanguagePickerScreen({super.key, required this.onLanguageConfirmed});

  @override
  State<LanguagePickerScreen> createState() => _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends State<LanguagePickerScreen>
    with SingleTickerProviderStateMixin {
  late String _selectedLang;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // Auto-detect device language, fall back to 'en'
    final deviceLang = ui.PlatformDispatcher.instance.locale.languageCode;
    final supported = AppLocalizations.supportedLocales
        .map((l) => l.languageCode)
        .toSet();
    _selectedLang = supported.contains(deviceLang) ? deviceLang : 'en';

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050E1C), Color(0xFF0A1628), Color(0xFF112240)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 16),

                // Title — shown in detected language
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.glowGradient.createShader(bounds),
                  child: Text(
                    AppLocalizations.of(context).t('chooseYourLanguage'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  AppLocalizations.of(context).t('selectPreferredLanguage'),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 24),

                // Language grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.6,
                      ),
                      itemCount: AppLocalizations.supportedLocales.length,
                      itemBuilder: (_, i) {
                        final locale = AppLocalizations.supportedLocales[i];
                        final code = locale.languageCode;
                        final flag =
                            AppLocalizations.languageFlags[code] ?? '🌐';
                        final name =
                            AppLocalizations.languageNames[code] ?? code;
                        final isSelected = code == _selectedLang;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedLang = code),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.glowCyan.withOpacity(0.15)
                                  : AppTheme.navyCard.withOpacity(0.6),
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
                                        color: AppTheme.glowCyan
                                            .withOpacity(0.2),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(flag,
                                    style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppTheme.glowCyan
                                          : AppTheme.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppTheme.glowCyan, size: 18),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Auto-detected hint
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.navyCard.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 16,
                            color: AppTheme.glowCyan.withOpacity(0.7)),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).t('autoDetectedLanguage'),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Confirm button
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _confirmLanguage,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: AppTheme.glowGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.glowCyan.withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${AppLocalizations.languageFlags[_selectedLang]} ${AppLocalizations.of(context).t('continueButton')}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLanguage() async {
    // Save the user's explicit choice
    final localeProvider = context.read<LocaleProvider>();
    await localeProvider.setLocale(_selectedLang);
    widget.onLanguageConfirmed();
  }
}
