import '../utils/web_utils.dart';
import '../model/chat_message.dart';
import '../resume_context.dart';

class LlmService {
  static bool _ready = false;
  static bool _initializing = false;
  static String? _selectedModelId;

  static bool get isReady => _ready;

  /// Set the model ID before calling init().
  static void setModelId(String? modelId) {
    _selectedModelId = modelId;
  }

  /// Check if a model is cached in the browser's Cache API.
  static Future<bool> checkModelCached(String modelId) async {
    if (modelId == 'none') return true; // 'none' is always "available"
    try {
      if (!WebUtils.hasProperty(WebUtils.jsContext, 'checkModelCached')) {
        return false;
      }
      final result = await WebUtils.promiseToFuture(
        WebUtils.callMethod(WebUtils.jsContext, 'checkModelCached', [modelId]),
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> init(Function(int)? onProgress, {String? modelId}) async {
    if (_ready || _initializing) return;
    // Use provided modelId, or previously set one
    final effectiveModelId = modelId ?? _selectedModelId;

    if (effectiveModelId == 'none' ||
        effectiveModelId == null && _selectedModelId == null) {
      // Actually, if both are null, it's not initialized fully, but let's assume 'none' if so
      // In ModelConfig default is 'none'.
      if ((effectiveModelId ?? 'none') == 'none') {
        _ready = true;
        return;
      }
    }

    _initializing = true;

    while (!WebUtils.hasProperty(WebUtils.jsContext, 'initLLM')) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (onProgress != null) {
      WebUtils.callMethod(WebUtils.jsContext, 'setLLMLoadingCallback',
          [WebUtils.allowInterop((int p) => onProgress(p))]);
    }

    await WebUtils.promiseToFuture(
      WebUtils.callMethod(
          WebUtils.jsContext, 'initLLM', [resumeContext, effectiveModelId]),
    );

    _ready = true;
    _initializing = false;
  }

  static Future<String> ask(String prompt) async {
    await init(
        null); // auto-init safety, but progress won't show unless provided

    if (_selectedModelId == 'none') {
      return "AI processing is disabled in offline mode.";
    }

    final res = await WebUtils.promiseToFuture(
      WebUtils.callMethod(WebUtils.jsContext, 'askLLM', [prompt]),
    );

    return res.toString();
  }

  static Future<String> getLlmResponse(List<dynamic> history) async {
    await init(null);

    if (_selectedModelId == 'none') {
      return "System offline. AI processing is disabled.";
    }

    // Convert history to list of maps for JS
    final historyList = history
        .map((m) => {
              'role': m.role == MessageRole.user ? 'user' : 'model',
              'parts': [
                {'text': m.text}
              ],
            })
        .toList();

    final res = await WebUtils.promiseToFuture(
      WebUtils.callMethod(
          WebUtils.jsContext, 'askLLMWithHistory', [historyList]),
    );

    return res.toString();
  }
}
