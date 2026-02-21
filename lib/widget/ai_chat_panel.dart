import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/web_utils.dart';
import '../llm/llm_service.dart';
import '../model/chat_message.dart';
import 'chat_bubble.dart';
import 'typing_indicator.dart';
import 'vn_dialogue_bubble.dart';

class AiChatPanel extends StatefulWidget {
  final List<ChatMessage> chatHistory;

  const AiChatPanel({super.key, required this.chatHistory});

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  late List<ChatMessage> messages;
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool isTyping = false;

  // VN State
  String currentDialogueJp = "";
  String? currentDialogueEn;
  bool isSakuraSpeaking = false;

  @override
  void initState() {
    super.initState();
    messages = widget.chatHistory;
    if (messages.isEmpty) {
      _addInitialMessage();
    }
  }

  Future<void> _addInitialMessage() async {
    const initialEnglish =
        "Ara~ Hello there! I'm Sakura, Master Angga's personal maid. Welcome to his portfolio! How can I help you today? ♡";
    const initialJapanese =
        "あら〜こんにちは！私はサクラ、アンガ様の専属メイドです。ポートフォリオへようこそ！今日は何かお手伝いできますか？♡";
    setState(() {
      messages
          .add(ChatMessage(text: initialEnglish, role: MessageRole.assistant));
    });
    _postMessageToVrm('speak', initialEnglish, japaneseText: initialJapanese);
    setState(() {
      currentDialogueJp = initialJapanese;
      currentDialogueEn = initialEnglish;
      isSakuraSpeaking = true;
    });
    _scrollToBottom();
  }

  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    final text = controller.text;
    controller.clear();

    setState(() {
      messages.add(ChatMessage(text: text, role: MessageRole.user));
      isTyping = true;
    });
    _scrollToBottom();

    try {
      String reply = await LlmService.getLlmResponse(messages);

      setState(() {
        isTyping = false;
        messages.add(ChatMessage(text: reply, role: MessageRole.assistant));
        currentDialogueEn = reply;
        currentDialogueJp = ""; // Reset since we don't have separate yet
        isSakuraSpeaking = true;
      });
      _postMessageToVrm('speak', reply);
    } catch (e) {
      setState(() {
        isTyping = false;
        messages
            .add(ChatMessage(text: "Error: $e", role: MessageRole.assistant));
      });
    }
    _scrollToBottom();
  }

  void _postMessageToVrm(String type, String text, {String? japaneseText}) {
    if (kIsWeb) {
      try {
        // Support bilingual: if japaneseText is provided, send structured data
        final messageData = japaneseText != null
            ? {
                'type': type,
                'japanese': japaneseText,
                'english': text,
              }
            : {'type': type, 'text': text};

        WebUtils.postMessageToIframe(
            'iframe[src="vrm/index.html"]', messageData);
      } catch (e) {
        // Handle error silently
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F18),
      body: SafeArea(
        child: Column(
          children: [
            // Chat header with Sakura info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16162A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Sakura avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B9D), Color(0xFFFF8E9E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B9D).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🌸', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sakura',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isTyping
                                    ? const Color(0xFFFFB74D)
                                    : const Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isTyping ? 'typing...' : 'Personal Maid • Online',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Heart decoration
                  Icon(
                    Icons.favorite,
                    color: const Color(0xFFFF6B9D).withOpacity(0.6),
                    size: 20,
                  ),
                ],
              ),
            ),

            // Chat messages
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
                    const SizedBox(height: 100), // Space for VN bubble
                  ],
                ),
              ),
            ),

            // VN Dialogue Bubble Overlay for Chat
            VnDialogueBubble(
              text: currentDialogueEn ?? "",
              subtitle: currentDialogueJp,
              isSpeaking: isSakuraSpeaking,
              onComplete: () {
                Future.delayed(const Duration(seconds: 4), () {
                  if (mounted) {
                    setState(() {
                      isSakuraSpeaking = false;
                    });
                  }
                });
              },
            ),

            // Input area
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF12121F),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFF6B9D).withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B9D).withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: TextField(
                        controller: controller,
                        enabled: !isTyping,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText:
                              isTyping ? "Sakura is typing…" : "Say something…",
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
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
                        gradient: LinearGradient(
                          colors: isTyping
                              ? [Colors.grey.shade600, Colors.grey.shade700]
                              : const [Color(0xFFFF6B9D), Color(0xFFFF8E9E)],
                        ),
                        boxShadow: isTyping
                            ? []
                            : [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFF6B9D).withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        color: isTyping ? Colors.grey[400] : Colors.white,
                        size: 22,
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
