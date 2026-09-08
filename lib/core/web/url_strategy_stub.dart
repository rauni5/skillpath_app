/// No-op stub — used on every platform except web (Android, iOS, desktop,
/// and `flutter test`, which defaults to the Dart VM). See url_strategy.dart
/// for why this needs to be a separate file rather than a runtime kIsWeb
/// check.
void configureUrlStrategy() {}
