import 'package:flutter/material.dart';
import '../llm/llm_service.dart';
import '../model/chat_message.dart';
import 'chat_bubble.dart';
import 'typing_indicator.dart';

class AiChatPanel extends StatefulWidget {
  final List<ChatMessage> chatHistory; // Receive messages from parent

  const AiChatPanel({super.key, required this.chatHistory});

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  late List<ChatMessage> messages;
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    messages = widget.chatHistory; // Use parent history
  }

  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    final text = controller.text;
    controller.clear();

    setState(() {
      messages.add(ChatMessage(text: text, role: MessageRole.user));
      isTyping = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    final reply = await LlmService.ask(text);

    setState(() {
      isTyping = false;
      messages.add(ChatMessage(text: reply, role: MessageRole.assistant));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0F0F18), Color(0xFF1A1A2E)],
                  ),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...messages.map((m) => ChatBubble(message: m)),
                    if (isTyping) const FuturisticTypingIndicator(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF12121F),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.cyanAccent.withOpacity(0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: TextField(
                        controller: controller,
                        enabled: !isTyping, // Disable input while AI typing
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: isTyping ? "AI is typing…" : "Ask me anything…",
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: isTyping ? null : sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.send,
                        color: isTyping ? Colors.grey.shade400 : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
