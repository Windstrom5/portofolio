import 'package:flutter/material.dart';
import '../llm/llm_service.dart';
import 'package:project_test/IntroLoader.dart';
import '../main.dart';

class LoaderGate extends StatefulWidget {
  const LoaderGate({super.key});

  @override
  State<LoaderGate> createState() => _LoaderGateState();
}

class _LoaderGateState extends State<LoaderGate> {
  int progress = 0;
  bool ready = false;

  @override
  void initState() {
    super.initState();

    LlmService.init((p) {
      setState(() => progress = p);
      if (p == 100) {
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() => ready = true);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: ready
            ? const HomePage(key: ValueKey("home"))
            : IntroLoader(
                key: const ValueKey("loader"),
                progress: progress,
              ),
      ),
    );
  }
}
