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
  bool _isComplete = false;

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
      _isComplete = false;
    });

    if (widget.text.isEmpty) return;

    _typewriterTimer =
        Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (_charIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_charIndex];
          _charIndex++;
        });
      } else {
        timer.cancel();
        setState(() => _isComplete = true);
        widget.onComplete?.call();
      }
    });
  }

  void _skipToEnd() {
    if (_isComplete) return;
    _typewriterTimer?.cancel();
    setState(() {
      _displayedText = widget.text;
      _charIndex = widget.text.length;
      _isComplete = true;
    });
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty && !widget.isSpeaking) return const SizedBox();

    // Tap anywhere on the dialogue to skip typewriter
    return GestureDetector(
      onTap: _skipToEnd,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: widget.text.isNotEmpty ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary Text (English) with typewriter
            Text(
              _displayedText,
              style: GoogleFonts.ubuntu(
                color: Colors.white,
                fontSize: 18,
                height: 1.4,
                letterSpacing: 0.5,
              ),
            ),
            if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              // Subtitle Text (Japanese)
              AnimatedOpacity(
                opacity: _isComplete ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 400),
                child: Text(
                  widget.subtitle!,
                  style: GoogleFonts.kosugiMaru(
                    color: Colors.cyanAccent.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.5,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
            // Blinking "click to continue" indicator
            if (_isComplete)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _BlinkingIndicator(),
                ),
              ),
            // "Click to skip" hint while typing
            if (!_isComplete && _displayedText.isNotEmpty)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '▶ skip',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white.withValues(alpha: 0.15),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '▼',
            style: GoogleFonts.vt323(
              color: const Color(0xFFFF6B9D),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
