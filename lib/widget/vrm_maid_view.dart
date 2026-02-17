import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/widgets.dart';
import 'dart:js' as js;

class VrmController {
  _VrmMaidViewState? _state;

  Function()? onSpeechStart;
  Function()? onSpeechEnd;
  Function()? onReady;

  void attach(_VrmMaidViewState state) {
    _state = state;
  }

  void detach() {
    _state = null;
  }

  void speak(String text, {String? english}) {
    _state?.speak(text, english: english);
  }

  void setEmotion(String emotion) {
    _state?.setEmotion(emotion);
  }
}

class VrmMaidView extends StatefulWidget {
  final Function(String, {String? english})? onSpeak;
  final VoidCallback? onReady;
  final VrmController? controller;

  const VrmMaidView({
    super.key,
    this.onSpeak,
    this.onReady,
    this.controller,
  });

  @override
  State<VrmMaidView> createState() => _VrmMaidViewState();
}

class _VrmMaidViewState extends State<VrmMaidView> {
  html.IFrameElement? _iframe;
  bool _isReady = false;
  final List<Map<String, dynamic>> _pendingMessages = [];

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(this);

    // Register unique factory (Flutter will give each instance its own viewId)
    ui.platformViewRegistry.registerViewFactory(
      'vrm-maid-${hashCode}',
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'vrm/index.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'autoplay';

        _iframe = iframe; // Store reference

        iframe.onLoad.listen((_) {
          // Optional: you can try to detect load here too
        });
        return iframe;
      },
    );

    html.window.addEventListener('message', js.allowInterop((event) {
      final e = event as html.MessageEvent;
      final data = e.data;
      if (data is Map) {
        if (data['type'] == 'vrm_ready') {
          if (mounted) {
            print(
                "VRM: Ready received for viewId \$${hashCode}"); // Escaped dollar sign
            setState(() => _isReady = true);
            _flushQueue();
            widget.onReady?.call();
            widget.controller?.onReady?.call();
          }
        } else if (data['type'] == 'speechStart') {
          widget.controller?.onSpeechStart?.call();
        } else if (data['type'] == 'speechEnd') {
          widget.controller?.onSpeechEnd?.call();
        }
      }
    }));
  }

  @override
  void dispose() {
    widget.controller?.detach();
    super.dispose();
  }

  void _flushQueue() {
    if (!_isReady || _iframe == null || _iframe!.contentWindow == null) return;

    for (final msg in _pendingMessages) {
      _postMessage(msg);
    }
    _pendingMessages.clear();
  }

  void speak(String text, {String? english}) {
    final msg = english != null
        ? {'type': 'speak', 'japanese': text, 'english': english}
        : {'type': 'speak', 'text': text};

    if (_isReady) {
      _postMessage(msg);
    } else {
      _pendingMessages.add(msg);
    }
    widget.onSpeak?.call(text, english: english);
  }

  void setEmotion(String emotion) {
    final msg = {'type': 'emotion', 'emotion': emotion};
    if (_isReady) {
      _postMessage(msg);
    } else {
      _pendingMessages.add(msg);
    }
  }

  void _postMessage(Map<String, dynamic> msg) {
    try {
      if (_iframe == null || _iframe!.contentWindow == null) return;
      _iframe!.contentWindow!.postMessage(msg, '*');
    } catch (e) {
      print('Failed to send to VRM: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: 'vrm-maid-${hashCode}');
  }
}
