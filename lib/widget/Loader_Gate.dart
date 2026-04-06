import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import 'package:flutter/services.dart';
import '../llm/model_config.dart';
import '../llm/llm_service.dart';

class LoaderGate extends StatefulWidget {
  const LoaderGate({super.key});

  @override
  State<LoaderGate> createState() => _LoaderGateState();
}

class _LoaderGateState extends State<LoaderGate> {
  bool showLogin = false;
  bool cursorVisible = true;
  bool isLoggingIn = false;
  bool _isDownloading = false;
  int _downloadProgress = 0;
  String _downloadStatus = '';
  Timer? _cursorTimer;
  Timer? _bootTimer;
  final int currentYear = DateTime.now().year;
  String _selectedModelId = ModelConfig.defaultModelId;
  final Set<String> _cachedModels = {'none'}; // 'none' is always available

  // MUFC Official Colors
  static const Color muRed = Color(0xFFDA291C);
  static const Color muGold = Color(0xFFFBE122);
  static const Color muBlack = Color(0xFF000000);

  // Fake boot messages - Hybrid Windstrom5/Sporty Edition
  final List<String> bootMessages = [
    "[    0.000000] WINDSTROM5 OS v3.5-LATEST-STABLE",
    "[    0.042188] [CORE] Initializing Terminal of Dreams kernel...",
    "[    1.248912] [NET ] Portfolio Network: [ONLINE]",
    "[    2.187654] [SYS ] Tactical Engine: [OPTIMIZED]",
    "[    3.891234] [SEC ] WINDSTROM5 Protocol: [ACTIVE]",
    "[    4.912345] [INF ] Root access granted. Welcome to the Terminal.",
  ];

  int currentMessageIndex = 0;
  bool bootFinished = false;

  @override
  void initState() {
    super.initState();

    // Blinking cursor
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => cursorVisible = !cursorVisible);
    });

    // Fake boot sequence - significantly faster to prevent late rendering
    _bootTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (currentMessageIndex < bootMessages.length) {
          currentMessageIndex++;
        } else {
          bootFinished = true;
          timer.cancel();

          // Show login directly after boot with minimal delay
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              setState(() => showLogin = true);
              _checkCachedModels();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _bootTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkCachedModels() async {
    bool hasAutoSelected = false;
    for (final model in ModelConfig.availableModels) {
      if (model.id == 'none') continue;
      final cached = await LlmService.checkModelCached(model.id);
      if (cached && mounted) {
        setState(() {
          _cachedModels.add(model.id);
          // Auto-select the first cached model if we haven't already
          if (!hasAutoSelected) {
            _selectedModelId = model.id;
            hasAutoSelected = true;
          }
        });
      }
    }
  }

  void _onLogin() {
    if (isLoggingIn || _isDownloading || !showLogin) return;

    // Set the selected model before navigating
    ModelConfig.selectedModelId = _selectedModelId;
    LlmService.setModelId(_selectedModelId);

    setState(() => isLoggingIn = true);

    if (_selectedModelId == 'none') {
      // No model to download, go straight to home
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _navigateToHome();
      });
    } else {
      // Start downloading the model with progress
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0;
        _downloadStatus = 'Connecting to model server...';
      });

      LlmService.init((progress) {
        if (!mounted) return;
        setState(() {
          _downloadProgress = progress;
          if (progress < 20) {
            _downloadStatus = 'Downloading model weights...';
          } else if (progress < 50) {
            _downloadStatus = 'Loading neural layers...';
          } else if (progress < 80) {
            _downloadStatus = 'Compiling WebGPU shaders...';
          } else if (progress < 100) {
            _downloadStatus = 'Initializing inference engine...';
          } else {
            _downloadStatus = 'Model ready! Launching...';
          }
        });

        if (progress >= 100) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) _navigateToHome();
          });
        }
      });
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (showLogin && event is RawKeyDownEvent) {
          _onLogin();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          backgroundColor: muBlack,
          body: Stack(
            children: [
              // Background gradient - MUFC themed but with dark hacker aesthetic
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      muBlack,
                      Color(0xFF0F0000), // Very dark red
                      Color(0xFF1A1A1A), // Dark grey
                    ],
                  ),
                ),
              ),

              // Subtle Tech Grid Overlay (CSS/Gradient based instead of Image)
              Opacity(
                opacity: 0.05,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.cyanAccent],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
              ),

              // Boot sequence - Hacker Green/Retro Cyan
              if (!showLogin)
                SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(30.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List.generate(
                          currentMessageIndex,
                          (i) {
                            Color textColor = Colors.white70;
                            if (bootMessages[i].contains('[OK]') ||
                                bootMessages[i].contains('[ONLINE]') ||
                                bootMessages[i].contains('ACTIVE')) {
                              textColor =
                                  const Color(0xFF50FA7B); // Hacker Green
                            } else if (bootMessages[i].contains('[CORE]') ||
                                bootMessages[i].contains('[SYS]') ||
                                bootMessages[i].contains('[NET]')) {
                              textColor = const Color(0xFF8BE9FD); // Retro Cyan
                            }

                            return Text(
                              bootMessages[i],
                              style: GoogleFonts.vt323(
                                fontSize: 18.sp,
                                height: 1.4,
                                color: textColor,
                              ),
                            );
                          },
                        ),
                        if (bootFinished)
                          Padding(
                            padding: EdgeInsets.only(top: 16.h),
                            child: Text(
                              'WINDSTROM5_OS: LOADING_AI_CONFIG...',
                              style: GoogleFonts.vt323(
                                fontSize: 20.sp,
                                color: muGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // Full Login Screen
              if (showLogin)
                Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Red Devils Logo
                        _brandLogo(),

                        SizedBox(height: 50.h),

                        // Login Box
                        Container(
                          width: 380.w.clamp(320.0, 420.0),
                          padding: EdgeInsets.all(40.r),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(24.r),
                            border: Border.all(
                                color: muRed.withOpacity(0.5), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: muRed.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              // User icon with MUFC Red glow
                              Container(
                                width: 100.r,
                                height: 100.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: muBlack,
                                  border: Border.all(color: muRed, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                        color: muRed.withOpacity(0.5),
                                        blurRadius: 15)
                                  ],
                                ),
                                child: Icon(
                                  Icons.bolt_rounded,
                                  size: 60.sp,
                                  color: muGold,
                                ),
                              ),

                              SizedBox(height: 25.h),

                              // Username
                              Text(
                                'VISITOR',
                                style: GoogleFonts.orbitron(
                                  fontSize: 22.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),

                              SizedBox(height: 25.h),

                              // Model Selection Dropdown
                              _buildModelDropdown(),

                              SizedBox(height: 35.h),

                              // Login Button
                              if (!_isDownloading)
                                GestureDetector(
                                  onTap: _onLogin,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 40.w, vertical: 12.h),
                                    decoration: BoxDecoration(
                                      color: muRed.withOpacity(0.2),
                                      border: Border.all(color: muRed),
                                      borderRadius: BorderRadius.circular(8.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: muRed.withOpacity(0.3),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: isLoggingIn && !_isDownloading
                                        ? SizedBox(
                                            width: 20.r,
                                            height: 20.r,
                                            child:
                                                const CircularProgressIndicator(
                                              color: muGold,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'INITIALIZE',
                                            style: GoogleFonts.orbitron(
                                              color: Colors.white,
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                  ),
                                ),

                              // Download Progress Section
                              if (_isDownloading) _buildDownloadProgress(),
                            ],
                          ),
                        ),

                        SizedBox(height: 40.h),

                        // Footer
                        Text(
                          'WINDSTROM5 OS • PORTFOLIO ENGINE',
                          style: GoogleFonts.vt323(
                            fontSize: 16.sp,
                            color: Colors.grey.shade500,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Windstrom5 Hybrid Edition v1.0',
                          style: GoogleFonts.notoSansJp(
                            fontSize: 10.sp,
                            color: muRed.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadProgress() {
    final model =
        ModelConfig.availableModels.firstWhere((m) => m.id == _selectedModelId);
    return Column(
      children: [
        // Model name being downloaded
        Text(
          '⬇ ${model.name}',
          style: GoogleFonts.orbitron(
            color: muGold,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),

        // Progress bar
        Container(
          width: double.infinity,
          height: 20.h,
          decoration: BoxDecoration(
            color: const Color(0xFF12121F),
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: muRed.withOpacity(0.3)),
          ),
          child: Stack(
            children: [
              // Fill
              FractionallySizedBox(
                widthFactor: (_downloadProgress / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3.r),
                    gradient: const LinearGradient(
                      colors: [muRed, muGold],
                    ),
                  ),
                ),
              ),
              // Percentage text
              Center(
                child: Text(
                  '$_downloadProgress%',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),

        // Status text
        Text(
          _downloadStatus,
          style: GoogleFonts.vt323(
            color: const Color(0xFF50FA7B),
            fontSize: 13.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildModelDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI ENGINE MODULE:',
          style: GoogleFonts.vt323(
            fontSize: 14.sp,
            color: Colors.grey.shade400,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Color(0xFF12121F),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: muRed.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedModelId,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A2E),
              icon: const Icon(Icons.arrow_drop_down, color: muRed),
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 13.sp,
              ),
              onChanged: _isDownloading
                  ? null
                  : (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedModelId = newValue;
                        });
                      }
                    },
              items: ModelConfig.availableModels
                  .map<DropdownMenuItem<String>>((LlmModel model) {
                return DropdownMenuItem<String>(
                  value: model.id,
                  child: Row(
                    children: [
                      Text(
                        _getModelEmoji(model),
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          model.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (model.size != '0MB')
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_cachedModels.contains(model.id))
                              Container(
                                margin: EdgeInsets.only(right: 6.w),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 5.w, vertical: 1.h),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF50FA7B).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4.r),
                                  border: Border.all(
                                    color: const Color(0xFF50FA7B)
                                        .withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  '✓',
                                  style: TextStyle(
                                    color: const Color(0xFF50FA7B),
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Text(
                              model.size,
                              style: TextStyle(
                                color: Colors.cyanAccent.withOpacity(0.7),
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          ModelConfig.availableModels
              .firstWhere((m) => m.id == _selectedModelId)
              .description,
          style: GoogleFonts.vt323(
            color: muGold.withOpacity(0.8),
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  String _getModelEmoji(LlmModel model) {
    if (model.id == 'none') return '🛑';
    if (model.id.contains('SmolLM')) return '⚡';
    if (model.id.contains('Llama')) return '🦙';
    if (model.id.contains('Qwen')) return '🌏';
    if (model.id.contains('Gemma')) return '💎';
    if (model.id.contains('Phi')) return '🔬';
    return '🤖';
  }

  Widget _brandLogo() {
    return Column(
      children: [
        Text(
          'WINDSTROM5 OS',
          style: GoogleFonts.orbitron(
            fontSize: 42.sp,
            fontWeight: FontWeight.w900,
            color: muRed,
            letterSpacing: 8,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: const Offset(4, 4),
                blurRadius: 2,
              ),
              Shadow(
                color: muRed.withOpacity(0.8),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [muRed, muGold]),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            'THE TERMINAL OF DREAMS',
            style: GoogleFonts.vt323(
              fontSize: 18.sp,
              color: muBlack,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
      ],
    );
  }
}
