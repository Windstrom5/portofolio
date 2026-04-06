import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LinuxContextMenu extends StatelessWidget {
  final Offset position;
  final VoidCallback onClose;
  final Function(String) onAction;

  const LinuxContextMenu({
    super.key,
    required this.position,
    required this.onClose,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          onSecondaryTap: onClose,
          onPanStart: (_) => onClose(),
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Positioned(
          left: position.dx,
          top: position.dy,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 220.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF282a36).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFF6272a4).withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuItem(
                        icon: Icons.terminal,
                        label: 'Open Terminal',
                        onTap: () => onAction('terminal'),
                      ),
                      _buildMenuItem(
                        icon: Icons.person,
                        label: 'View Profile',
                        onTap: () => onAction('profile'),
                      ),
                      _buildMenuItem(
                        icon: Icons.code,
                        label: 'Projects',
                        onTap: () => onAction('projects'),
                      ),
                      _divider(),
                      _buildMenuItem(
                        icon: Icons.volume_up,
                        label: 'Toggle VRM Mute',
                        onTap: () => onAction('mute'),
                      ),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        label: 'System Info',
                        onTap: () => onAction('sysinfo'),
                      ),
                      _divider(),
                      _buildMenuItem(
                        icon: Icons.refresh,
                        label: 'Refresh',
                        onTap: () => onAction('refresh'),
                      ),
                      _buildMenuItem(
                        icon: Icons.close,
                        label: 'Close Menu',
                        onTap: onClose,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: () {
        onTap();
        onClose();
      },
      hoverColor: isDestructive
          ? Colors.red.withOpacity(0.2)
          : const Color(0xFF6272a4).withOpacity(0.4),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isDestructive ? Colors.redAccent : const Color(0xFFbd93f9),
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFFf8f8f2),
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(vertical: 4.h),
      color: const Color(0xFF6272a4).withOpacity(0.2),
    );
  }
}
