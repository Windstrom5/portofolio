import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/project_model.dart';
import 'project_detail_view.dart';

class ProjectStoreApp extends StatefulWidget {
  const ProjectStoreApp({Key? key}) : super(key: key);

  @override
  State<ProjectStoreApp> createState() => _ProjectStoreAppState();
}

class _ProjectStoreAppState extends State<ProjectStoreApp> {
  final ScrollController _scrollController = ScrollController();
  String _selectedLanguage = 'All';
  String _selectedPlatform = 'All';
  String _selectedStatus = 'All';

  List<ProjectModel> get _filteredProjects {
    return allProjects.where((project) {
      final matchesLanguage = _selectedLanguage == 'All' ||
          project.primaryLanguage == _selectedLanguage;
      final matchesPlatform =
          _selectedPlatform == 'All' || project.platform == _selectedPlatform;
      final matchesStatus = _selectedStatus == 'All' ||
          project.status.name.toLowerCase() == _selectedStatus.toLowerCase();
      return matchesLanguage && matchesPlatform && matchesStatus;
    }).toList();
  }

  List<String> get _languages =>
      ['All', ...allProjects.map((p) => p.primaryLanguage).toSet()];
  List<String> get _platforms =>
      ['All', ...allProjects.map((p) => p.platform).toSet()];
  List<String> get _statuses => ['All', 'Production', 'Development', 'Legacy'];

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProjects;
    return Column(
      children: [
        // --- Store Header ---
        _buildStoreHeader(),

        // --- Main Content ---
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured Banner
                _buildFeaturedBanner(),

                SizedBox(height: 24.h),

                // Section Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "LATEST RELEASES",
                      style: GoogleFonts.orbitron(
                        color: Colors.cyanAccent,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (_selectedLanguage != 'All' ||
                        _selectedPlatform != 'All' ||
                        _selectedStatus != 'All')
                      Text(
                        "FILTERED: $_selectedLanguage / $_selectedPlatform / $_selectedStatus",
                        style: GoogleFonts.vt323(
                          color: Colors.cyanAccent.withOpacity(0.5),
                          fontSize: 12.sp,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Project Grid
                filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          child: Text(
                            "NO PROJECTS MATCH YOUR FILTERS",
                            style: GoogleFonts.orbitron(
                              color: Colors.white38,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _calculateCrossAxisCount(context),
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 16.r,
                          mainAxisSpacing: 16.r,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _ProjectStoreCard(project: filtered[index]);
                        },
                      ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildStoreHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border:
            Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Icon(FontAwesomeIcons.bagShopping,
              color: const Color(0xFFDA291C), size: 24.sp),
          SizedBox(width: 12.w),
          Text(
            "WINDSTROM5 PROJECT",
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          // Search Bar (Visual)
          Container(
            width: 250.w,
            height: 35.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.white70, size: 16.sp),
                SizedBox(width: 8.w),
                Text(
                  "Search apps & games...",
                  style:
                      GoogleFonts.vt323(color: Colors.white38, fontSize: 16.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 20.w),
          // Filter Button
          InkWell(
            onTap: _showFilterDialog,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: (_selectedLanguage != 'All' ||
                        _selectedPlatform != 'All' ||
                        _selectedStatus != 'All')
                    ? Colors.cyanAccent.withOpacity(0.3)
                    : Colors.cyanAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list,
                      color: Colors.cyanAccent, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text(
                    "FILTER",
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.cyanAccent, width: 1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            title: Text(
              "FILTER PROJECTS",
              style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("DEVELOPMENT STATUS",
                    style: GoogleFonts.vt323(
                        color: Colors.white70, fontSize: 14.sp)),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _statuses.map((stat) {
                    final isSelected = _selectedStatus == stat;
                    return ChoiceChip(
                      label: Text(stat.toUpperCase()),
                      selected: isSelected,
                      onSelected: (val) {
                        setDialogState(() => _selectedStatus = stat);
                        setState(() {});
                      },
                      backgroundColor: Colors.black,
                      selectedColor: Colors.cyanAccent,
                      labelStyle: GoogleFonts.vt323(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 14.sp,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20.h),
                Text("PROGRAMMING LANGUAGE",
                    style: GoogleFonts.vt323(
                        color: Colors.white70, fontSize: 14.sp)),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _languages.map((lang) {
                    final isSelected = _selectedLanguage == lang;
                    return ChoiceChip(
                      label: Text(lang),
                      selected: isSelected,
                      onSelected: (val) {
                        setDialogState(() => _selectedLanguage = lang);
                        setState(() {});
                      },
                      backgroundColor: Colors.black,
                      selectedColor: Colors.cyanAccent,
                      labelStyle: GoogleFonts.vt323(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 14.sp,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20.h),
                Text("PLATFORM",
                    style: GoogleFonts.vt323(
                        color: Colors.white70, fontSize: 14.sp)),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _platforms.map((plat) {
                    final isSelected = _selectedPlatform == plat;
                    return ChoiceChip(
                      label: Text(plat),
                      selected: isSelected,
                      onSelected: (val) {
                        setDialogState(() => _selectedPlatform = plat);
                        setState(() {});
                      },
                      backgroundColor: Colors.black,
                      selectedColor: Colors.cyanAccent,
                      labelStyle: GoogleFonts.vt323(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 14.sp,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedLanguage = 'All';
                    _selectedPlatform = 'All';
                    _selectedStatus = 'All';
                  });
                  Navigator.pop(context);
                },
                child: Text("RESET",
                    style: GoogleFonts.orbitron(
                        color: Colors.redAccent, fontSize: 12.sp)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("CLOSE",
                    style: GoogleFonts.orbitron(
                        color: Colors.white, fontSize: 12.sp)),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildFeaturedBanner() {
    final featured = allProjects.firstWhere((p) => p.id == 'portofolio',
        orElse: () => allProjects[0]);

    return GestureDetector(
      onTap: () => _openProjectDetail(context, featured),
      child: Container(
        height: 250.h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          image: DecorationImage(
            image: NetworkImage(featured.bannerUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5), BlendMode.darken),
          ),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 24.w,
              bottom: 24.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDA291C),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      "FEATURED APP",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    featured.title.toUpperCase(),
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        BoxShadow(
                            color: Colors.black,
                            blurRadius: 10,
                            offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: 400.w,
                    child: Text(
                      featured.shortDescription,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProjectDetail(BuildContext context, ProjectModel project) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => ProjectDetailView(project: project)),
    );
  }
}

class _ProjectStoreCard extends StatelessWidget {
  final ProjectModel project;

  const _ProjectStoreCard({Key? key, required this.project}) : super(key: key);

  Color _getStatusColor() {
    switch (project.status) {
      case ProjectStatus.production:
        return Colors.greenAccent;
      case ProjectStatus.development:
        return Colors.orangeAccent;
      case ProjectStatus.legacy:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (project.status) {
      case ProjectStatus.production:
        return "STABLE";
      case ProjectStatus.development:
        return "WIP";
      case ProjectStatus.legacy:
        return "LEGACY";
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final url = project.demoUrl ?? project.repoUrl;
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: Colors.black,
          border:
              Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.05),
              offset: const Offset(4, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Info Area (Left)
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          color: _getStatusColor(),
                          child: Text(
                            _getStatusLabel(),
                            style: GoogleFonts.orbitron(
                              color: Colors.black,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            project.title.toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      project.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.sp,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _TechChip(label: project.techStack.first),
                        if (project.techStack.length > 1) ...[
                          SizedBox(width: 4.w),
                          _TechChip(label: project.techStack[1]),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Banner Area (Right)
            Container(
              width: 120.w,
              height: double.infinity,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.white10)),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    project.bannerUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                        color: Colors.grey.shade900,
                        child: Icon(Icons.broken_image, color: Colors.white54)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                  // Small Icon Overlay
                  Positioned(
                    bottom: 8.h,
                    right: 8.w,
                    child: Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                        image: DecorationImage(
                          image: NetworkImage(project.iconUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechChip extends StatelessWidget {
  final String label;
  const _TechChip({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.vt323(
          color: Colors.white54,
          fontSize: 10.sp,
        ),
      ),
    );
  }
}
