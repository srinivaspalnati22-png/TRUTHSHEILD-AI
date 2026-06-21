import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/scanner/screens/message_scanner_screen.dart';
import '../../features/scanner/screens/url_scanner_screen.dart';
import '../../features/document/screens/offer_letter_screen.dart';
import '../../features/fact_check/screens/fact_check_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/assistant/screens/ai_assistant_screen.dart';
import '../../features/history/screens/scan_history_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/notification_listener_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../shell/main_shell.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (isSplash) return null;
      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/scanner/message',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const MessageScannerScreen(),
            ),
          ),
          GoRoute(
            path: '/scanner/url',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const UrlScannerScreen(),
            ),
          ),
          GoRoute(
            path: '/document/offer-letter',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const OfferLetterScreen(),
            ),
          ),
          GoRoute(
            path: '/fact-check',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const FactCheckScreen(),
            ),
          ),
          GoRoute(
            path: '/community',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const CommunityScreen(),
            ),
          ),
          GoRoute(
            path: '/assistant',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const AiAssistantScreen(),
            ),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const ScanHistoryScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const AdminDashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const NotificationListenerScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage _buildPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
