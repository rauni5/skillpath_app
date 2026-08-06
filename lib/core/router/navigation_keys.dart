import 'package:flutter/widgets.dart';

/// Shared with [GoRouter]'s `navigatorKey`. Lets code that isn't inside the
/// widget tree — most importantly, the push-notification tap handler, which
/// can fire while the app is fully backgrounded — push a route once the app
/// is back in the foreground and the navigator exists again.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
