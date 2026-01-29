import 'dart:js_util' as js;
import '../resume_context.dart';

class LlmService {
  static bool _ready = false;
  static bool _initializing = false;

  static Future<void> init(Function(int)? onProgress) async {
    if (_ready || _initializing) return;
    _initializing = true;

    while (!js.hasProperty(js.globalThis, 'initLLM')) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (onProgress != null) {
      js.callMethod(js.globalThis, 'setLLMLoadingCallback', [
        js.allowInterop((int p) => onProgress(p))
      ]);
    }

    await js.promiseToFuture(
      js.callMethod(js.globalThis, 'initLLM', [resumeContext]),
    );

    _ready = true;
    _initializing = false;
  }

  static Future<String> ask(String prompt) async {
    await init(null); // auto-init safety, but progress won't show unless provided

    final res = await js.promiseToFuture(
      js.callMethod(js.globalThis, 'askLLM', [prompt]),
    );

    return res.toString();
  }
}