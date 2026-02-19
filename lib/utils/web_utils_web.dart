// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;

class WebUtils {
  static JSObject get jsContext => web.window as JSObject;

  static int get hardwareConcurrency {
    try {
      final nav = web.window.navigator as JSObject;
      final hc = nav.getProperty('hardwareConcurrency'.toJS);
      if (hc.isUndefinedOrNull) return 4;
      return int.tryParse(hc.toString()) ?? 4;
    } catch (_) {
      return 4;
    }
  }

  static String get deviceMemory {
    final nav = web.window.navigator as JSObject;
    try {
      if (nav.hasProperty('deviceMemory'.toJS).toDart) {
        return nav.getProperty('deviceMemory'.toJS).toString();
      }
    } catch (_) {}
    return '8';
  }

  static int get screenWidth => web.window.screen.width;
  static int get screenHeight => web.window.screen.height;
  static double get devicePixelRatio => web.window.devicePixelRatio.toDouble();
  static String get userAgent => web.window.navigator.userAgent;
  static String get platform => web.window.navigator.platform;
  static String get vendor => web.window.navigator.vendor;
  static String get language => web.window.navigator.language;
  static int get maxTouchPoints => web.window.navigator.maxTouchPoints;

  static void downloadFile(List<int> bytes, String filename, String type) {
    final blob = web.Blob(
        [Uint8List.fromList(bytes).toJS].toJS, web.BlobPropertyBag(type: type));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.style.display = 'none';
    anchor.download = filename;
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }

  static void postMessageToIframe(String selector, dynamic message) {
    final element = web.document.querySelector(selector);
    if (element is web.HTMLIFrameElement) {
      final jsMessage = (message as Object).jsify();
      if (jsMessage != null) {
        element.contentWindow?.postMessage(jsMessage, '*'.toJS);
      }
    }
  }

  static bool hasProperty(dynamic obj, String property) =>
      (obj as JSObject).hasProperty(property.toJS).toDart;

  static dynamic getProperty(dynamic obj, String property) =>
      (obj as JSObject).getProperty(property.toJS);

  static dynamic getPropertyByPath(String path) {
    try {
      dynamic obj = jsContext;
      for (var part in path.split('.')) {
        if (obj != null && obj is JSObject) {
          obj = obj.getProperty(part.toJS);
        } else {
          return null;
        }
      }
      return obj;
    } catch (_) {
      return null;
    }
  }

  static dynamic callMethod(dynamic obj, String method, List args) {
    final jsObj = obj as JSObject;
    final jsMethod = jsObj.getProperty(method.toJS) as JSFunction;
    final reflect =
        (web.window as JSObject).getProperty('Reflect'.toJS) as JSObject;
    final jsArgs = args.map((e) => (e as Object?)?.jsify()).toList().toJS;
    return reflect.callMethod('apply'.toJS, jsMethod, jsObj, jsArgs);
  }

  static dynamic jsify(dynamic obj) => (obj as Object).jsify();

  static JSExportedDartFunction allowInterop(Function f) {
    if (f is void Function(int)) return f.toJS;
    if (f is void Function()) return f.toJS;
    if (f is void Function(String)) return f.toJS;
    if (f is void Function(web.Event)) return f.toJS;
    throw UnsupportedError(
        "Unsupported function type for allowInterop: ${f.runtimeType}");
  }

  static Future<dynamic> promiseToFuture(dynamic promise) =>
      (promise as JSPromise).toDart;

  static void registerViewFactory(
      String viewType, Object Function(int viewId, {Object? params}) factory) {
    ui.platformViewRegistry.registerViewFactory(viewType, factory);
  }

  static dynamic createIFrameElement(
      {String? src,
      String? border,
      String? width,
      String? height,
      String? allow}) {
    final iframe =
        web.document.createElement('iframe') as web.HTMLIFrameElement;
    iframe.src = src ?? '';
    iframe.style.border = border ?? 'none';
    iframe.style.width = width ?? '100%';
    iframe.style.height = height ?? '100%';
    iframe.allow = allow ?? '';
    return iframe;
  }

  static void addWindowEventListener(
      String event, void Function(web.Event) listener) {
    web.window.addEventListener(event, listener.toJS);
  }
}
