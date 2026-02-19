import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class VnDialogueBubble extends StatefulWidget {
  final String text;
  final String? subtitle;
  final String name;
  final VoidCallback? onComplete;
  final bool isSpeaking;

  const VnDialogueBubble({
    super.key,
    required this.text,
    this.subtitle,
    this.name = "Sakura",
    this.onComplete,
    this.isSpeaking = false,
  });

  @override
  State<VnDialogueBubble> createState() => _VnDialogueBubbleState();
}

class _VnDialogueBubbleState extends State<VnDialogueBubble> {
  String _displayedText = "";
  Timer? _typewriterTimer;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  @override
  void didUpdateWidget(VnDialogueBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startTypewriter();
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    super.dispose();
  }

  void _startTypewriter() {
    _typewriterTimer?.cancel();
    setState(() {
      _displayedText = "";
      _charIndex = 0;
    });

    if (widget.text.isEmpty) return;

    _typewriterTimer =
        Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_charIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_charIndex];
          _charIndex++;
        });
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty && !widget.isSpeaking) return const SizedBox();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.8),
              border: Border.all(
                  color: Colors.pinkAccent.withOpacity(0.8), width: 1.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.pinkAccent.withOpacity(0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              widget.name.toUpperCase(),
              style: GoogleFonts.pressStart2p(
                color: Colors.pinkAccent,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ),
          // Dialogue Box
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F18).withOpacity(0.7),
                border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary Text (English)
                  Text(
                    _displayedText,
                    style: GoogleFonts.vt323(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.subtitle != null &&
                      widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    // Subtitle Text (Japanese)
                    Text(
                      widget.subtitle!,
                      style: GoogleFonts.notoSansJp(
                        color: Colors.cyanAccent.withOpacity(0.6),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Cursor / blinking indicator
                  if (_charIndex == widget.text.length)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: _BlinkingIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingIndicator extends StatefulWidget {
  @override
  State<_BlinkingIndicator> createState() => _BlinkingIndicatorState();
}

class _BlinkingIndicatorState extends State<_BlinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child:
          const Icon(Icons.arrow_drop_down, color: Colors.pinkAccent, size: 24),
    );
  }
}
