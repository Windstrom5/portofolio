import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../llm/llm_service.dart';
import '../llm/model_config.dart';
import '../model/chat_message.dart';
import 'chat_bubble.dart';
import 'vn_dialogue_bubble.dart';
import 'vrm_maid_view.dart';

class AiChatPanel extends StatefulWidget {
  final List<ChatMessage> chatHistory;
  final Function(String)? onCommand;

  const AiChatPanel({super.key, required this.chatHistory, this.onCommand});

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  late List<ChatMessage> messages;
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool isTyping = false;
  bool showBacklog = false;

  final VrmController _vrmController = VrmController();

  // VN State
  String currentDialogueText = "";
  String? currentDialogueSubtitle;
  bool isSakuraSpeaking = false;
  String currentSpeaker = "Sakura";

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
      currentDialogueText = initialEnglish;
      currentDialogueSubtitle = initialJapanese;
      currentSpeaker = "Sakura";
      isSakuraSpeaking = true;
    });
    _vrmController.speak(initialJapanese, english: initialEnglish);
  }

  Future<void> sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    final text = controller.text;
    controller.clear();

    setState(() {
      messages.add(ChatMessage(text: text, role: MessageRole.user));
      // Show user's message in VN dialogue briefly
      currentDialogueText = text;
      currentDialogueSubtitle = null;
      currentSpeaker = "You";
      isSakuraSpeaking = true;
      isTyping = true;
    });

    // Brief delay to show user's text, then switch to typing indicator
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      // Check for commands
      if (text.toLowerCase().startsWith("open ") ||
          text.toLowerCase() == "close" ||
          text.toLowerCase() == "exit") {
        if (widget.onCommand != null) {
          widget.onCommand!(text);
          setState(() => isTyping = false);
          return;
        }
      }

      String reply = await LlmService.ask(text);

      setState(() {
        isTyping = false;
        messages.add(ChatMessage(text: reply, role: MessageRole.assistant));
        currentDialogueText = reply;
        currentDialogueSubtitle = null;
        currentSpeaker = "Sakura";
        isSakuraSpeaking = true;
      });
      _vrmController.speak(reply);
    } catch (e) {
      setState(() {
        isTyping = false;
        messages
            .add(ChatMessage(text: "Error: $e", role: MessageRole.assistant));
        currentDialogueText = "Ah, something went wrong... ♡";
        currentSpeaker = "Sakura";
        isSakuraSpeaking = true;
      });
    }
  }

  Future<bool> _handleMicTranscript(String transcript) async {
    if (transcript.trim().isEmpty) {
      setState(() => isTyping = false);
      return false;
    }

    try {
      // Intercept commands
      final lowerTranscript = transcript.toLowerCase();
      if (lowerTranscript.startsWith("open ") ||
          lowerTranscript == "close" ||
          lowerTranscript == "exit") {
        if (widget.onCommand != null) {
          widget.onCommand!(transcript);
          return true;
        }
      }

      final reply = await LlmService.ask(transcript);
      if (mounted) {
        setState(() {
          isTyping = false;
          messages.add(ChatMessage(text: reply, role: MessageRole.assistant));
          currentDialogueText = reply;
          currentDialogueSubtitle = null;
          currentSpeaker = "Sakura";
          isSakuraSpeaking = true;
        });
        _vrmController.speak(reply);
      }
      return true;
    } catch (e) {
      if (mounted) {
        setState(() => isTyping = false);
      }
      return false;
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
        child: Stack(
          children: [
            // Background VRM Model
            Positioned.fill(
              child: VrmMaidView(
                controller: _vrmController,
                showVoiceControls: true,
                onMicResult: _handleMicTranscript,
              ),
            ),
            // Background overlay gradient to ensure text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      const Color(0xFF0F0F18).withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),

            // Main VN-style layout
            Column(
              children: [
                // Top bar with Sakura info + backlog toggle
                _buildVnHeader(),

                // Spacer to push dialogue box to bottom
                const Expanded(child: SizedBox()),

                // VN Dialogue Box (primary display)
                _buildVnDialogueBox(),

                // VN-style text input
                _buildVnInput(),
              ],
            ),

            // Backlog overlay (slide from right)
            if (showBacklog) _buildBacklogOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildVnHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withValues(alpha: 0.95),
            const Color(0xFF16162A).withValues(alpha: 0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // Sakura avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFFF8E9E)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B9D).withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Center(
              child: Text('🌸', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),

          // Name and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sakura',
                  style: GoogleFonts.pressStart2p(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: ModelConfig.activeModelId == 'none'
                            ? Colors.grey
                            : isTyping
                                ? const Color(0xFFFFB74D)
                                : const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ModelConfig.activeModelId == 'none'
                          ? 'Offline'
                          : isTyping
                              ? 'thinking...'
                              : 'Online',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Backlog button
          GestureDetector(
            onTap: () => setState(() => showBacklog = !showBacklog),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: showBacklog
                    ? const Color(0xFFFF6B9D).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: showBacklog
                      ? const Color(0xFFFF6B9D).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    color: showBacklog
                        ? const Color(0xFFFF6B9D)
                        : Colors.grey[400],
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LOG',
                    style: GoogleFonts.jetBrainsMono(
                      color: showBacklog
                          ? const Color(0xFFFF6B9D)
                          : Colors.grey[400],
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVnDialogueBox() {
    if (!isSakuraSpeaking && currentDialogueText.isEmpty) {
      return const SizedBox(height: 100);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Typing indicator above dialogue box
          if (isTyping)
            Positioned(
              bottom: 140, // Above the box
              left: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDotPulse(),
                  const SizedBox(width: 8),
                  Text(
                    'Sakura is thinking...',
                    style: GoogleFonts.ubuntu(
                      color: const Color(0xFFFF6B9D).withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Speaker name tag - Floating above the box
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: currentSpeaker == "You"
                          ? [const Color(0xFF4FACFE), const Color(0xFF00F2FE)]
                          : [const Color(0xFFFF6B9D), const Color(0xFFFF8E9E)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (currentSpeaker == "You"
                                ? const Color(0xFF4FACFE)
                                : const Color(0xFFFF6B9D))
                            .withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Text(
                    currentSpeaker.toUpperCase(),
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              // Main dialogue box - Wider and more traditional VN style
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(30, 25, 30, 35),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A14).withValues(alpha: 0.92),
                  border: Border(
                    top: BorderSide(
                      color: (currentSpeaker == "You"
                              ? const Color(0xFF4FACFE)
                              : const Color(0xFFFF6B9D))
                          .withValues(alpha: 0.8),
                      width: 3,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: (currentSpeaker == "You"
                              ? const Color(0xFF4FACFE)
                              : const Color(0xFFFF6B9D))
                          .withValues(alpha: 0.1),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: VnDialogueBubble(
                  text: currentDialogueText,
                  subtitle: currentDialogueSubtitle,
                  name: currentSpeaker,
                  isSpeaking: isSakuraSpeaking,
                  onComplete: () {
                    Future.delayed(const Duration(seconds: 4), () {
                      if (mounted && !isTyping) {
                        setState(() => isSakuraSpeaking = false);
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVnInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A14),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Voice Toggle button (Mic)
          _buildVnIconButton(
            icon: Icons.mic_rounded,
            onTap: () => _vrmController.startMic(),
            color: const Color(0xFF4FACFE),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: TextField(
                controller: controller,
                enabled: !isTyping,
                style: GoogleFonts.ubuntu(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: isTyping ? "Sakura is thinking…" : "Send a message…",
                  hintStyle: GoogleFonts.ubuntu(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildVnIconButton(
            icon: Icons.send_rounded,
            onTap: isTyping ? null : sendMessage,
            color: const Color(0xFFFF6B9D),
          ),
        ],
      ),
    );
  }

  Widget _buildVnIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildBacklogOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => showBacklog = false),
        child: Container(
          color: Colors.black.withOpacity(0.6),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {}, // Don't close when tapping inside
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F1A).withValues(alpha: 0.98),
                  border: Border(
                    left: BorderSide(
                      color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B9D).withValues(alpha: 0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Backlog header
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.history,
                              color: const Color(0xFFFF6B9D), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'BACKLOG',
                            style: GoogleFonts.pressStart2p(
                              color: const Color(0xFFFF6B9D),
                              fontSize: 10,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() => showBacklog = false),
                            child: Icon(Icons.close,
                                color: Colors.grey[500], size: 18),
                          ),
                        ],
                      ),
                    ),
                    // Messages
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return ChatBubble(message: messages[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDotPulse() {
    return SizedBox(
      width: 30,
      height: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1.0),
            duration: Duration(milliseconds: 600 + (i * 200)),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B9D),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
