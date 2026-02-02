import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/widgets.dart';
import 'dart:js' as js;

class VrmMaidView extends StatefulWidget {
  final Function(String)?
      onSpeak; // Optional: if you want this widget to speak directly

  const VrmMaidView({
    super.key,
    this.onSpeak,
  });

  @override
  State<VrmMaidView> createState() => _VrmMaidViewState();
}

class _VrmMaidViewState extends State<VrmMaidView> {
  html.IFrameElement? _iframe;
  bool _isReady = false;
  final List<String> _pendingMessages = [];

  @override
  void initState() {
    super.initState();

    // Register unique factory (Flutter will give each instance its own viewId)
    ui.platformViewRegistry.registerViewFactory(
      'vrm-maid-${hashCode}', // ← unique per instance to avoid conflicts
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'vrm/index.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'autoplay'; // helpful for voice in some browsers

        iframe.onLoad.listen((_) {
          // Optional: you can try to detect load here too
        });

        // Defer setState to after the current frame to avoid calling during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _iframe = iframe);
          }
        });
        return iframe;
      },
    );

    // Global listener for 'vrm_ready' messages from any iframe
    html.window.addEventListener('message', js.allowInterop((event) {
      final e = event as html.MessageEvent;
      final data = e.data;
      if (data is Map && data['type'] == 'vrm_ready') {
        if (mounted) {
          setState(() => _isReady = true);
          _flushQueue();
        }
      }
    }));
  }

  void _flushQueue() {
    if (!_isReady || _iframe == null || _iframe!.contentWindow == null) return;

    for (final text in _pendingMessages) {
      _send(text);
    }
    _pendingMessages.clear();
  }

  void speak(String text) {
    if (_isReady && _iframe != null && _iframe!.contentWindow != null) {
      _send(text);
    } else {
      _pendingMessages.add(text);
    }

    // Also forward to external callback if provided
    widget.onSpeak?.call(text);
  }

  void _send(String text) {
    try {
      if (_iframe == null || _iframe!.contentWindow == null) {
        print('Iframe or contentWindow not available');
        _pendingMessages.add(text);
        return;
      }

      // Use dart:html's native postMessage - much simpler and more reliable
      _iframe!.contentWindow!.postMessage({
        'type': 'speak',
        'text': text,
      }, '*');
    } catch (e, stack) {
      print('Failed to send to VRM: $e');
      print('Stack: $stack');
      _pendingMessages.add(text); // retry later
    }
  }

  @override
  void dispose() {
    // Optional: clean up global listener if needed (but usually safe to leave)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: 'vrm-maid-${hashCode}');
  }
}
