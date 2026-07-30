import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/career/screens/career_goal_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/projects/screens/create_project_screen.dart';
import '../../features/projects/screens/my_projects_screen.dart';
import '../../features/projects/screens/project_detail_screen.dart';
import '../../features/projects/screens/project_manage_screen.dart';
import '../../features/projects/screens/projects_list_screen.dart';
import '../../features/roadmap/screens/roadmap_screen.dart';
import '../../features/skills/screens/skills_screen.dart';
import '../../shared/widgets/app_shell.dart';

GoRouter buildRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final onAuthScreens = loc == '/login' || loc == '/register';
      final onOnboarding = loc == '/onboarding';

      if (authProvider.status == AuthStatus.unknown) return null;

      if (authProvider.status == AuthStatus.unauthenticated) {
        return onAuthScreens ? null : '/login';
      }

      final needsOnboarding = authProvider.needsOnboarding;
      if (needsOnboarding == null) return null;

      if (needsOnboarding) {
        return onOnboarding ? null : '/onboarding';
      }

      if (onOnboarding || onAuthScreens) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/roadmap',
                builder: (context, state) => const RoadmapScreen(),
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
                    path: 'new',
                    builder: (context, state) => const CreateProjectScreen(),
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
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'skills',
                    builder: (context, state) => const SkillsScreen(),
                  ),
                  GoRoute(
                    path: 'career-goal',
                    builder: (context, state) => const CareerGoalScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
