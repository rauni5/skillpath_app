import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'features/audio/sound_effects_service.dart';
import 'core/router/app_router.dart';
import 'core/router/navigation_keys.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'shared/widgets/app_dialogs.dart';
import 'features/admin/providers/admin_dashboard_provider.dart';
import 'features/admin/providers/admin_achievements_provider.dart';
import 'features/admin/providers/admin_roles_provider.dart';
import 'features/admin/providers/admin_skills_provider.dart';
import 'features/admin/providers/admin_users_provider.dart';
import 'features/assistant/providers/assistant_chat_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/career/providers/career_provider.dart';
import 'features/dashboard/providers/dashboard_ai_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/dashboard/providers/gamification_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/profile/providers/portfolio_provider.dart';
import 'features/projects/providers/discussion_provider.dart';
import 'features/projects/providers/project_management_provider.dart';
import 'features/projects/providers/projects_provider.dart';
import 'features/projects/providers/user_search_provider.dart';
import 'features/roadmap/providers/roadmap_provider.dart';
import 'features/skills/providers/skills_provider.dart';
import 'features/tutor/providers/skill_check_provider.dart';
import 'features/tutor/providers/tutor_chat_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.initialize();
  await AudioPlayer.global.setAudioContext(
    AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
    ),
  );
  await SoundEffectsService.instance.preload();
  runApp(const SkillPathApp());
}

class SkillPathApp extends StatelessWidget {
  const SkillPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => RoadmapProvider()),
        ChangeNotifierProvider(create: (_) => SkillsProvider()),
        ChangeNotifierProvider(create: (_) => CareerProvider()),
        ChangeNotifierProvider(create: (_) => ProjectsProvider()),
        ChangeNotifierProvider(create: (_) => ProjectManagementProvider()),
        ChangeNotifierProvider(create: (_) => DiscussionProvider()),
        ChangeNotifierProvider(create: (_) => UserSearchProvider()),
        ChangeNotifierProvider(create: (_) => AdminUsersProvider()),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        ChangeNotifierProvider(create: (_) => AdminSkillsProvider()),
        ChangeNotifierProvider(create: (_) => AdminRolesProvider()),
        ChangeNotifierProvider(create: (_) => AdminAchievementsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TutorChatProvider()),
        ChangeNotifierProvider(create: (_) => SkillCheckProvider()),
        ChangeNotifierProvider(create: (_) => DashboardAiProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => AssistantChatProvider()),
      ],
      child: const _RouterHost(),
    );
  }
}

class _RouterHost extends StatefulWidget {
  const _RouterHost();

  @override
  State<_RouterHost> createState() => _RouterHostState();
}

class _RouterHostState extends State<_RouterHost> {
  late final GoRouter _router;
  late final AuthProvider _auth;
  bool _hasShownOfflineDialog = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _auth = auth;
    _router = buildRouter(auth);
    // Every provider below holds user-scoped data but — like
    // GamificationProvider — is created once for the app's whole process
    // lifetime, not per login. Without resetting them, signing out and
    // back in (as the same or a different account) would show stale data
    // from the previous session until each screen's own reload kicked in,
    // or worse briefly leak one account's data into another's on a shared
    // device.
    auth.registerSignOutListener(
      () => context.read<GamificationProvider>().reset(),
    );
    auth.registerSignOutListener(
      () => context.read<DashboardProvider>().reset(),
    );
    auth.registerSignOutListener(
      () => context.read<PortfolioProvider>().reset(),
    );
    auth.registerSignOutListener(() => context.read<RoadmapProvider>().reset());
    auth.registerSignOutListener(() => context.read<SkillsProvider>().reset());
    auth.registerSignOutListener(() => context.read<CareerProvider>().reset());
    auth.registerSignOutListener(
      () => context.read<ProjectsProvider>().reset(),
    );
    auth.registerSignOutListener(
      () => context.read<ProjectManagementProvider>().reset(),
    );
    auth.registerSignOutListener(
      () => context.read<DiscussionProvider>().reset(),
    );
    auth.registerSignOutListener(
      () => context.read<UserSearchProvider>().reset(),
    );
    auth.registerSignOutListener(
      () => context.read<AdminUsersProvider>().reset(),
    );
    auth.registerSignOutListener(
      () => context.read<AdminDashboardProvider>().reset(),
    );
    auth.registerSignOutListener(
      () => context.read<AdminSkillsProvider>().reset(),
    );
    auth.registerSignOutListener(
      () => context.read<AdminRolesProvider>().reset(),
    );
    auth.registerSignOutListener(
      () => context.read<AdminAchievementsProvider>().reset(),
    );
    auth.registerSignOutListener(
      () => context.read<TutorChatProvider>().reset(),
    );
    auth.registerSignOutListener(
      () => context.read<SkillCheckProvider>().reset(),
    );
    auth.registerSignOutListener(
      () => context.read<DashboardAiProvider>().reset(),
    );
    auth.registerSignOutListener(
      () => context.read<NotificationsProvider>().reset(),
    );
    auth.registerSignOutListener(
      () => context.read<AssistantChatProvider>().reset(),
    );

    // Gamification/achievements are recomputed lazily by the backend
    // whenever they're read, so there's no server event to react to — but
    // the app itself already knows exactly when something that *might*
    // affect them just happened, since it's the one that made the call.
    // Wiring a direct refresh at each of those points is strictly better
    // than polling on a timer: instant instead of up-to-30s-stale, and it
    // doesn't burn a request when nothing actually changed. This covers
    // the app's own actions; a project teammate's action still relies on
    // the lighter resume/tab-visit check on the Dashboard itself.
    final gamification = context.read<GamificationProvider>();
    void refreshGamification() {
      final userId = auth.currentUser?.id;
      if (userId != null) gamification.load(userId);
    }

    context.read<SkillsProvider>().onProgressMade = refreshGamification;
    context.read<SkillCheckProvider>().onProgressMade = refreshGamification;
    context.read<ProjectManagementProvider>().onProgressMade =
        refreshGamification;

    // Tell the user once, the moment we fall back to a cached session or
    // cached screen data — not on every rebuild, and again if they go
    // offline a second time later in the same app session.
    auth.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (_auth.isOffline && !_hasShownOfflineDialog) {
      _hasShownOfflineDialog = true;
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        showInfoDialog(
          ctx,
          title: "You're offline",
          message:
              "Showing your last saved data. Some screens may be out of "
              "date, and anything that needs a connection — like sending "
              "a message or saving changes — won't work until you're "
              "back online.",
          icon: Icons.cloud_off_rounded,
        );
      }
    } else if (!_auth.isOffline) {
      _hasShownOfflineDialog = false;
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().mode;

    return MaterialApp.router(
      title: 'SkillPath',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
