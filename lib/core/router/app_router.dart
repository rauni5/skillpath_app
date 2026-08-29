import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/models/assistant_chat_session.dart';
import '../../features/admin/screens/admin_achievement_form_screen.dart';
import '../../features/admin/screens/admin_achievements_screen.dart';
import '../../features/admin/screens/admin_blocked_screen.dart';
import '../../features/admin/screens/admin_branch_detail_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/admin/screens/admin_role_detail_screen.dart';
import '../../features/admin/screens/admin_roles_screen.dart';
import '../../features/admin/screens/admin_skill_detail_screen.dart';
import '../../features/admin/screens/admin_skills_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/widgets/admin_shell.dart';
import '../../features/assistant/screens/assistant_chat_screen.dart';
import '../../features/assistant/screens/assistant_sessions_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/career/screens/career_goal_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/portfolio_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/providers/portfolio_provider.dart';
import '../../features/projects/screens/create_post_screen.dart';
import '../../features/projects/screens/create_project_screen.dart';
import '../../features/projects/screens/edit_project_screen.dart';
import '../../features/projects/screens/my_invites_screen.dart';
import '../../features/projects/screens/my_projects_screen.dart';
import '../../features/projects/screens/post_detail_screen.dart';
import '../../features/projects/screens/project_detail_screen.dart';
import '../../features/projects/screens/project_discussion_screen.dart';
import '../../features/projects/screens/project_manage_screen.dart';
import '../../features/projects/screens/projects_list_screen.dart';
import '../../features/roadmap/screens/roadmap_screen.dart';
import '../../features/skills/screens/skills_screen.dart';
import '../../features/skills/screens/add_skills_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import 'skill_check_route_args.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/tutor/screen/skill_check_screen.dart';
import '../../features/tutor/screen/tutor_chat_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../models/discussion_post.dart';
import 'navigation_keys.dart';

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final onSplash = loc == '/splash';
      final onAuthScreens =
          loc == '/login' || loc == '/register' || loc == '/forgot-password';
      final onOnboarding = loc == '/onboarding';
      final onVerifyEmail = loc == '/verify-email';
      final onAdminBlocked = loc == '/admin-blocked';
      final onAdmin = loc.startsWith('/admin');

      if (authProvider.status == AuthStatus.unknown) {
        return onSplash ? null : '/splash';
      }

      if (authProvider.status == AuthStatus.unauthenticated) {
        return onAuthScreens ? null : '/login';
      }

      // Signed in from here on — email verification gates everything else.
      if (authProvider.needsEmailVerification) {
        return onVerifyEmail ? null : '/verify-email';
      }

      final isAdmin = authProvider.currentUser?.isAdmin ?? false;

      if (isAdmin) {
        // Admins never go through onboarding or the normal student app —
        // web takes them straight to the admin panel, mobile is blocked.
        if (!kIsWeb) {
          return onAdminBlocked ? null : '/admin-blocked';
        }
        if (onAuthScreens ||
            onVerifyEmail ||
            onOnboarding ||
            onAdminBlocked ||
            !onAdmin) {
          return '/admin';
        }
        return null;
      }

      // Non-admin users should never reach admin-only routes.
      if (onAdmin || onAdminBlocked) return '/dashboard';

      final needsOnboarding = authProvider.needsOnboarding;
      if (needsOnboarding == null) return onVerifyEmail ? '/login' : null;

      if (needsOnboarding) {
        return onOnboarding ? null : '/onboarding';
      }

      if (onOnboarding || onAuthScreens || onVerifyEmail || onSplash) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/admin-blocked',
        builder: (context, state) => const AdminBlockedScreen(),
      ),
      GoRoute(
        path: '/assistant',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const AssistantSessionsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'session',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: AssistantChatScreen(
                session: state.extra as AssistantChatSession,
              ),
            ),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminHomeScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/skills',
            builder: (context, state) => const AdminSkillsScreen(),
          ),
          GoRoute(
            path: '/admin/skills/:id',
            builder: (context, state) => AdminSkillDetailScreen(
              skillId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/admin/roles',
            builder: (context, state) => const AdminRolesScreen(),
          ),
          GoRoute(
            path: '/admin/roles/:id',
            builder: (context, state) => AdminRoleDetailScreen(
              roleId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/admin/roles/:roleid/branches/:id',
            builder: (context, state) => AdminBranchDetailScreen(
              roleId: int.parse(state.pathParameters['roleid']!),
              branchId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/admin/achievements',
            builder: (context, state) => const AdminAchievementsScreen(),
          ),
          GoRoute(
            path: '/admin/achievements/new',
            builder: (context, state) => const AdminAchievementFormScreen(),
          ),
          GoRoute(
            path: '/admin/achievements/:id',
            builder: (context, state) => AdminAchievementFormScreen(
              achievementId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      //! full screen routes
      GoRoute(
        path: '/roadmap/skill/:skillId/chat',
        builder: (context, state) => TutorChatScreen(
          skillId: int.parse(state.pathParameters['skillId']!),
          skillName: state.extra as String? ?? 'Skill',
        ),
      ),
      GoRoute(
        path: '/roadmap/skill/:skillId/skill-check',
        builder: (context, state) {
          final extra = state.extra;
          final args = extra is SkillCheckRouteArgs
              ? extra
              : SkillCheckRouteArgs(extra as String? ?? 'Skill');
          return SkillCheckScreen(
            skillId: int.parse(state.pathParameters['skillId']!),
            skillName: args.skillName,
            returnLabel: args.returnLabel ?? 'Back to Roadmap',
          );
        },
      ),
      GoRoute(
        path: '/projects/new',
        builder: (context, state) => const CreateProjectScreen(),
      ),
      GoRoute(
        path: '/projects/mine/:id/edit',
        builder: (context, state) => EditProjectScreen(
          projectId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/projects/:id/discussion',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ProjectDiscussionScreen(
            projectId: int.parse(state.pathParameters['id']!),
            projectName: extra['name'] as String? ?? 'Discussion',
            isMember: extra['isMember'] as bool? ?? false,
          );
        },
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => CreatePostScreen(
              projectId: int.parse(state.pathParameters['id']!),
              channel:
                  state.extra as DiscussionChannel? ?? DiscussionChannel.public,
            ),
          ),
          GoRoute(
            path: 'post/:postId',
            builder: (context, state) => PostDetailScreen(
              projectId: int.parse(state.pathParameters['id']!),
              postId: int.parse(state.pathParameters['postId']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/profile/settings/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/users/:id/portfolio',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => PortfolioProvider(),
          child: PortfolioScreen(
            userId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/profile/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/career-goal',
        builder: (context, state) => const CareerGoalScreen(),
      ),
      GoRoute(
        path: '/profile/skills',
        builder: (context, state) => const SkillsScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddSkillsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          //! nav bar routes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/roadmap',
                builder: (context, state) => const RoadmapScreen(),
                routes: [
                  GoRoute(
                    path: 'skill/:skillId/chat',
                    builder: (context, state) => TutorChatScreen(
                      skillId: int.parse(state.pathParameters['skillId']!),
                      skillName: state.extra as String? ?? 'Skill',
                    ),
                  ),
                  GoRoute(
                    path: 'skill/:skillId/skill-check',
                    builder: (context, state) {
                      final extra = state.extra;
                      final args = extra is SkillCheckRouteArgs
                          ? extra
                          : SkillCheckRouteArgs(extra as String? ?? 'Skill');
                      return SkillCheckScreen(
                        skillId: int.parse(state.pathParameters['skillId']!),
                        skillName: args.skillName,
                        returnLabel: args.returnLabel ?? 'Back to Roadmap',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (context, state) => const ProjectsListScreen(),
                routes: [
                  GoRoute(
                    path: 'invites',
                    builder: (context, state) => const MyInvitesScreen(),
                  ),
                  GoRoute(
                    path: 'mine',
                    builder: (context, state) => const MyProjectsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => ProjectManageScreen(
                          projectId: int.parse(state.pathParameters['id']!),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ProjectDetailScreen(
                      projectId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const PortfolioScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
