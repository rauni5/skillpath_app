import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// The real implementation — only ever compiled into the web build, since
/// url_strategy.dart's conditional export only picks this file when
/// dart:ui_web is available.
void configureUrlStrategy() {
  usePathUrlStrategy();
}
