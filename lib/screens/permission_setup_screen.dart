import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Play Store–compliant permission setup screen.
/// Shown once after onboarding — explains WHY each permission is needed
/// with an emotional but honest tone. Never blocks app access.
class PermissionSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PermissionSetupScreen({super.key, required this.onComplete});

  @override
  State<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends State<PermissionSetupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _notifGranted = false;
  bool _batteryOptimized = false;
  bool _exactAlarmGranted = false;
  bool _isOemDevice = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _detectOem();
    _checkExactAlarmPermission();
  }

  void _detectOem() async {
    try {
      const platform = MethodChannel('com.aidaddy.ai_daddy/bubble');
      final manufacturer = await platform.invokeMethod<String>('getDeviceManufacturer') ?? '';
      final m = manufacturer.toLowerCase();
      setState(() {
        _isOemDevice = m.contains('xiaomi') ||
            m.contains('redmi') ||
            m.contains('poco') ||
            m.contains('oppo') ||
            m.contains('realme') ||
            m.contains('vivo') ||
            m.contains('oneplus') ||
            m.contains('huawei') ||
            m.contains('honor');
      });
    } catch (_) {
      _isOemDevice = false;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _requestNotifications() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      final granted = await NotificationService.instance.requestPermission();
      setState(() => _notifGranted = granted);
    } catch (_) {}
    setState(() => _requesting = false);
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      const platform = MethodChannel('com.aidaddy.ai_daddy/bubble');
      await platform.invokeMethod('requestBatteryOptimization');
      setState(() => _batteryOptimized = true);
    } catch (_) {
      // Not available on all devices — that's fine
      setState(() => _batteryOptimized = true);
    }
  }

  Future<void> _checkExactAlarmPermission() async {
    try {
      final granted = await NotificationService.instance.canScheduleExactAlarms();
      setState(() => _exactAlarmGranted = granted);
    } catch (_) {
      setState(() => _exactAlarmGranted = true); // Can't check = assume OK
    }
  }

  Future<void> _requestExactAlarm() async {
    try {
      await NotificationService.instance.openExactAlarmSettings();
      // Re-check after user returns (small delay for settings to apply)
      await Future.delayed(const Duration(seconds: 2));
      await _checkExactAlarmPermission();
    } catch (_) {
      setState(() => _exactAlarmGranted = true);
    }
  }

  Future<void> _completeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permission_setup_done', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Header
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00BFFF), Color(0xFF0080FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00BFFF).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l.t('permSetupTitle'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.t('permSetupDesc'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Permission cards
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // 1. Notification permission
                          _buildPermissionCard(
                            icon: Icons.notifications_rounded,
                            title: l.t('permNotifTitle'),
                            description: l.t('permNotifDesc'),
                            buttonText: _notifGranted
                                ? l.t('permGranted')
                                : l.t('permAllow'),
                            granted: _notifGranted,
                            onTap: _notifGranted ? null : _requestNotifications,
                          ),
                          const SizedBox(height: 16),

                          // 2. Battery optimization
                          _buildPermissionCard(
                            icon: Icons.battery_saver_rounded,
                            title: l.t('permBatteryTitle'),
                            description: l.t('permBatteryDesc'),
                            buttonText: _batteryOptimized
                                ? l.t('permDone')
                                : l.t('permOptimize'),
                            granted: _batteryOptimized,
                            onTap: _batteryOptimized
                                ? null
                                : _requestBatteryOptimization,
                          ),
                          const SizedBox(height: 16),

                          // 3. Exact alarm permission (Android 12+)
                          if (!_exactAlarmGranted)
                            _buildPermissionCard(
                              icon: Icons.alarm_rounded,
                              title: l.t('permExactAlarmTitle'),
                              description: l.t('permExactAlarmDesc'),
                              buttonText: l.t('permExactAlarmBtn'),
                              granted: false,
                              onTap: _requestExactAlarm,
                            ),
                          if (!_exactAlarmGranted)
                            const SizedBox(height: 16),

                          // 4. OEM-specific guidance
                          if (_isOemDevice)
                            _buildPermissionCard(
                              icon: Icons.phone_android_rounded,
                              title: l.t('permOemTitle'),
                              description: l.t('permOemDesc'),
                              buttonText: l.t('permShowGuide'),
                              granted: false,
                              isGuide: true,
                              onTap: () => _showOemGuide(context, l),
                            ),

                          const SizedBox(height: 24),
                          // Disclaimer
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withOpacity(0.05),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.white.withOpacity(0.5),
                                    size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l.t('permDisclaimer'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.5),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _completeSetup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BFFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child: Text(
                              l.t('permContinue'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Skip / Enable later
                        TextButton(
                          onPressed: _completeSetup,
                          child: Text(
                            l.t('permSkip'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required bool granted,
    bool isGuide = false,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.navyCard,
        border: Border.all(
          color: granted
              ? Colors.greenAccent.withOpacity(0.5)
              : const Color(0xFF00BFFF).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          if (granted)
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.1),
              blurRadius: 8,
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: granted
                  ? Colors.greenAccent.withOpacity(0.15)
                  : const Color(0xFF00BFFF).withOpacity(0.15),
            ),
            child: Icon(
              granted ? Icons.check_circle_rounded : icon,
              color: granted ? Colors.greenAccent : const Color(0xFF00BFFF),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (onTap != null)
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: _requesting ? null : onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGuide
                      ? Colors.amber.withOpacity(0.9)
                      : granted
                          ? Colors.greenAccent
                          : const Color(0xFF00BFFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isGuide ? Colors.black87 : Colors.white,
                  ),
                ),
              ),
            ),
          if (onTap == null && granted)
            Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
        ],
      ),
    );
  }

  void _showOemGuide(BuildContext context, AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navyDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.t('oemGuideTitle'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l.t('oemGuideSubtitle'),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildOemStep(
                '1',
                l.t('oemStep1Title'),
                l.t('oemStep1Desc'),
                Icons.settings_rounded,
              ),
              _buildOemStep(
                '2',
                l.t('oemStep2Title'),
                l.t('oemStep2Desc'),
                Icons.battery_full_rounded,
              ),
              _buildOemStep(
                '3',
                l.t('oemStep3Title'),
                l.t('oemStep3Desc'),
                Icons.play_circle_outline_rounded,
              ),
              _buildOemStep(
                '4',
                l.t('oemStep4Title'),
                l.t('oemStep4Desc'),
                Icons.lock_open_rounded,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.amber.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.t('oemGuideNote'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l.t('permDone'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOemStep(
    String number,
    String title,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00BFFF).withOpacity(0.15),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Color(0xFF00BFFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFF00BFFF), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
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
}
