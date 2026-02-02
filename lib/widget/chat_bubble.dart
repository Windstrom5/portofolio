import 'package:flutter/material.dart';
import '../model/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sakura avatar (left side for assistant)
          if (!isUser) ...[
            _buildAvatar(isUser: false),
            const SizedBox(width: 10),
          ],

          // Message column
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Name label
                Padding(
                  padding: EdgeInsets.only(
                    left: isUser ? 0 : 4,
                    right: isUser ? 4 : 0,
                    bottom: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isUser)
                        const Icon(
                          Icons.favorite,
                          size: 12,
                          color: Color(0xFFFF6B9D),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        isUser ? 'Master' : 'Sakura',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isUser
                              ? const Color(0xFF4FACFE)
                              : const Color(0xFFFF6B9D),
                        ),
                      ),
                      if (isUser) const SizedBox(width: 4),
                      if (isUser)
                        const Icon(
                          Icons.person,
                          size: 12,
                          color: Color(0xFF4FACFE),
                        ),
                    ],
                  ),
                ),

                // Message bubble
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF2D2D3A), Color(0xFF1E1E2E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: const Color(0xFFFF6B9D).withOpacity(0.3),
                            width: 1,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? const Color(0xFF4FACFE).withOpacity(0.3)
                            : const Color(0xFFFF6B9D).withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User avatar (right side for user)
          if (isUser) ...[
            const SizedBox(width: 10),
            _buildAvatar(isUser: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isUser}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isUser
            ? const LinearGradient(
                colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFFF8E9E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: isUser
                ? const Color(0xFF4FACFE).withOpacity(0.4)
                : const Color(0xFFFF6B9D).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: isUser
            ? const Icon(Icons.person, color: Colors.white, size: 22)
            : const Text(
                '🌸',
                style: TextStyle(fontSize: 20),
              ),
      ),
    );
  }
}
