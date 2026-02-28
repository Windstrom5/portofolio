import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/web_utils.dart';

/// ─────────────────────────────────────────────────
///  IMAGE LAB — Client-side image processing app
///  7 features, no backend, cyberpunk retro UI
/// ─────────────────────────────────────────────────

enum ImageFeature {
  grayscale,
  sepia,
  invert,
  brightness,
  contrast,
  blur,
  pixelate,
}

class _FeatureMeta {
  final String label;
  final IconData icon;
  final Color color;
  final bool hasSlider;
  final double sliderMin;
  final double sliderMax;
  final double sliderDefault;
  final String sliderLabel;

  const _FeatureMeta({
    required this.label,
    required this.icon,
    required this.color,
    this.hasSlider = false,
    this.sliderMin = 0,
    this.sliderMax = 1,
    this.sliderDefault = 0.5,
    this.sliderLabel = '',
  });
}

const Map<ImageFeature, _FeatureMeta> _featureMeta = {
  ImageFeature.grayscale: _FeatureMeta(
    label: 'GRAYSCALE',
    icon: Icons.filter_b_and_w,
    color: Colors.grey,
  ),
  ImageFeature.sepia: _FeatureMeta(
    label: 'SEPIA',
    icon: Icons.filter_vintage,
    color: Color(0xFFD4A574),
  ),
  ImageFeature.invert: _FeatureMeta(
    label: 'INVERT',
    icon: Icons.invert_colors,
    color: Colors.purpleAccent,
  ),
  ImageFeature.brightness: _FeatureMeta(
    label: 'BRIGHTNESS',
    icon: Icons.brightness_6,
    color: Colors.amberAccent,
    hasSlider: true,
    sliderMin: -100,
    sliderMax: 100,
    sliderDefault: 30,
    sliderLabel: 'LEVEL',
  ),
  ImageFeature.contrast: _FeatureMeta(
    label: 'CONTRAST',
    icon: Icons.contrast,
    color: Colors.orangeAccent,
    hasSlider: true,
    sliderMin: -100,
    sliderMax: 100,
    sliderDefault: 30,
    sliderLabel: 'FACTOR',
  ),
  ImageFeature.blur: _FeatureMeta(
    label: 'BLUR',
    icon: Icons.blur_on,
    color: Colors.lightBlueAccent,
    hasSlider: true,
    sliderMin: 1,
    sliderMax: 20,
    sliderDefault: 5,
    sliderLabel: 'RADIUS',
  ),
  ImageFeature.pixelate: _FeatureMeta(
    label: 'PIXELATE',
    icon: Icons.grid_on,
    color: Colors.greenAccent,
    hasSlider: true,
    sliderMin: 2,
    sliderMax: 40,
    sliderDefault: 10,
    sliderLabel: 'BLOCK SIZE',
  ),
};

class ImageProcessor extends StatefulWidget {
  const ImageProcessor({super.key});

  @override
  State<ImageProcessor> createState() => _ImageProcessorState();
}

class _ImageProcessorState extends State<ImageProcessor>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────
  Uint8List? _originalBytes;
  ui.Image? _originalImage;
  Uint8List? _processedBytes;
  ui.Image? _processedImage;

  ImageFeature? _selectedFeature;
  final Map<ImageFeature, double> _sliderValues = {};
  bool _isProcessing = false;
  String? _fileName;

  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    // Init slider defaults
    for (final f in ImageFeature.values) {
      _sliderValues[f] = _featureMeta[f]!.sliderDefault;
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _originalImage?.dispose();
    _processedImage?.dispose();
    super.dispose();
  }

  // ── Pick File ──────────────────────────────
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final image = await _decodeImage(bytes);
      setState(() {
        _originalBytes = bytes;
        _originalImage = image;
        _processedBytes = null;
        _processedImage?.dispose();
        _processedImage = null;
        _selectedFeature = null;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  // ── Apply Feature ──────────────────────────
  Future<void> _applyFeature(ImageFeature feature) async {
    if (_originalImage == null) return;
    setState(() {
      _selectedFeature = feature;
      _isProcessing = true;
    });

    final sliderVal =
        _sliderValues[feature] ?? _featureMeta[feature]!.sliderDefault;
    final result = await _processImage(_originalImage!, feature, sliderVal);

    setState(() {
      _processedImage?.dispose();
      _processedImage = result.image;
      _processedBytes = result.pngBytes;
      _isProcessing = false;
    });
  }

  // ── Reset ──────────────────────────────────
  void _reset() {
    setState(() {
      _processedBytes = null;
      _processedImage?.dispose();
      _processedImage = null;
      _selectedFeature = null;
      // Reset sliders
      for (final f in ImageFeature.values) {
        _sliderValues[f] = _featureMeta[f]!.sliderDefault;
      }
    });
  }

  // ── Download ───────────────────────────────
  void _downloadImage() {
    if (_processedBytes == null) return;
    final name = _fileName ?? 'image';
    final ext = name.contains('.') ? name.split('.').first : name;
    final featureName = _selectedFeature != null
        ? _featureMeta[_selectedFeature]!.label.toLowerCase()
        : 'processed';
    WebUtils.downloadFile(
      _processedBytes!.toList(),
      '${ext}_$featureName.png',
      'image/png',
    );
  }

  // ════════════════════════════════════════════
  //  IMAGE PROCESSING (pure pixel manipulation)
  // ════════════════════════════════════════════

  Future<_ProcessedResult> _processImage(
      ui.Image src, ImageFeature feature, double sliderVal) async {
    // Get pixel data
    final byteData = await src.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw Exception('Failed to get pixel data');
    }

    final w = src.width;
    final h = src.height;
    final pixels = Uint8List.fromList(byteData.buffer.asUint8List());

    Uint8List result;
    switch (feature) {
      case ImageFeature.grayscale:
        result = _applyGrayscale(pixels);
        break;
      case ImageFeature.sepia:
        result = _applySepia(pixels);
        break;
      case ImageFeature.invert:
        result = _applyInvert(pixels);
        break;
      case ImageFeature.brightness:
        result = _applyBrightness(pixels, sliderVal);
        break;
      case ImageFeature.contrast:
        result = _applyContrast(pixels, sliderVal);
        break;
      case ImageFeature.blur:
        result = _applyBoxBlur(pixels, w, h, sliderVal.round());
        break;
      case ImageFeature.pixelate:
        result = _applyPixelate(pixels, w, h, sliderVal.round());
        break;
    }

    // Encode back to image
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        result, w, h, ui.PixelFormat.rgba8888, completer.complete);
    final newImage = await completer.future;

    // Convert to PNG
    final pngData = await newImage.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = Uint8List.fromList(pngData!.buffer.asUint8List());

    return _ProcessedResult(newImage, pngBytes);
  }

  Uint8List _applyGrayscale(Uint8List pixels) {
    final out = Uint8List.fromList(pixels);
    for (int i = 0; i < out.length; i += 4) {
      final gray =
          (0.299 * out[i] + 0.587 * out[i + 1] + 0.114 * out[i + 2]).round();
      out[i] = gray;
      out[i + 1] = gray;
      out[i + 2] = gray;
    }
    return out;
  }

  Uint8List _applySepia(Uint8List pixels) {
    final out = Uint8List.fromList(pixels);
    for (int i = 0; i < out.length; i += 4) {
      final r = out[i], g = out[i + 1], b = out[i + 2];
      out[i] = min(255, (r * 0.393 + g * 0.769 + b * 0.189).round());
      out[i + 1] = min(255, (r * 0.349 + g * 0.686 + b * 0.168).round());
      out[i + 2] = min(255, (r * 0.272 + g * 0.534 + b * 0.131).round());
    }
    return out;
  }

  Uint8List _applyInvert(Uint8List pixels) {
    final out = Uint8List.fromList(pixels);
    for (int i = 0; i < out.length; i += 4) {
      out[i] = 255 - out[i];
      out[i + 1] = 255 - out[i + 1];
      out[i + 2] = 255 - out[i + 2];
    }
    return out;
  }

  Uint8List _applyBrightness(Uint8List pixels, double amount) {
    final out = Uint8List.fromList(pixels);
    for (int i = 0; i < out.length; i += 4) {
      out[i] = (out[i] + amount).clamp(0, 255).toInt();
      out[i + 1] = (out[i + 1] + amount).clamp(0, 255).toInt();
      out[i + 2] = (out[i + 2] + amount).clamp(0, 255).toInt();
    }
    return out;
  }

  Uint8List _applyContrast(Uint8List pixels, double amount) {
    final factor = (259 * (amount + 255)) / (255 * (259 - amount));
    final out = Uint8List.fromList(pixels);
    for (int i = 0; i < out.length; i += 4) {
      out[i] = (factor * (out[i] - 128) + 128).clamp(0, 255).toInt();
      out[i + 1] = (factor * (out[i + 1] - 128) + 128).clamp(0, 255).toInt();
      out[i + 2] = (factor * (out[i + 2] - 128) + 128).clamp(0, 255).toInt();
    }
    return out;
  }

  Uint8List _applyBoxBlur(Uint8List pixels, int w, int h, int radius) {
    if (radius < 1) radius = 1;
    final out = Uint8List(pixels.length);
    // Copy alpha channel
    for (int i = 3; i < pixels.length; i += 4) {
      out[i] = pixels[i];
    }
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int rr = 0, gg = 0, bb = 0, count = 0;
        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            final nx = (x + dx).clamp(0, w - 1);
            final ny = (y + dy).clamp(0, h - 1);
            final idx = (ny * w + nx) * 4;
            rr += pixels[idx];
            gg += pixels[idx + 1];
            bb += pixels[idx + 2];
            count++;
          }
        }
        final idx = (y * w + x) * 4;
        out[idx] = rr ~/ count;
        out[idx + 1] = gg ~/ count;
        out[idx + 2] = bb ~/ count;
      }
    }
    return out;
  }

  Uint8List _applyPixelate(Uint8List pixels, int w, int h, int blockSize) {
    if (blockSize < 2) blockSize = 2;
    final out = Uint8List.fromList(pixels);
    for (int y = 0; y < h; y += blockSize) {
      for (int x = 0; x < w; x += blockSize) {
        int rr = 0, gg = 0, bb = 0, aa = 0, count = 0;
        // Average the block
        for (int dy = 0; dy < blockSize && y + dy < h; dy++) {
          for (int dx = 0; dx < blockSize && x + dx < w; dx++) {
            final idx = ((y + dy) * w + (x + dx)) * 4;
            rr += pixels[idx];
            gg += pixels[idx + 1];
            bb += pixels[idx + 2];
            aa += pixels[idx + 3];
            count++;
          }
        }
        rr ~/= count;
        gg ~/= count;
        bb ~/= count;
        aa ~/= count;
        // Fill the block
        for (int dy = 0; dy < blockSize && y + dy < h; dy++) {
          for (int dx = 0; dx < blockSize && x + dx < w; dx++) {
            final idx = ((y + dy) * w + (x + dx)) * 4;
            out[idx] = rr;
            out[idx + 1] = gg;
            out[idx + 2] = bb;
            out[idx + 3] = aa;
          }
        }
      }
    }
    return out;
  }

  // ════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: _originalImage == null ? _buildUploadView() : _buildEditorView(),
    );
  }

  // ── Upload View ────────────────────────────
  Widget _buildUploadView() {
    return Center(
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            constraints: BoxConstraints(maxWidth: 500.w, maxHeight: 400.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _sectionHeader('IMAGE_LAB // UPLOAD_MODULE'),
                SizedBox(height: 30.h),
                // Upload drop-zone
                GestureDetector(
                  onTap: _pickImage,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      width: 400.w,
                      height: 220.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        border: Border.all(
                          color: Color.lerp(
                            Colors.cyanAccent.withOpacity(0.3),
                            Colors.cyanAccent,
                            _glowController.value,
                          )!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent
                                .withOpacity(0.1 * _glowController.value),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 60.r,
                            color: Colors.cyanAccent.withOpacity(0.7),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'CLICK TO UPLOAD IMAGE',
                            style: GoogleFonts.orbitron(
                              color: Colors.cyanAccent,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Supports JPEG, PNG, WEBP, GIF',
                            style: GoogleFonts.vt323(
                              color: Colors.grey,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                // Feature list preview
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: ImageFeature.values.map((f) {
                    final meta = _featureMeta[f]!;
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: meta.color.withOpacity(0.1),
                        border: Border.all(
                            color: meta.color.withOpacity(0.3), width: 1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(meta.icon, color: meta.color, size: 12.r),
                          SizedBox(width: 4.w),
                          Text(
                            meta.label,
                            style: GoogleFonts.vt323(
                              color: meta.color,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Editor View ────────────────────────────
  Widget _buildEditorView() {
    return Column(
      children: [
        // Toolbar
        _buildToolbar(),
        // Content
        Expanded(
          child: Row(
            children: [
              // Left: Feature selector panel
              SizedBox(
                width: 180.w,
                child: _buildFeaturePanel(),
              ),
              // Divider
              Container(
                width: 1,
                color: Colors.cyanAccent.withOpacity(0.2),
              ),
              // Right: Preview area
              Expanded(child: _buildPreviewArea()),
            ],
          ),
        ),
      ],
    );
  }

  // ── Toolbar ────────────────────────────────
  Widget _buildToolbar() {
    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.cyanAccent.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // File info
          Icon(Icons.image, color: Colors.cyanAccent, size: 16.r),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'FILE: ${_fileName ?? "unknown"}'.toUpperCase(),
              style: GoogleFonts.vt323(
                color: Colors.cyanAccent.withOpacity(0.8),
                fontSize: 13.sp,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Dimensions
          if (_originalImage != null)
            Text(
              '${_originalImage!.width}x${_originalImage!.height}',
              style: GoogleFonts.vt323(
                color: Colors.grey,
                fontSize: 12.sp,
              ),
            ),
          SizedBox(width: 16.w),
          // Action buttons
          _toolbarButton(
            icon: Icons.refresh,
            label: 'RESET',
            color: Colors.orangeAccent,
            onTap: _reset,
          ),
          SizedBox(width: 8.w),
          _toolbarButton(
            icon: Icons.download,
            label: 'DOWNLOAD',
            color: Colors.greenAccent,
            onTap: _processedBytes != null ? _downloadImage : null,
          ),
          SizedBox(width: 8.w),
          _toolbarButton(
            icon: Icons.folder_open,
            label: 'NEW',
            color: Colors.cyanAccent,
            onTap: _pickImage,
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor:
            disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: disabled
                ? Colors.white.withOpacity(0.03)
                : color.withOpacity(0.1),
            border: Border.all(
              color: disabled
                  ? Colors.grey.withOpacity(0.2)
                  : color.withOpacity(0.4),
            ),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14.r, color: disabled ? Colors.grey : color),
              SizedBox(width: 4.w),
              Text(
                label,
                style: GoogleFonts.vt323(
                  color: disabled ? Colors.grey : color,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Feature Panel ──────────────────────────
  Widget _buildFeaturePanel() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Panel header
          Container(
            height: 32.h,
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.cyanAccent.withOpacity(0.2)),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              '◆ FEATURES',
              style: GoogleFonts.orbitron(
                color: Colors.cyanAccent,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          // Feature list
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              children: ImageFeature.values.map((f) {
                final meta = _featureMeta[f]!;
                final isSelected = _selectedFeature == f;
                return _buildFeatureItem(f, meta, isSelected);
              }).toList(),
            ),
          ),
          // Slider (if selected feature has one)
          if (_selectedFeature != null &&
              _featureMeta[_selectedFeature]!.hasSlider)
            _buildSliderControl(),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
      ImageFeature feature, _FeatureMeta meta, bool isSelected) {
    return GestureDetector(
      onTap: () => _applyFeature(feature),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected
                ? meta.color.withOpacity(0.15)
                : Colors.white.withOpacity(0.02),
            border: Border.all(
              color: isSelected
                  ? meta.color.withOpacity(0.6)
                  : Colors.white.withOpacity(0.05),
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Row(
            children: [
              // Indicator
              Container(
                width: 3,
                height: 20.h,
                decoration: BoxDecoration(
                  color: isSelected ? meta.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(meta.icon,
                  color: isSelected ? meta.color : Colors.grey, size: 18.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  meta.label,
                  style: GoogleFonts.vt323(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: 14.sp,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: meta.color, size: 14.r),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderControl() {
    final feature = _selectedFeature!;
    final meta = _featureMeta[feature]!;
    final value = _sliderValues[feature]!;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: meta.color.withOpacity(0.05),
        border: Border(
          top: BorderSide(color: meta.color.withOpacity(0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                meta.sliderLabel,
                style: GoogleFonts.orbitron(
                  color: meta.color,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value.round().toString(),
                style: GoogleFonts.vt323(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: meta.color,
              inactiveTrackColor: meta.color.withOpacity(0.2),
              thumbColor: meta.color,
              overlayColor: meta.color.withOpacity(0.2),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: meta.sliderMin,
              max: meta.sliderMax,
              onChanged: (v) {
                setState(() => _sliderValues[feature] = v);
              },
              onChangeEnd: (_) => _applyFeature(feature),
            ),
          ),
        ],
      ),
    );
  }

  // ── Preview Area ───────────────────────────
  Widget _buildPreviewArea() {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          // Tab bar
          Container(
            height: 28.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              border: Border(
                bottom: BorderSide(color: Colors.cyanAccent.withOpacity(0.15)),
              ),
            ),
            child: Row(
              children: [
                _previewTab(
                  'ORIGINAL',
                  _processedImage == null,
                  Colors.cyanAccent,
                ),
                if (_processedImage != null)
                  _previewTab(
                    'PROCESSED // ${_featureMeta[_selectedFeature]?.label ?? ""}',
                    true,
                    _featureMeta[_selectedFeature]?.color ?? Colors.cyanAccent,
                  ),
              ],
            ),
          ),
          // Image display
          Expanded(
            child: _isProcessing
                ? _buildProcessingIndicator()
                : _buildImagePreview(),
          ),
        ],
      ),
    );
  }

  Widget _previewTab(String label, bool active, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? color : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.vt323(
          color: active ? Colors.white : Colors.grey,
          fontSize: 11.sp,
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40.r,
            height: 40.r,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.cyanAccent,
              backgroundColor: Colors.cyanAccent.withOpacity(0.1),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'PROCESSING...',
            style: GoogleFonts.orbitron(
              color: Colors.cyanAccent,
              fontSize: 12.sp,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_processedImage != null) {
          // Side-by-side comparison
          return Row(
            children: [
              // Original (left half)
              Expanded(
                child: _imagePanel(
                  'ORIGINAL',
                  _originalImage!,
                  _originalBytes!,
                  Colors.cyanAccent,
                ),
              ),
              // Divider
              Container(
                width: 2,
                color: _featureMeta[_selectedFeature]?.color.withOpacity(0.5) ??
                    Colors.cyanAccent.withOpacity(0.5),
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _featureMeta[_selectedFeature]?.color ??
                            Colors.cyanAccent,
                      ),
                    ),
                    child: Icon(Icons.compare_arrows,
                        size: 12, color: Colors.white),
                  ),
                ),
              ),
              // Processed (right half)
              Expanded(
                child: _imagePanel(
                  _featureMeta[_selectedFeature]?.label ?? 'PROCESSED',
                  _processedImage!,
                  _processedBytes!,
                  _featureMeta[_selectedFeature]?.color ?? Colors.cyanAccent,
                ),
              ),
            ],
          );
        } else {
          // Just original
          return _imagePanel(
            'ORIGINAL',
            _originalImage!,
            _originalBytes!,
            Colors.cyanAccent,
          );
        }
      },
    );
  }

  Widget _imagePanel(
      String label, ui.Image img, Uint8List bytes, Color accentColor) {
    return Column(
      children: [
        // Label
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          color: accentColor.withOpacity(0.05),
          child: Text(
            '[ $label ]',
            style: GoogleFonts.vt323(
              color: accentColor,
              fontSize: 11.sp,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Image
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: accentColor.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.05),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Common Widgets ─────────────────────────
  Widget _sectionHeader(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 4, height: 16, color: Colors.cyanAccent),
        SizedBox(width: 10.w),
        Text(
          text,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ProcessedResult {
  final ui.Image image;
  final Uint8List pngBytes;
  _ProcessedResult(this.image, this.pngBytes);
}
