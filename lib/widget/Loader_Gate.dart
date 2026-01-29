import 'package:flutter/material.dart';
import '../llm/llm_service.dart';
import 'package:project_test/IntroLoader.dart';
import '../main.dart';
import 'dart:async';

class LoaderGate extends StatefulWidget {
  const LoaderGate({super.key});

  @override
  State<LoaderGate> createState() => _LoaderGateState();
}

class _LoaderGateState extends State<LoaderGate> {
  bool ready = false;

  @override
  void initState() {
    super.initState();
    // Simulate boot time without LLM loading
    Future.delayed(const Duration(seconds: 4), () { // Adjust based on boot messages timing
      setState(() => ready = true);
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
            : const IntroLoader(
                key: ValueKey("loader"),
              ),
      ),
    );
  }
}