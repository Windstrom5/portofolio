import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_test/service/news_scraper.dart';
import 'package:project_test/widget/hud_components.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsSidebarWidget extends StatefulWidget {
  const NewsSidebarWidget({super.key});

  @override
  State<NewsSidebarWidget> createState() => _NewsSidebarWidgetState();
}

class _NewsSidebarWidgetState extends State<NewsSidebarWidget> {
  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  late PageController _pageController;
  Timer? _scrollTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _fetchNews();
    
    // Auto-scroll timer
    _scrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_articles.isNotEmpty && _pageController.hasClients) {
        _currentIndex = (_currentIndex + 1) % _articles.length;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _fetchNews() async {
    final news = await NewsScraper.fetchAllNews();
    if (mounted) {
      setState(() {
        _articles = news;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HUDContainer(
      height: 120.h,
      accentColor: const Color(0xFFFF4500), // Orange/Red for News
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.newspaper, color: const Color(0xFFFF4500), size: 16.sp),
                  SizedBox(width: 8.w),
                  Text(
                    "LIVE NEWS FEED",
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFFFF4500),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              if (!_isLoading)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4500).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    "SYNCED",
                    style: GoogleFonts.vt323(color: const Color(0xFFFF4500), fontSize: 10.sp),
                  ),
                ),
            ],
          ),
          const Divider(color: Color(0x33FF4500)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4500)))
                : _articles.isEmpty
                    ? Center(child: Text("NO DATA", style: GoogleFonts.vt323(color: Colors.white54)))
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: _articles.length,
                        itemBuilder: (context, index) {
                          final article = _articles[index];
                          return _buildNewsItem(article);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(NewsArticle article) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(article.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Container(
        width: 240.w,
        margin: EdgeInsets.only(right: 12.w),
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          border: Border(left: BorderSide(color: const Color(0xFFFF4500).withOpacity(0.5), width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  color: const Color(0xFFFF4500),
                  child: Text(
                    article.source,
                    style: GoogleFonts.vt323(color: Colors.black, fontSize: 10.sp, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_right, color: Colors.white38, size: 14.sp),
              ],
            ),
            SizedBox(height: 4.h),
            Expanded(
              child: Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.teko(
                  color: Colors.white,
                  fontSize: 14.sp,
                  height: 1.1,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
