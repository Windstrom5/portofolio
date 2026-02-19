// lib/utils/web_utils_stub.dart

class WebUtils {
  static dynamic get jsContext => null;

  static int get hardwareConcurrency => 4;
  static String get deviceMemory => '8';
  static int get screenWidth => 1920;
  static int get screenHeight => 1080;
  static double get devicePixelRatio => 1.0;
  static String get userAgent => 'Dart VM';
  static String get platform => 'Generic';
  static String get vendor => 'Google';
  static String get language => 'en-US';
  static int get maxTouchPoints => 0;

  static void downloadFile(List<int> bytes, String filename, String type) {
    // No-op
  }

  static void postMessageToIframe(String selector, dynamic message) {
    // No-op
  }

  static bool hasProperty(dynamic obj, String property) => false;
  static dynamic getProperty(dynamic obj, String property) => null;
  static dynamic getPropertyByPath(String path) => null;
  static dynamic callMethod(dynamic obj, String method, List args) => null;
  static dynamic jsify(dynamic obj) => obj;
  static dynamic allowInterop(Function f) => f;
  static Future<dynamic> promiseToFuture(dynamic promise) => Future.value(null);

  static void registerViewFactory(
      String viewType, Object Function(int viewId, {Object? params}) factory) {
    // No-op
  }

  static dynamic createIFrameElement(
      {String? src,
      String? border,
      String? width,
      String? height,
      String? allow}) {
    return null;
  }

  static void addWindowEventListener(String event, Function(dynamic) listener) {
    // No-op
  }
}
