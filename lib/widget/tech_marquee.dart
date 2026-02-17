import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class TechStackMarquee extends StatefulWidget {
  const TechStackMarquee({super.key});

  @override
  State<TechStackMarquee> createState() => _TechStackMarqueeState();
}

class _TechStackMarqueeState extends State<TechStackMarquee>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;

  final Map<String, IconData> techStack = {
    'Flutter': Icons.flutter_dash,
    'Kotlin': FontAwesomeIcons.android,
    'Vue.js': FontAwesomeIcons.vuejs,
    'Laravel': FontAwesomeIcons.laravel,
    'PostgreSQL': FontAwesomeIcons.database,
    'Firebase': Icons.local_fire_department,
    'Steam': FontAwesomeIcons.steam,
    'Unreal Engine': Icons.gamepad,
    'Docker': FontAwesomeIcons.docker,
    'Unity': FontAwesomeIcons.unity,
    'Python': FontAwesomeIcons.python,
    'Dart': Icons.terminal,
    'C++': Icons.code,
  };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Large multiplication for infinite feel
    final items = [
      ...techStack.entries,
      ...techStack.entries,
      ...techStack.entries,
      ...techStack.entries,
      ...techStack.entries,
    ];

    return SizedBox(
      height: 35.h,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final entry = items[index];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(entry.value,
                    color: Colors.cyanAccent.withOpacity(0.3), size: 14.sp),
                SizedBox(width: 8.w),
                Text(
                  entry.key.toUpperCase(),
                  style: GoogleFonts.vt323(
                    color: Colors.white24,
                    fontSize: 13.sp,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _startScrolling() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;

    _scrollController
        .animateTo(
      maxScroll,
      duration: const Duration(seconds: 80),
      curve: Curves.linear,
    )
        .then((_) {
      if (mounted) {
        _scrollController.jumpTo(0);
        _startScrolling();
      }
    });
  }
}
