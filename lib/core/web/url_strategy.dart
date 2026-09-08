// ignore: dangling_library_doc_comments
/// Picks the right implementation of configureUrlStrategy() at *compile*
/// time, not runtime — this is the important part. A runtime `if (kIsWeb)`
/// check inside a single shared file still requires the Android/iOS
/// compiler to parse the whole file, including the `import
/// 'package:flutter_web_plugins/flutter_web_plugins.dart'` line, which
/// transitively pulls in `dart:ui_web` — a library that simply doesn't
/// exist outside web. That import alone crashes non-web builds even if
/// the code that uses it never actually runs on those platforms (see
/// https://github.com/flutter/flutter/issues/152490 — a real, currently
/// open Flutter bug, not a mistake in how this was wired up).
///
/// The fix is a compile-time conditional export: the non-web stub never
/// even mentions flutter_web_plugins, so Android/iOS/desktop/test builds
/// never see that import at all.
export 'url_strategy_stub.dart'
    if (dart.library.ui_web) 'url_strategy_web.dart';
