import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/web_utils.dart';
import '../llm/llm_service.dart';
import '../llm/model_config.dart';

class VrmController {
  _VrmMaidViewState? _state;

  Function()? onSpeechStart;
  Function()? onSpeechEnd;
  Function()? onReady;
  FutureOr<bool> Function(String text)? onSpeechResult;
  Function(String text, {String? english, String? emotion})? onSpeakHook;

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

  void setActivity(String activity) {
    _state?.setActivity(activity);
  }

  void pat() {
    _state?.pat();
  }

  void wave() {
    _state?.wave();
  }

  void dance() {
    _state?.dance();
  }

  void startMic() {
    _state?._startListening();
  }

  void stopMic() {
    _state?._stopListening();
  }

  void toggleMute() {
    _state?._toggleMute();
  }
}

class VrmMaidView extends StatefulWidget {
  final Function(String, {String? english})? onSpeak;
  final VoidCallback? onReady;
  final VrmController? controller;

  /// Callback when mic captures speech text — parent can use this.
  /// If it returns true, the internal LLM call is skipped.
  final FutureOr<bool> Function(String transcript)? onMicResult;
  final bool showVoiceControls; // Added to hide voice UI in text chat

  const VrmMaidView({
    super.key,
    this.onSpeak,
    this.onReady,
    this.controller,
    this.onMicResult,
    this.showVoiceControls = true,
  });

  @override
  State<VrmMaidView> createState() => _VrmMaidViewState();
}

class _VrmMaidViewState extends State<VrmMaidView> {
  dynamic _iframe;
  bool _isReady = false;
  final List<Map<String, dynamic>> _pendingMessages = [];

  // Mic & Mute state
  bool _isMicActive = false;
  bool _isMuted = false;
  bool _isMicProcessing = false;

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
          pointerEvents: 'none',
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

    // Register the speech result callback in JS
    _registerSpeechCallback();
  }

  void _registerSpeechCallback() {
    try {
      WebUtils.setProperty(WebUtils.jsContext, 'onSpeechResult',
          WebUtils.allowInterop((String transcript) async {
        if (mounted) {
          setState(() {
            _isMicActive = false;
            _isMicProcessing = true;
          });

          bool consumed = false;
          
          // 1. Check widget callback
          if (widget.onMicResult != null) {
            final res = widget.onMicResult!(transcript);
            if (res is Future<bool>) {
              consumed = await res;
            } else {
              consumed = res;
            }
          }

          // 2. Check controller callback
          if (widget.controller?.onSpeechResult != null) {
            final res = widget.controller!.onSpeechResult!(transcript);
            if (res is Future<bool>) {
              consumed = (await res) || consumed;
            } else {
              consumed = res || consumed;
            }
          }

          if (consumed) {
            if (mounted) {
              setState(() => _isMicProcessing = false);
            }
            return;
          }

          // 3. Fallback to LLM if not consumed
          _handleMicTranscript(transcript);
        }
      }));
    } catch (e) {
      print('VRM: Failed to register speech callback: $e');
    }
  }

  Future<void> _handleMicTranscript(String transcript) async {
    if (transcript.trim().isEmpty) {
      setState(() => _isMicProcessing = false);
      return;
    }

    try {
      final reply = await LlmService.ask(transcript);
      if (mounted) {
        if (widget.controller?.onSpeakHook != null) {
          widget.controller!.onSpeakHook!(reply, english: reply);
        } else {
          speak(reply);
        }
        setState(() => _isMicProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isMicProcessing = false);
      }
    }
  }

  void _startListening() {
    try {
      WebUtils.callMethod(WebUtils.jsContext, 'startListening', []);
      setState(() => _isMicActive = true);
    } catch (e) {
      print('VRM: Failed to start listening: $e');
    }
  }

  void _stopListening() {
    try {
      WebUtils.callMethod(WebUtils.jsContext, 'stopListening', []);
      setState(() => _isMicActive = false);
    } catch (e) {
      print('VRM: Failed to stop listening: $e');
    }
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    final msg = {'type': 'mute', 'muted': _isMuted};
    if (_isReady) {
      _postMessage(msg);
    }
    // Also stop/cancel current speech if muting
    if (_isMuted) {
      try {
        WebUtils.callMethod(WebUtils.jsContext, 'stopSpeaking', []);
      } catch (_) {}
    }
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

  void setActivity(String activity) {
    final msg = {'type': 'activity', 'activity': activity};
    if (_isReady) {
      _postMessage(msg);
    } else {
      _pendingMessages.add(msg);
    }
  }

  void pat() {
    final msg = {'type': 'pat'};
    if (_isReady) {
      _postMessage(msg);
    } else {
      _pendingMessages.add(msg);
    }
  }

  void wave() {
    final msg = {'type': 'wave'};
    if (_isReady) {
      _postMessage(msg);
    } else {
      _pendingMessages.add(msg);
    }
  }

  void dance() {
    final msg = {'type': 'dance'};
    if (_isReady) {
      _postMessage(msg);
    } else {
      _pendingMessages.add(msg);
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
    return Stack(
      children: [
        // VRM iframe (Pointer events disabled in WebUtils to fix overlapping hit-tests)
        HtmlElementView(viewType: 'vrm-maid-${hashCode}'),

        // Flutter Interaction Overlay for VRM (Pats)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) {
              final RenderBox? box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final localPos = box.globalToLocal(details.globalPosition);
                // Top 45% triggers pat
                if (localPos.dy < box.size.height * 0.45) {
                  pat();
                }
              }
            },
          ),
        ),

        // Floating mic & mute controls
        if (ModelConfig.activeModelId != 'none' && widget.showVoiceControls)
          Positioned(
            top:
                20, // Moved from bottom to top to avoid overlapping character hands
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mute toggle
                _buildControlButton(
                  icon: _isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  isActive: _isMuted,
                  activeColor: const Color(0xFFFF6B9D),
                  inactiveColor: Colors.white.withValues(alpha: 0.7),
                  tooltip: _isMuted ? 'Unmute' : 'Mute',
                  onTap: _toggleMute,
                ),
                const SizedBox(height: 10),
                // Mic push-to-talk button
                _buildMicButton(),
              ],
            ),
          ),
        // Mic status indicator at top
        if (_isMicActive || _isMicProcessing)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isMicActive
                        ? [const Color(0xFFFF6B9D), const Color(0xFFFF4081)]
                        : [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: (_isMicActive
                              ? const Color(0xFFFF6B9D)
                              : const Color(0xFF4FACFE))
                          .withValues(alpha: 0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                   mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulseIcon(
                      icon: _isMicActive ? Icons.mic_rounded : Icons.sync_rounded,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isMicActive ? 'LISTENING' : 'PROCESSING',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onLongPressStart: (_) => _startListening(),
      onLongPressEnd: (_) => _stopListening(),
      onTap: () {
        // Single tap: toggle listen
        if (_isMicActive) {
          _stopListening();
        } else {
          _startListening();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _isMicActive ? 56 : 48,
        height: _isMicActive ? 56 : 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _isMicActive
              ? const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFF4081)],
                )
              : LinearGradient(
                  colors: [
                    const Color(0xFF1A1A2E).withValues(alpha: 0.9),
                    const Color(0xFF12121F).withValues(alpha: 0.9),
                  ],
                ),
          border: Border.all(
            color: _isMicActive
                ? const Color(0xFFFF6B9D)
                : Colors.white.withValues(alpha: 0.2),
            width: _isMicActive ? 2 : 1.5,
          ),
          boxShadow: _isMicActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Center(
          child: Icon(
            _isMicActive ? Icons.mic : Icons.mic_none_rounded,
            color: _isMicActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
            size: _isMicActive ? 26 : 22,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? activeColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.6),
            border: Border.all(
              color: isActive
                  ? activeColor.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Icon(
              icon,
              color: isActive ? activeColor : Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseIcon extends StatefulWidget {
  final IconData icon;
  const _PulseIcon({required this.icon});

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Icon(widget.icon, color: Colors.white, size: 16),
    );
  }
}
