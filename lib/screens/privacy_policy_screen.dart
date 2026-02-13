import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyDark,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppTheme.navyCard,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSection(
              'Information We Collect',
              Icons.info_outline,
              [
                _buildSubSection('Information You Provide', [
                  'Chat Messages: Your conversations with AI Daddy are stored locally on your device',
                  'User Profile: Nickname, preferences, and settings',
                  'Emotional Data: Mood indicators, stress levels, and emotional patterns derived from your interactions',
                  'Care Threads: Health status, travel plans, study schedules, and life events you share',
                ]),
                _buildSubSection('Automatically Collected', [
                  'Usage Data: App interaction patterns and reminder response rates',
                  'Device Information: Android version, device model, app version',
                  'Notification Data: Reminder scheduling and delivery status',
                ]),
              ],
            ),
            _buildSection(
              'How We Use Your Information',
              Icons.settings_outlined,
              [
                _buildSubSection('Local Processing', [
                  'All personal data is stored locally on YOUR device',
                  'Chat history, emotional profiles, and care threads remain on your device',
                  'No personal conversations are transmitted to external servers except for AI processing',
                ]),
                _buildSubSection('AI Processing', [
                  'Chat messages are sent to LongCat AI API for generating responses',
                  'Messages are processed in real-time and NOT permanently stored by the AI service',
                  'HTTPS encryption is used for secure transmission',
                ]),
              ],
            ),
            _buildSection(
              'Data Storage & Security',
              Icons.security_outlined,
              [
                _buildBulletList([
                  'All data stored in local SQLite database on your device',
                  'No cloud backup or synchronization',
                  'HTTPS encryption for all network communications',
                  'No third-party analytics or tracking',
                  'No advertising networks',
                  'No user accounts or authentication required',
                ]),
              ],
            ),
            _buildSection(
              'Data Sharing',
              Icons.share_outlined,
              [
                _buildSubSection('Third-Party Services', [
                  'LongCat AI: Chat messages sent for generating responses only',
                  'Data is processed but NOT stored permanently',
                  'No personal identifying information is shared',
                ]),
                _buildHighlight(
                  'We do NOT sell, rent, or trade your personal information.\n'
                  'We do NOT share data with advertisers.\n'
                  'We do NOT use tracking services.',
                  Colors.green,
                ),
              ],
            ),
            _buildSection(
              'Your Rights & Controls',
              Icons.admin_panel_settings_outlined,
              [
                _buildBulletList([
                  'View all your data within the app',
                  'Clear Chat History: Delete individual or all conversations in Settings',
                  'Reset App Data: Clear all data including emotional profiles',
                  'Uninstall: Removes ALL app data permanently',
                  'Control notification permissions in device settings',
                ]),
              ],
            ),
            _buildSection(
              'Children\'s Privacy',
              Icons.child_care_outlined,
              [
                _buildHighlight(
                  'AI Daddy is intended for users aged 13 and older. '
                  'We do not knowingly collect personal information from children under 13.',
                  Colors.orange,
                ),
              ],
            ),
            _buildSection(
              'Important Disclaimer',
              Icons.warning_amber_rounded,
              [
                _buildHighlight(
                  'AI Daddy is a supportive companion app and is NOT:\n\n'
                  '• A substitute for professional mental health care\n'
                  '• A medical device or diagnostic tool\n'
                  '• A crisis intervention service\n'
                  '• Qualified to provide medical or therapeutic advice\n\n'
                  'If you are experiencing a mental health crisis, please contact:\n'
                  '• National Suicide Prevention Lifeline: 988 (US)\n'
                  '• Crisis Text Line: Text HOME to 741741\n'
                  '• International: findahelpline.com\n'
                  '• Or call emergency services (911 in US)',
                  Colors.red,
                ),
              ],
            ),
            _buildSection(
              'Data Retention',
              Icons.timer_outlined,
              [
                _buildBulletList([
                  'Chat messages: Retained until you delete them or uninstall',
                  'Emotional profiles: Updated continuously, reset when you clear data',
                  'Care threads: Auto-expire after resolution or 30 days inactivity',
                  'Reminders: Deleted after delivery or cancellation',
                ]),
              ],
            ),
            _buildSection(
              'GDPR Rights (EU Users)',
              Icons.gavel_outlined,
              [
                _buildBulletList([
                  'Right to Access: Request a copy of your data',
                  'Right to Rectification: Correct inaccurate data',
                  'Right to Erasure: Request deletion of your data',
                  'Right to Restrict Processing',
                  'Right to Data Portability',
                  'Right to Object',
                ]),
              ],
            ),
            const SizedBox(height: 24),
            _buildFooter(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glowCyan.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.glowCyan, size: 48),
          const SizedBox(height: 12),
          Text(
            'AI Daddy Privacy Policy',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last Updated: February 13, 2026',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Your data stays on YOUR device',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.navyCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.glowCyan, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSubSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.glowCyan,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildHighlight(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.withOpacity(0.9),
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navyCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Summary',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow(Icons.check_circle, 'Chat messages stored locally', Colors.green),
          _summaryRow(Icons.check_circle, 'AI processing for responses only', Colors.green),
          _summaryRow(Icons.check_circle, 'No cloud storage, no user accounts', Colors.green),
          _summaryRow(Icons.check_circle, 'No advertising, no tracking', Colors.green),
          _summaryRow(Icons.check_circle, 'HTTPS encryption', Colors.green),
          _summaryRow(Icons.check_circle, 'You control your data', Colors.green),
          const SizedBox(height: 12),
          Text(
            'Your privacy matters. Your data stays yours.',
            style: TextStyle(
              color: AppTheme.glowCyan,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
