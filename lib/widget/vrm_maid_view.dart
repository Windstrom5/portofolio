import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/widgets.dart';

class VrmMaidView extends StatelessWidget {
  VrmMaidView({super.key}) {
    ui.platformViewRegistry.registerViewFactory(
      'vrm-maid',
      (int viewId) => html.IFrameElement()
        ..src = 'vrm/index.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: 'vrm-maid');
  }
}