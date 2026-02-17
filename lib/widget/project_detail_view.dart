import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../model/project_model.dart';
import 'hud_components.dart'; // Reuse HUD styling if available or standard widgets

class ProjectDetailView extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailView({Key? key, required this.project}) : super(key: key);

  @override
  State<ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends State<ProjectDetailView> {
  bool _isInstalling = false;
  double _installProgress = 0.0;
  late bool _isInstalled;

  @override
  void initState() {
    super.initState();
    _isInstalled = widget.project.isInstalled;
  }

  Future<void> _handlePrimaryAction() async {
    if (_isInstalled) {
      if (widget.project.demoUrl != null) {
        // Open Demo
        final Uri uri = Uri.parse(widget.project.demoUrl!);
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      } else if (widget.project.repoUrl != null) {
        final Uri uri = Uri.parse(widget.project.repoUrl!);
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      }
    } else {
      // Fake Install
      setState(() => _isInstalling = true);

      // Simulate download
      for (int i = 0; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() => _installProgress = i / 100);
      }

      if (mounted) {
        setState(() {
          _isInstalling = false;
          _isInstalled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${widget.project.title} installed successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: CustomScrollView(
        slivers: [
          // --- Premium Header Banner ---
          SliverAppBar(
            expandedHeight: 250.h,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.project.bannerUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                widget.project.title.toUpperCase(),
                style: GoogleFonts.orbitron(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.cyanAccent),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // --- App Info Header ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 100.r,
                        height: 100.r,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.r),
                          image: DecorationImage(
                              image: NetworkImage(widget.project.iconUrl),
                              fit: BoxFit.cover),
                          border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.2),
                                blurRadius: 20),
                          ],
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.project.title,
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "Windstrom5 / ${widget.project.platform}",
                              style: GoogleFonts.vt323(
                                color: Colors.cyanAccent,
                                fontSize: 18.sp,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                if (widget.project.status ==
                                        ProjectStatus.development &&
                                    widget.project.estimatedCompletion !=
                                        null) ...[
                                  _StatItem(
                                      label: "ESTIMATED",
                                      value:
                                          widget.project.estimatedCompletion!),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  // Action Buttons
                  if (_isInstalling)
                    _buildInstallingState()
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildPrimaryButton(),
                        ),
                        if (widget.project.repoUrl != null) ...[
                          SizedBox(width: 12.w),
                          _buildSourceButton(),
                        ],
                      ],
                    ),

                  SizedBox(height: 48.h),

                  // Screenshots
                  Text(
                    "PREVIEW",
                    style: GoogleFonts.orbitron(
                      color: Colors.white38,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildScreenshotList(),

                  SizedBox(height: 48.h),

                  // README Style Description
                  _buildReadmeSection(),

                  SizedBox(height: 48.h),

                  // Tech Stack Tags
                  _buildTechStackSection(),

                  SizedBox(height: 80.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallingState() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: LinearProgressIndicator(
            value: _installProgress,
            minHeight: 12.h,
            backgroundColor: Colors.white10,
            color: Colors.cyanAccent,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          "DOWNLOADING FROM REMOTE SERVER: ${(_installProgress * 100).toInt()}%",
          style: GoogleFonts.vt323(color: Colors.cyanAccent, fontSize: 14.sp),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    return InkWell(
      onTap: _handlePrimaryAction,
      child: Container(
        height: 55.h,
        decoration: BoxDecoration(
          color:
              _isInstalled ? Colors.white.withOpacity(0.05) : Colors.cyanAccent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.cyanAccent),
          boxShadow: [
            if (!_isInstalled)
              BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15),
          ],
        ),
        child: Center(
          child: Text(
            _isInstalled ? "LAUNCH SIMULATION" : "GET / INSTALL",
            style: GoogleFonts.orbitron(
              color: _isInstalled ? Colors.cyanAccent : Colors.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton() {
    return InkWell(
      onTap: () async {
        final Uri uri = Uri.parse(widget.project.repoUrl!);
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
      child: Container(
        height: 55.h,
        width: 60.w,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white24),
        ),
        child: const Icon(FontAwesomeIcons.github, color: Colors.white70),
      ),
    );
  }

  Widget _buildScreenshotList() {
    return SizedBox(
      height: 220.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (c, i) => SizedBox(width: 16.w),
        itemBuilder: (c, i) => Container(
          width: 320.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white10),
            image: DecorationImage(
              image: NetworkImage(widget.project.bannerUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadmeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notes, color: Colors.cyanAccent, size: 20),
            SizedBox(width: 12.w),
            Text(
              "README.md",
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Divider(color: Colors.white12),
        SizedBox(height: 16.h),
        Text(
          widget.project.description,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 15.sp,
            height: 1.6,
            wordSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTechStackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "DEPENDENCIES / TECH STACK",
          style: GoogleFonts.orbitron(
            color: Colors.white38,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: widget.project.techStack.map((tech) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
              ),
              child: Text(
                tech.toUpperCase(),
                style: GoogleFonts.vt323(
                  color: Colors.cyanAccent,
                  fontSize: 15.sp,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 10.sp),
        ),
        Text(
          value,
          style: GoogleFonts.vt323(color: Colors.white, fontSize: 18.sp),
        ),
      ],
    );
  }
}
