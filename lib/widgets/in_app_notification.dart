import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// In-app notification popup that slides from the right side to center.
/// Shows a Messenger-style card with avatar, title, and message.
/// Plays the daddy_sound chime and auto-dismisses after 5 seconds.
class InAppNotification {
  static final InAppNotification instance = InAppNotification._();
  InAppNotification._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  OverlayEntry? _currentOverlay;
  Timer? _autoDismiss;
  AudioPlayer? _player;

  /// Play the daddy_sound notification chime.
  Future<void> _playSound() async {
    try {
      _player?.dispose();
      _player = AudioPlayer();
      // Set audio context so it doesn't fully steal music focus
      await _player!.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.notification,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
        ),
      ));
      await _player!.play(AssetSource('sounds/daddy_sound.wav'));
      debugPrint('[AI Daddy] In-app sound played');
    } catch (e) {
      debugPrint('[AI Daddy] In-app sound error: $e');
    }
  }

  /// Show a notification popup that slides from right to center.
  void show({
    required String title,
    required String body,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 5),
  }) {
    // Dismiss any existing notification
    dismiss();

    // Play custom notification sound
    _playSound();

    // Try to show overlay — retry up to 3 times with delay if overlay isn't ready
    _tryShowOverlay(title, body, onTap, duration, retriesLeft: 3);
  }

  void _tryShowOverlay(
    String title,
    String body,
    VoidCallback? onTap,
    Duration duration, {
    int retriesLeft = 3,
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) {
      debugPrint('[AI Daddy] Overlay null, retries=$retriesLeft');
      if (retriesLeft > 0) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _tryShowOverlay(title, body, onTap, duration,
              retriesLeft: retriesLeft - 1);
        });
      }
      return;
    }

    _currentOverlay = OverlayEntry(
      builder: (context) => _InAppNotificationWidget(
        title: title,
        body: body,
        onTap: () {
          onTap?.call();
          dismiss();
        },
        onDismiss: dismiss,
      ),
    );

    overlay.insert(_currentOverlay!);
    debugPrint('[AI Daddy] In-app overlay shown');

    // Auto-dismiss after duration
    _autoDismiss = Timer(duration, dismiss);
  }

  void dismiss() {
    _autoDismiss?.cancel();
    _autoDismiss = null;
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _InAppNotificationWidget extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppNotificationWidget({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_InAppNotificationWidget> createState() =>
      _InAppNotificationWidgetState();
}

class _InAppNotificationWidgetState extends State<_InAppNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Slide from right side to center
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0), // Start off-screen right
      end: Offset.zero,            // End at center
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _controller.forward();
  }

  Future<void> _dismissWithAnimation() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: widget.onTap,
              onHorizontalDragEnd: (details) {
                // Swipe to dismiss
                if (details.primaryVelocity != null &&
                    details.primaryVelocity!.abs() > 100) {
                  _dismissWithAnimation();
                }
              },
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(20),
                shadowColor: const Color(0xFF00BFFF).withOpacity(0.3),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFF00BFFF).withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00BFFF), Color(0xFF0080FF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00BFFF).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Color(0xFF00BFFF),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.body,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                height: 1.3,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Close button
                      GestureDetector(
                        onTap: () => _dismissWithAnimation(),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
