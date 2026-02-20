import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/presentation/device_check_guard.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/set_new_password_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/splash_screen.dart';
import '../features/courses/presentation/course_details_screen.dart';
import '../features/courses/presentation/course_list_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/subscription/presentation/subscription_screen.dart';
import '../features/lesson_player/presentation/lesson_player_screen.dart';
import '../features/quizzes/presentation/quiz_screen.dart';
import '../features/certificates/presentation/certificate_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/community/presentation/community_screen.dart';
import '../features/jobs/presentation/jobs_screen.dart';
import '../features/referral/presentation/referral_screen.dart';

CustomTransitionPage<void> _fadePage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

final _publicPaths = ['/splash', '/onboarding', '/login', '/signup'];

final _authRedirectNotifier = ValueNotifier<int>(0);
bool _needsPasswordReset = false;

void refreshAuthRedirect() => _authRedirectNotifier.value++;

void setNeedsPasswordReset(bool value) {
  _needsPasswordReset = value;
  _authRedirectNotifier.value++;
}

void clearNeedsPasswordReset() {
  _needsPasswordReset = false;
  _authRedirectNotifier.value++;
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: _authRedirectNotifier,
  redirect: (context, state) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    final path = state.matchedLocation;
    final isPublic = _publicPaths.any((p) => path.startsWith(p));

    if (isLoggedIn && _needsPasswordReset && path != '/set-new-password') {
      return '/set-new-password';
    }
    if (isLoggedIn && (path == '/login' || path == '/signup')) {
      return '/home';
    }
    if (!isLoggedIn && !isPublic && path != '/set-new-password') {
      return '/login';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _fadePage(const SplashScreen()),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => _fadePage(const OnboardingScreen()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _fadePage(const LoginScreen()),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => _fadePage(const SignupScreen()),
    ),
    GoRoute(
      path: '/set-new-password',
      pageBuilder: (context, state) => _fadePage(const SetNewPasswordScreen()),
    ),
    ShellRoute(
      builder: (context, state, child) => HomeShell(
        child: DeviceCheckGuard(child: child),
      ),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => _fadePage(const HomeScreen()),
        ),
        GoRoute(
          path: '/courses',
          pageBuilder: (context, state) => _fadePage(const CourseListScreen()),
        ),
        GoRoute(
          path: '/courses/:id',
          pageBuilder: (context, state) => _fadePage(
            CourseDetailsScreen(courseId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (context, state) => _fadePage(const ProgressScreen()),
        ),
        GoRoute(
          path: '/jobs',
          pageBuilder: (context, state) => _fadePage(const JobsScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => _fadePage(const ProfileScreen()),
        ),
        GoRoute(
          path: '/subscription',
          pageBuilder: (context, state) => _fadePage(const SubscriptionScreen()),
        ),
        GoRoute(
          path: '/referral',
          pageBuilder: (context, state) => _fadePage(const ReferralScreen()),
        ),
        GoRoute(
          path: '/lesson/:id',
          pageBuilder: (context, state) => _fadePage(
            LessonPlayerScreen(
              lessonId: state.pathParameters['id']!,
              courseId: state.uri.queryParameters['courseId'] ?? '',
            ),
          ),
        ),
        GoRoute(
          path: '/quiz',
          pageBuilder: (context, state) => _fadePage(const QuizScreen()),
        ),
        GoRoute(
          path: '/certificates',
          pageBuilder: (context, state) => _fadePage(const CertificateScreen()),
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) =>
              _fadePage(const NotificationsScreen()),
        ),
        GoRoute(
          path: '/community',
          pageBuilder: (context, state) => _fadePage(const CommunityScreen()),
        ),
      ],
    ),
  ],
);

