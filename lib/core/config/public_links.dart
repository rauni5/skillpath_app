/// Builds the shareable public-profile URL for a given token.
///
/// The base URL is **not** derived from [resolveBaseUrl] in
/// `api_client.dart` — that resolves the *backend API* origin (defaults to
/// localhost for dev), which may or may not be the same origin that
/// actually serves the public web page once deployed. Rather than guess,
/// this is a separate, explicitly-configurable value:
///
/// ```
/// flutter build web --dart-define=PUBLIC_PROFILE_BASE_URL=https://your-real-domain.com
/// ```
///
/// Until that's set to a real, reachable domain, the link this builds
/// will point at an obviously-placeholder address rather than something
/// that looks real but silently doesn't work.
String publicProfileBaseUrl() {
  const override = String.fromEnvironment('PUBLIC_PROFILE_BASE_URL');
  if (override.isNotEmpty) return override;
  return 'https://your-skillpath-domain.example.com';
}

String buildPublicProfileLink(String token) {
  final base = publicProfileBaseUrl().replaceFirst(RegExp(r'/+$'), '');
  return '$base/p/$token';
}
