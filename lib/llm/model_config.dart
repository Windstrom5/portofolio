/// Configuration for available WebLLM models.
/// Users can choose which model to download, or use the default.
library;

class LlmModel {
  final String id;
  final String name;
  final String size;
  final String description;
  final bool isDefault;

  const LlmModel({
    required this.id,
    required this.name,
    required this.size,
    required this.description,
    this.isDefault = false,
  });
}

class ModelConfig {
  static String? selectedModelId;

  static const String defaultModelId = 'none';

  static String get activeModelId => selectedModelId ?? defaultModelId;

  static const List<LlmModel> availableModels = [
    LlmModel(
      id: 'none',
      name: 'None (Offline)',
      size: '0MB',
      description: 'Skip AI download. Voice features disabled.',
      isDefault: true,
    ),
    LlmModel(
      id: 'SmolLM2-360M-Instruct-q4f16_1-MLC',
      name: 'SmolLM2 360M',
      size: '~200MB',
      description: 'Ultra-light. Fastest download, basic conversations.',
    ),
    LlmModel(
      id: 'Llama-3.2-1B-Instruct-q4f16_1-MLC',
      name: 'Llama 3.2 1B',
      size: '~500MB',
      description: 'Recommended. Fast, good quality.',
    ),
    LlmModel(
      id: 'Qwen2.5-1.5B-Instruct-q4f16_1-MLC',
      name: 'Qwen 2.5 1.5B',
      size: '~900MB',
      description: 'Strong multilingual support. Good for JP/EN.',
    ),
    LlmModel(
      id: 'Gemma-2-2b-it-q4f16_1-MLC',
      name: 'Gemma 2 2B',
      size: '~1.2GB',
      description: 'Google model. High quality, moderate size.',
    ),
    LlmModel(
      id: 'Llama-3.2-3B-Instruct-q4f16_1-MLC',
      name: 'Llama 3.2 3B',
      size: '~1.5GB',
      description: 'Larger Llama. Better reasoning, slower download.',
    ),
    LlmModel(
      id: 'Phi-3.5-mini-instruct-q4f16_1-MLC',
      name: 'Phi 3.5 Mini',
      size: '~2GB',
      description: 'Microsoft model. Best quality, largest download.',
    ),
  ];
}
