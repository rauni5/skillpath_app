import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/public_links.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../providers/public_profile_provider.dart';
import 'portfolio_screen.dart' show PortfolioBody;

/// Reachable while completely signed out, on both mobile and web — see the
/// unconditional `/p/` carve-out at the top of app_router.dart's redirect
/// function.
///
/// Deliberately renders through the *same* `PortfolioBody` widget the
/// authenticated PortfolioScreen uses when you view a teammate's profile
/// in-app (`isSelf: false`) — same layout, same AppBar-shows-their-name
/// convention, same hidden edit affordances. One real shared screen
/// instead of a hand-built lookalike that can drift out of sync.
class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key, required this.token});

  final String token;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) =>
          context.read<PublicProfileProvider>().loadPublicProfile(widget.token),
    );
  }

  /// A public profile link can be the *first and only* route in the app's
  /// navigation stack — someone tapping it from a text message or email
  /// cold-starts the app straight onto this screen, so there's nothing to
  /// pop back to and Flutter's AppBar won't show a back button at all
  /// (it only shows one when Navigator.canPop is true). Without this,
  /// there'd be no way to actually get into the rest of the app from here.
  void _exitOrGoToApp(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/dashboard');
    }
  }

  Future<void> _openInApp() async {
    // Explicitly requests this package by name via an Android intent URL,
    // rather than relying only on App Links verification — this works
    // even if verification hasn't completed yet, and is a more visible,
    // explicit affordance than a passive OS-level link claim. Android
    // only: there's no equivalent without a paid Apple Developer account
    // for iOS, and it's meaningless on desktop.
    final link = buildPublicProfileLink(widget.token);
    final uri = Uri.parse(link);
    final intentUri = Uri.parse(
      'intent://${uri.host}${uri.path}#Intent;scheme=https;package=com.skillpath.skillpath_app;end',
    );
    await launchUrl(intentUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicProfileProvider>();
    final showOpenInApp =
        kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _exitOrGoToApp(context),
        ),
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (showOpenInApp) _OpenInAppBanner(onTap: _openInApp),
            Expanded(
              child: switch (provider.viewState) {
                PublicProfileLoadState.initial ||
                PublicProfileLoadState.loading => const LoadingView(),
                PublicProfileLoadState.error => ErrorView(
                  message: provider.viewError ?? 'Could not load this profile.',
                  onRetry: () => context
                      .read<PublicProfileProvider>()
                      .loadPublicProfile(widget.token),
                ),
                PublicProfileLoadState.loaded => PortfolioBody(
                  data: provider.viewedProfile!.toPortfolioData(),
                  isSelf: false,
                  onAddEducation: () {},
                  onDeleteEducation: (_) {},
                  onAddCertification: () {},
                  onDeleteCertification: (_) {},
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenInAppBanner extends StatelessWidget {
  const _OpenInAppBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: p.indigoLight,
      child: Row(
        children: [
          Icon(Icons.smartphone_outlined, size: 18, color: p.indigo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Have the SkillPath app installed?',
              style: TextStyle(fontSize: 12.5, color: p.textPrimary),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text('Open in app', style: TextStyle(color: p.indigo)),
          ),
        ],
      ),
    );
  }
}
