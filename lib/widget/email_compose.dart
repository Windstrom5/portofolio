import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class EmailComposeWindow extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback? onSend;
  final String recipient;
  final String subject;
  final String message;

  const EmailComposeWindow({
    super.key,
    required this.onClose,
    this.onSend,
    this.recipient = "myemail@windstrom5.com",
    this.subject = "[COLLABORATION] Project Inquiry",
    this.message =
        "Hello Windstrom5,\n\nI saw your portfolio and would like to discuss a potential project...",
  });

  void _handleSend() {
    if (onSend != null) {
      onSend!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 500.w,
          height: 550.h,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.95),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Fields
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      _buildField("Recipients", recipient),
                      _buildField("Subject", subject),
                      Expanded(
                        child: _buildMessageField(message),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer / Actions
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "New Message",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Icon(Icons.remove, color: Colors.white60, size: 18.sp),
              SizedBox(width: 12.w),
              Icon(Icons.open_in_full, color: Colors.white60, size: 16.sp),
              SizedBox(width: 12.w),
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close, color: Colors.white60, size: 18.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 13.sp,
            ),
          ),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value),
              readOnly: true,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 13.sp,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageField(String initialText) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: TextField(
        controller: TextEditingController(text: initialText),
        maxLines: null,
        style: GoogleFonts.inter(
          color: Colors.white.withOpacity(0.85),
          fontSize: 14.sp,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                "Send",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Icon(Icons.text_format, color: Colors.white60, size: 20.sp),
          SizedBox(width: 12.w),
          Icon(Icons.attach_file, color: Colors.white60, size: 20.sp),
          SizedBox(width: 12.w),
          Icon(Icons.link, color: Colors.white60, size: 20.sp),
          SizedBox(width: 12.w),
          Icon(Icons.insert_emoticon, color: Colors.white60, size: 20.sp),
          const Spacer(),
          Icon(Icons.more_vert, color: Colors.white60, size: 20.sp),
          SizedBox(width: 12.w),
          Icon(Icons.delete_outline, color: Colors.white60, size: 20.sp),
        ],
      ),
    );
  }
}
