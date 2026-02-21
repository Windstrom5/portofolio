import 'package:flutter/widgets.dart';
import '../utils/web_utils.dart';

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

  void speak(String text, {String? english, String? emotion}) {
    _state?.speak(text, english: english, emotion: emotion);
  }

  void setEmotion(String emotion) {
    _state?.setEmotion(emotion);
  }

  void lookAt(double x, double y) {
    _state?.lookAt(x, y);
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
  dynamic _iframe;
  bool _isReady = false;
  final List<Map<String, dynamic>> _pendingMessages = [];

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(this);

    // Register unique factory
    WebUtils.registerViewFactory(
      'vrm-maid-${hashCode}',
      (int viewId, {Object? params}) {
        final iframe = WebUtils.createIFrameElement(
          src: 'vrm/index.html?viewId=${hashCode}',
          border: 'none',
          width: '100%',
          height: '100%',
          allow: 'autoplay',
        );

        _iframe = iframe;
        return iframe;
      },
    );

    WebUtils.addWindowEventListener('message', (event) {
      try {
        final data = WebUtils.getProperty(event, 'data');
        if (data == null) return;

        // Extract type and other fields using WebUtils to handle JS/Dart types
        String? type;
        if (data is Map) {
          type = data['type'];
        } else {
          try {
            type = WebUtils.getProperty(data, 'type')?.toString();
          } catch (_) {}
        }

        if (type == 'vrm_ready') {
          if (mounted) {
            print("VRM: Ready received for viewId ${hashCode}");
            setState(() => _isReady = true);
            _flushQueue();
            widget.onReady?.call();
            widget.controller?.onReady?.call();
          }
        } else if (type == 'speechStart') {
          widget.controller?.onSpeechStart?.call();
        } else if (type == 'speechEnd') {
          widget.controller?.onSpeechEnd?.call();
        }
      } catch (e) {
        // Silently fail for non-matching messages
      }
    });
  }

  @override
  void dispose() {
    widget.controller?.detach();
    super.dispose();
  }

  void _flushQueue() {
    if (!_isReady || _iframe == null) return;

    for (final msg in _pendingMessages) {
      _postMessage(msg);
    }
    _pendingMessages.clear();
  }

  void speak(String text, {String? english, String? emotion}) {
    if (emotion != null) {
      setEmotion(emotion);
    }
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

  void lookAt(double x, double y) {
    // x, y should be normalized -1.0 to 1.0
    // Don't queue lookAt messages if not ready, they are real-time
    if (_isReady) {
      _postMessage({'type': 'control', 'x': x, 'y': y});
    }
  }

  void _postMessage(Map<String, dynamic> msg) {
    try {
      if (_iframe == null) return;
      final contentWindow = WebUtils.getProperty(_iframe, 'contentWindow');
      if (contentWindow != null) {
        msg['targetId'] = '${hashCode}';
        WebUtils.callMethod(
            contentWindow, 'postMessage', [WebUtils.jsify(msg), '*']);
      }
    } catch (e) {
      print('Failed to send to VRM: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: 'vrm-maid-${hashCode}');
  }
}
