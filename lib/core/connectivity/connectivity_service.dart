import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around `connectivity_plus`, exposing a simple online/offline
/// signal.
///
/// Important caveat: this reports whether the device is attached to a
/// network interface (wifi/cellular/etc), not whether that network can
/// actually reach the internet or our backend — a device on wifi with no
/// internet still reports "connected" here. That's why this is used to
/// decide *when it's worth retrying* and to proactively disable actions
/// that obviously can't work (e.g. the tutor chat send button), not as the
/// source of truth for "is the backend reachable" — actual request
/// success/failure (and [AuthProvider.isOffline]) still owns that.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  /// Emits true/false whenever the device's network attachment changes.
  Stream<bool> get onStatusChanged =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}
