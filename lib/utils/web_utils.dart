// lib/utils/web_utils.dart

export 'web_utils_stub.dart'
    if (dart.library.js_interop) 'web_utils_web.dart'
    if (dart.library.js_util) 'web_utils_web.dart'
    if (dart.library.js) 'web_utils_web.dart'
    if (dart.library.html) 'web_utils_web.dart';
