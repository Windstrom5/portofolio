import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../llm/model_config.dart';

/// A premium dialog for selecting which LLM model to download.
/// Returns the selected model ID, or null if cancelled.
class ModelSelectionDialog extends StatefulWidget {
  const ModelSelectionDialog({super.key});

  /// Shows the dialog and returns the selected model ID.
  /// Returns null if the user cancels.
  static Future<String?> show(BuildContext context) {
    return showDialog<String?>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (_) => const ModelSelectionDialog(),
    );
  }

  @override
  State<ModelSelectionDialog> createState() => _ModelSelectionDialogState();
}

class _ModelSelectionDialogState extends State<ModelSelectionDialog>
    with SingleTickerProviderStateMixin {
  String? _hoveredId;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: 520,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFF6B9D).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B9D).withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(),
              // Model list
              Flexible(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shrinkWrap: true,
                  itemCount: ModelConfig.availableModels.length,
                  itemBuilder: (context, index) {
                    final model = ModelConfig.availableModels[index];
                    return _buildModelCard(model);
                  },
                ),
              ),
              // Quick start button
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFF9B59B6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B9D).withOpacity(0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Center(
              child: Text('🧠', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select AI Model',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose a model to power Sakura\'s brain',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
              child: Icon(Icons.close, color: Colors.grey[500], size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(LlmModel model) {
    final isHovered = _hoveredId == model.id;
    final isDefault = model.isDefault;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredId = model.id),
      onExit: (_) => setState(() => _hoveredId = null),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(model.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                isHovered ? const Color(0xFF1A1A2E) : const Color(0xFF12121F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered
                  ? const Color(0xFFFF6B9D).withOpacity(0.5)
                  : isDefault
                      ? const Color(0xFFFF6B9D).withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
              width: isHovered ? 1.5 : 1,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF6B9D).withOpacity(0.1),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Model icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: isDefault
                        ? [
                            const Color(0xFFFF6B9D).withOpacity(0.2),
                            const Color(0xFF9B59B6).withOpacity(0.2),
                          ]
                        : [
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.02),
                          ],
                  ),
                ),
                child: Center(
                  child: Text(
                    _getModelEmoji(model),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Model info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          model.name,
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B9D).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFFF6B9D).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: GoogleFonts.jetBrainsMono(
                                color: const Color(0xFFFF6B9D),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      model.description,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Size badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  model.size,
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.cyanAccent.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '💡 Models are cached after first download',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(ModelConfig.defaultModelId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFF8E9E)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '⚡ Quick Start',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getModelEmoji(LlmModel model) {
    if (model.id.contains('SmolLM')) return '⚡';
    if (model.id.contains('Llama')) return '🦙';
    if (model.id.contains('Qwen')) return '🌏';
    if (model.id.contains('Gemma')) return '💎';
    if (model.id.contains('Phi')) return '🔬';
    return '🤖';
  }
}
