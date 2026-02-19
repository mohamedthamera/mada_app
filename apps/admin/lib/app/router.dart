import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/courses/courses_screen.dart';
import '../features/courses/course_lessons_screen.dart';
import '../features/users/users_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/subscriptions/subscriptions_screen.dart';
import '../features/jobs/jobs_screen.dart';
import '../features/banners/banners_screen.dart';
import '../features/influencers/influencers_screen.dart';
import '../features/dashboard/admin_shell.dart';

String? _cachedUserId;
String? _cachedRole;

final adminRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final session = SupabaseClientFactory.client.auth.currentSession;
    final loggedIn = session != null;
    final isLogin = state.matchedLocation == '/login';
    if (!loggedIn) {
      _cachedUserId = null;
      _cachedRole = null;
      if (!isLogin) return '/login';
    }
    if (!loggedIn && isLogin) return null;
    if (loggedIn) {
      try {
        if (_cachedUserId == session.user.id && _cachedRole != null) {
          // use cached role
        } else {
          final res = await SupabaseClientFactory.client
              .from('profiles')
              .select('role')
              .eq('id', session.user.id)
              .maybeSingle();
          _cachedUserId = session.user.id;
          _cachedRole = (res != null && res['role'] != null)
              ? res['role'].toString()
              : 'student';
        }
        final role = (_cachedRole ?? 'student').toString().trim().toLowerCase();
        if (!role.contains('admin')) return '/login?reason=not_admin';
      } catch (_) {
        return '/login?reason=error';
      }
      if (isLogin) return '/dashboard';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) =>
          AdminLoginScreen(reason: state.uri.queryParameters['reason']),
    ),
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/courses',
          builder: (context, state) => const CoursesScreen(),
        ),
        GoRoute(
          path: '/courses/:id/lessons',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final title = state.uri.queryParameters['title'] ?? 'دورة';
            return CourseLessonsScreen(courseId: id, courseTitle: title);
          },
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) => const UsersScreen(),
        ),
        GoRoute(
          path: '/jobs',
          builder: (context, state) => const AdminJobsScreen(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/subscriptions',
          builder: (context, state) => const SubscriptionsScreen(),
        ),
        GoRoute(
          path: '/banners',
          builder: (context, state) => const BannersScreen(),
        ),
        GoRoute(
          path: '/influencers',
          builder: (context, state) => const InfluencersScreen(),
        ),
      ],
    ),
  ],
);
