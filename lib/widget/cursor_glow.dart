import 'package:flutter/material.dart';

class CursorGlow extends StatefulWidget {
  final Widget child;
  const CursorGlow({super.key, required this.child});

  @override
  State<CursorGlow> createState() => _CursorGlowState();
}

class _CursorGlowState extends State<CursorGlow> {
  final ValueNotifier<Offset> _mousePos = ValueNotifier(Offset.zero);

  @override
  void dispose() {
    _mousePos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasSize = constraints.maxWidth > 0 && constraints.maxHeight > 0;

        return MouseRegion(
          opaque: false,
          hitTestBehavior: HitTestBehavior.translucent,
          onHover: hasSize
              ? (event) {
                  _mousePos.value = event.localPosition;
                }
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              if (hasSize)
                ValueListenableBuilder<Offset>(
                  valueListenable: _mousePos,
                  builder: (context, pos, _) {
                    if (pos == Offset.zero) return const SizedBox.shrink();

                    return Positioned(
                      left: pos.dx - 100,
                      top: pos.dy - 100,
                      child: IgnorePointer(
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.cyanAccent.withOpacity(0.12),
                                Colors.cyanAccent.withOpacity(0.04),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
