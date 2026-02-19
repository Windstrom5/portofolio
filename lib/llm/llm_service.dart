import '../utils/web_utils.dart';
import '../model/chat_message.dart';
import '../resume_context.dart';

class LlmService {
  static bool _ready = false;
  static bool _initializing = false;

  static Future<void> init(Function(int)? onProgress) async {
    if (_ready || _initializing) return;
    _initializing = true;

    while (!WebUtils.hasProperty(WebUtils.jsContext, 'initLLM')) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (onProgress != null) {
      WebUtils.callMethod(WebUtils.jsContext, 'setLLMLoadingCallback',
          [WebUtils.allowInterop((int p) => onProgress(p))]);
    }

    await WebUtils.promiseToFuture(
      WebUtils.callMethod(WebUtils.jsContext, 'initLLM', [resumeContext]),
    );

    _ready = true;
    _initializing = false;
  }

  static Future<String> ask(String prompt) async {
    await init(
        null); // auto-init safety, but progress won't show unless provided

    final res = await WebUtils.promiseToFuture(
      WebUtils.callMethod(WebUtils.jsContext, 'askLLM', [prompt]),
    );

    return res.toString();
  }

  static Future<String> getLlmResponse(List<dynamic> history) async {
    await init(null);
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
