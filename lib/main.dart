import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'features/audio/sound_effects_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
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

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _router = buildRouter(auth);
    // Achievement "newly unlocked" tracking lives in GamificationProvider,
    // which — like the other providers — is created once for the app's
    // whole process lifetime, not per login. Without this, signing out and
    // back in would diff fresh achievements against stale data from the
    // previous session and re-show toasts for things already seen.
    auth.registerSignOutListener(
      () => context.read<GamificationProvider>().reset(),
    );
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
