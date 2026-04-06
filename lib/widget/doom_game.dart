import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/web_utils.dart';

class DoomGame extends StatefulWidget {
  final Function(String, {String? english, String? emotion}) onSpeak;
  
  const DoomGame({super.key, required this.onSpeak});

  @override
  State<DoomGame> createState() => _DoomGameState();
}

class _DoomGameState extends State<DoomGame> {
  final String _viewId = 'doom-engine-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _registerFactory();
    _startGreeting();
  }

  void _registerFactory() {
    WebUtils.registerViewFactory(
      _viewId,
      (int viewId, {Object? params}) {
        final iframe = WebUtils.createIFrameElement(
          src: 'doom/index.html',
          border: 'none',
          width: '100%',
          height: '100%',
          allow: 'autoplay; keyboard-focus-at-startup',
        );
        return iframe;
      },
    );
  }

  void _startGreeting() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        widget.onSpeak(
          "地獄へようこそ、マリーン。銃を手に取れ！",
          english: "Welcome to Hell, Marine. Pick up your weapon and exterminate the infestation!",
          emotion: "angry"
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}
