import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ai_service.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      role: 'assistant',
      content:
          'Hello! I\'m TrustShield AI Assistant. 🛡️\n\nI can help you:\n• Check if a message is a scam\n• Verify job/internship offers\n• Analyze suspicious URLs\n• Learn about cybersecurity\n\nWhat would you like to check today?',
      timestamp: DateTime.now(),
    ),
  ];

  final _quickActions = [
    '🔍 Is this internship real?',
    '🌐 Check this URL for me',
    '💌 Analyze this message',
    '🏦 Is this bank alert fake?',
    '💼 Verify this job offer',
    '📱 Tips to stay safe online',
  ];

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;
    _messageController.clear();

    // Build history BEFORE adding new message (to avoid sending it twice)
    final history = _messages
        .where((m) => m.role != 'typing')
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    setState(() {
      _messages.add(_ChatMessage(
        role: 'user',
        content: trimmed,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.chat(trimmed, history);

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            role: 'assistant',
            content: response.isNotEmpty
                ? response
                : 'I apologize, I could not process that. Please try again.',
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            role: 'assistant',
            content: 'Sorry, I encountered an error: ${e.toString().replaceAll('Exception: ', '')}',
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(_ChatMessage(
        role: 'assistant',
        content: 'Chat cleared. 🛡️ How can I help you stay safe today?',
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TrustShield AI',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: AppColors.darkText)),
                Text('Powered by Gemini',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.darkSubtext)),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.darkCard,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: AppColors.darkSubtext),
            tooltip: 'Clear chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                return _ChatBubble(message: msg)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.15, duration: 300.ms, curve: Curves.easeOut);
              },
            ),
          ),

          // Quick actions (show only if few messages)
          if (_messages.length <= 2)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.darkSubtext,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickActions
                        .map((action) => GestureDetector(
                              onTap: () => _sendMessage(action),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.darkCard,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.primary.withOpacity(0.3)),
                                ),
                                child: Text(action,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.darkText)),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ).animate().fadeIn(),

          // Input field
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
            decoration: const BoxDecoration(
              color: AppColors.darkCard,
              border: Border(top: BorderSide(color: AppColors.darkBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(
                        color: AppColors.darkText, fontSize: 14),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about scams...',
                      hintStyle: TextStyle(
                          color: AppColors.darkSubtext.withOpacity(0.7),
                          fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: AppColors.darkBg,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.darkBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_messageController.text),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _isLoading
                          ? null
                          : AppColors.primaryGradient,
                      color: _isLoading ? AppColors.darkBorder : null,
                    ),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                color: AppColors.primary, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                      delay: Duration(milliseconds: 200 * i),
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(0.5, 0.5),
                      duration: 600.ms,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.primaryGradient : null,
                color: isUser ? null : AppColors.darkCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.darkBorder),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : AppColors.darkText,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Icon(Icons.person,
                  color: AppColors.primary, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  const _ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}
