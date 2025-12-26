import 'package:flutter/material.dart';
import '../model/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? Colors.blueAccent.withOpacity(0.3)
                  : Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isUser
              ? null
              : Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: SelectableText(
          message.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
