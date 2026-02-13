import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/token_provider.dart';
import '../models/message_model.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final int userId;
  const ChatScreen({super.key, required this.userId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: Column(
          children: [
            // Custom App Bar
            _buildAppBar(),
            // Chat messages
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (_, chat, __) {
                  if (chat.messages.isEmpty) {
                    return _buildEmptyChat(chat);
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        chat.messages.length + (chat.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chat.messages.length && chat.isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(chat.messages[index]);
                    },
                  );
                },
              ),
            ),
            // Input field
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.navyMid,
        boxShadow: [
          BoxShadow(
            color: AppTheme.glowCyan.withOpacity(0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo avatar
          Image.asset(
            'assets/images/logo.png',
            width: 38,
            height: 38,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (_, chat, __) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).t('aiDaddy'),
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.white)),
                    if (chat.currentUser != null)
                      Text(
                        "${AppLocalizations.of(context).t('imYourDaddy').replaceAll(' ❤️', '')}, ${chat.currentUser!.nickname}! ❤️",
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(ChatProvider chat) {
    final name = chat.currentUser?.nickname ?? 'there';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 90,
              height: 90,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).t('heyUser').replaceAll('{name}', name),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${AppLocalizations.of(context).t('imYourDaddy').replaceAll(' ❤️', '')}. ${AppLocalizations.of(context).t('talkToDaddy').replaceAll('...', '')}! 💙",
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _quickAction(AppLocalizations.of(context).t('hiDaddy')),
                _quickAction(AppLocalizations.of(context).t('feelingGreat')),
                _quickAction(AppLocalizations.of(context).t('needHelp')),
                _quickAction(AppLocalizations.of(context).t('imBored')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.glowCyanLight)),
      backgroundColor: AppTheme.glowCyan.withOpacity(0.1),
      side: BorderSide(color: AppTheme.glowCyan.withOpacity(0.3), width: 0.5),
      onPressed: () => _sendMessage(text),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final isUser = message.senderType == SenderType.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.accentBlue : AppTheme.navyCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? AppTheme.accentBlue.withOpacity(0.2)
                  : AppTheme.glowCyan.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : AppTheme.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                color: isUser
                    ? Colors.white.withOpacity(0.6)
                    : AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.navyCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.glowCyan.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 4),
            _dot(1),
            const SizedBox(width: 4),
            _dot(2),
          ],
        ),
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (_, value, __) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.glowCyan.withOpacity(0.3 + value * 0.4),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.navyMid,
        boxShadow: [
          BoxShadow(
            color: AppTheme.glowCyan.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).t('talkToDaddy'),
                  filled: true,
                  fillColor: AppTheme.navySurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(null),
              ),
            ),
            const SizedBox(width: 8),
            Container(
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
              child: IconButton(
                onPressed: () => _sendMessage(null),
                icon: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String? quickText) {
    final text = quickText ?? _messageController.text;
    if (text.trim().isEmpty) return;

    context.read<ChatProvider>().sendMessage(text);
    _messageController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Refresh tokens
    context.read<TokenProvider>().refresh(widget.userId);
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
